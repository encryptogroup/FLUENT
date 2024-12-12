const std = @import("std");
const assert = std.debug.assert;

const Circuit = @import("Circuit.zig");
const Torder = @import("Torder.zig");

const Builder = @This();

gpa: std.mem.Allocator,

root: std.json.Value,
torder: Torder,
private_modules: std.StringHashMapUnmanaged(Circuit),
top_module: []const u8,

circuit_nodes: std.MultiArrayList(Circuit.Node) = .{},
circuit_luts: std.ArrayListUnmanaged(Circuit.Node.Index) = .{},
circuit_inputs: std.ArrayListUnmanaged(Circuit.Node.Index) = .{},
circuit_outputs: std.ArrayListUnmanaged(Circuit.Node.Index) = .{},
circuit_lut_tables: std.ArrayListUnmanaged(u1) = .{},
circuit_programming_bits: std.ArrayListUnmanaged(u1) = .{},
circuit_max_wire_number: Circuit.Node.Index = 0,

/// Memoizes the max wire number for every module, populated on demand
max_wire_numbers: std.StringHashMapUnmanaged(Circuit.Node.Index) = .{},

err_msg: ?ErrorMsg = null,

/// Wire number guaranteed to be wired to a constant 0 gate
const constant_zero_wire_number = 0;

/// Wire number guaranteed to be wired to a constant 1 gate
const constant_one_wire_number = 1;

const ErrorMsg = struct {
    msg: []const u8,
};

const InnerError = error{
    OutOfMemory,
    BuildFail,
};

/// This hash map contains a mapping necessary for a submodule to
/// connect its ports to the parent module.
///
///        Submodule                      Parent module
///
///       raw wire number
///        found in JSON
///              |
///              +--- submodule wire
///              |    number offset
///              |
///        wire number -----------------> wire number
///          (port)            ^          (connection)
///                      this mapping
const WireTranslationsManaged = std.AutoHashMap(Circuit.Node.Index, Circuit.Node.Index);
const WireTranslations = std.AutoHashMapUnmanaged(Circuit.Node.Index, Circuit.Node.Index);

/// Every time a new module is instantiated (whether it be because the
/// module is the top-level module or because it is included as a
/// submodule), a fresh copy of a ModuleInstantiation is created which
/// governs the terms (wire number offset and wire number translation
/// table) under which this module is generated
const ModuleInstantiation = struct {
    module_name: []const u8,
    wire_number_offset: Circuit.Node.Index,
    connections: *WireTranslations,
};

/// Tracks the progress for every module built. When a submodule is
/// encountered, the progress on the current module is paused and the
/// build process continues with the submodule. When the submodule
/// (including all its potential submodules) is finished building, we
/// resume progress using the data stored in ModuleProgress
const ModuleProgress = struct {
    instantiation: ModuleInstantiation,
    index: usize,
};

pub fn build(builder: *Builder) !Circuit {
    if (builder.root != .Object) return builder.fail("JSON root is not an object", .{});
    if (!builder.root.Object.contains("modules")) return builder.fail("JSON root does not contain 'modules'", .{});
    if (!(builder.root.Object.get("modules").? == .Object)) return builder.fail("'modules' is not an object", .{});

    try builder.buildTopModule(builder.top_module);

    return Circuit{
        .nodes = builder.circuit_nodes.toOwnedSlice(),
        .luts = builder.circuit_luts.toOwnedSlice(builder.gpa),
        .inputs = builder.circuit_inputs.toOwnedSlice(builder.gpa),
        .outputs = builder.circuit_outputs.toOwnedSlice(builder.gpa),
        .lut_tables = builder.circuit_lut_tables.toOwnedSlice(builder.gpa),
        .programming_bits = builder.circuit_programming_bits.toOwnedSlice(builder.gpa),
        .max_wire_number = builder.circuit_max_wire_number,
    };
}

fn fail(builder: *Builder, comptime format: []const u8, args: anytype) InnerError {
    @setCold(true);
    assert(builder.err_msg == null);
    builder.err_msg = ErrorMsg{ .msg = try std.fmt.allocPrint(builder.gpa, format, args) };
    return error.BuildFail;
}

fn addNode(builder: *Builder, node: Circuit.Node) !void {
    try builder.circuit_nodes.ensureUnusedCapacity(builder.gpa, 1);
    builder.circuit_nodes.appendAssumeCapacity(node);
}

fn findMaxWireLabel(builder: *Builder, module_name: []const u8) !Circuit.Node.Index {
    const modules = builder.root.Object.get("modules").?;
    const module_node = modules.Object.get(module_name).?;

    var max_wire_label: Circuit.Node.Index = 0;

    if (module_node.Object.get("ports")) |ports| {
        var iterator = ports.Object.iterator();
        while (iterator.next()) |entry| {
            const port = entry.value_ptr.Object;
            const bits = port.get("bits").?.Array.items;
            for (bits) |bit| {
                switch (bit) {
                    .Integer => |int| max_wire_label = @max(max_wire_label, @intCast(Circuit.Node.Index, int)),
                    else => {},
                }
            }
        }
    }

    if (module_node.Object.get("cells")) |cells| {
        var cell_iterator = cells.Object.iterator();
        while (cell_iterator.next()) |cell_entry| {
            const cell = cell_entry.value_ptr.Object;
            const connections = cell.get("connections").?.Object;
            var connection_iterator = connections.iterator();
            while (connection_iterator.next()) |connection_entry| {
                const list = connection_entry.value_ptr.Array;
                for (list.items) |bit| {
                    switch (bit) {
                        .Integer => |int| max_wire_label = @max(max_wire_label, @intCast(Circuit.Node.Index, int)),
                        else => {},
                    }
                }
            }
        }
    }

    return max_wire_label;
}

fn buildTopModule(builder: *Builder, top_module_name: []const u8) !void {
    const modules = builder.root.Object.get("modules").?.Object;

    try builder.buildInputs(top_module_name);

    // Add constant gates
    try builder.addNode(.{
        .tag = .zero,
        .data = .{ .constant = .{ .output = constant_zero_wire_number } },
    });
    try builder.addNode(.{
        .tag = .one,
        .data = .{ .constant = .{ .output = constant_one_wire_number } },
    });

    const top_module_instantiation = ModuleInstantiation{
        .module_name = top_module_name,
        .wire_number_offset = 0,
        .connections = blk: {
            const result = try builder.gpa.create(WireTranslations);
            result.* = .{};
            break :blk result;
        },
    };

    var stack = std.ArrayList(ModuleProgress).init(builder.gpa);
    defer stack.deinit();
    try stack.append(.{
        .instantiation = top_module_instantiation,
        .index = 0,
    });
    var next_free_wire_number: Circuit.Node.Index = 0;

    modules: while (stack.popOrNull()) |module_progress| {
        const module_name = module_progress.instantiation.module_name;
        const wire_number_offset = module_progress.instantiation.wire_number_offset;
        const wire_translations = module_progress.instantiation.connections;
        const module_node = modules.get(module_name) orelse return builder.fail("Module '{s}' not found", .{module_name});

        const cells = module_node.Object.get("cells") orelse return builder.fail("Module '{s}' does not contain any cells", .{module_name});
        const cell_order = builder.torder.modules.get(module_name) orelse return builder.fail("No torder for module '{s}' found", .{module_name});

        // If this module was just freshly added to the queue (not
        // a resumed build), increment the next free wire number
        if (module_progress.index == 0) {
            // Look up the max wire number of the current module
            // and add it to the max count
            if (!builder.max_wire_numbers.contains(module_name)) {
                try builder.max_wire_numbers.putNoClobber(
                    builder.gpa,
                    module_name,
                    try builder.findMaxWireLabel(module_name),
                );
            }
            next_free_wire_number += builder.max_wire_numbers.get(module_name).? + 1;
        }

        var i: usize = module_progress.index;
        while (i < cell_order.len) : (i += 1) {
            const cell_name = cell_order[i];
            const cell = cells.Object.get(cell_name).?.Object;
            const cell_type = cell.get("type").?.String;

            if (std.mem.eql(u8, "SPFE_NOT", cell_type) or std.mem.eql(u8, "$_NOT_", cell_type)) {
                try builder.buildOneInput(
                    wire_number_offset,
                    wire_translations,
                    cell,
                    .inv,
                );
            } else if (std.mem.eql(u8, "SPFE_XOR", cell_type) or std.mem.eql(u8, "$_XOR_", cell_type)) {
                try builder.buildTwoInput(
                    wire_number_offset,
                    wire_translations,
                    cell,
                    .xor,
                );
            } else if (std.mem.eql(u8, "SPFE_AND", cell_type) or std.mem.eql(u8, "$_AND_", cell_type)) {
                try builder.buildTwoInput(
                    wire_number_offset,
                    wire_translations,
                    cell,
                    .@"and",
                );
            } else if (std.mem.eql(u8, "$lut", cell_type)) {
                try builder.buildLut(
                    wire_number_offset,
                    wire_translations,
                    cell,
                    .lut,
                );
            } else if (modules.contains(cell_type)) {
                const submodule_wire_number_offset = next_free_wire_number;

                if (builder.private_modules.get(cell_type)) |private_circuit| {
                    // Set up wire translations
                    var submodule_wire_translations = WireTranslationsManaged.init(builder.gpa);
                    defer submodule_wire_translations.deinit();

                    {
                        const connections = cell.get("connections").?.Object;
                        const port_directions = cell.get("port_directions").?.Object;
                        assert(connections.count() == port_directions.count());

                        if (connections.count() != 2) {
                            return builder.fail("Exactly one input and one output connection for private modules is supported for now", .{});
                        }

                        var input_connection_name: ?[]const u8 = null;
                        var output_connection_name: ?[]const u8 = null;

                        var iterator = port_directions.iterator();
                        while (iterator.next()) |entry| {
                            const port_direction = entry.value_ptr.String;
                            if (std.mem.eql(u8, "input", port_direction)) {
                                if (input_connection_name == null) {
                                    input_connection_name = entry.key_ptr.*;
                                } else {
                                    return builder.fail("Only one input connection for private modules is supported", .{});
                                }
                            } else if (std.mem.eql(u8, "output", port_direction)) {
                                if (output_connection_name == null) {
                                    output_connection_name = entry.key_ptr.*;
                                } else {
                                    return builder.fail("Only one output connection for private modules is supported", .{});
                                }
                            } else {
                                return builder.fail("Invalid port direction: '{s}'", .{port_direction});
                            }
                        }

                        const input_list = connections.get(input_connection_name.?).?.Array;
                        for (input_list.items) |connection_bit, j| {
                            const port_wire_number = private_circuit.inputs[j];
                            const translated_port_wire_number = port_wire_number + submodule_wire_number_offset;
                            const translated_connection_wire_number = try builder.translateConnectionBit(
                                connection_bit,
                                wire_number_offset,
                                wire_translations,
                            );
                            try submodule_wire_translations.putNoClobber(
                                translated_port_wire_number,
                                translated_connection_wire_number,
                            );
                        }

                        const output_list = connections.get(output_connection_name.?).?.Array;
                        for (output_list.items) |connection_bit, j| {
                            const port_wire_number = private_circuit.outputs[j];
                            const translated_port_wire_number = port_wire_number + submodule_wire_number_offset;
                            const translated_connection_wire_number = try builder.translateConnectionBit(
                                connection_bit,
                                wire_number_offset,
                                wire_translations,
                            );
                            try submodule_wire_translations.putNoClobber(
                                translated_port_wire_number,
                                translated_connection_wire_number,
                            );
                        }
                    }

                    try builder.buildSubCircuit(
                        submodule_wire_number_offset,
                        &submodule_wire_translations.unmanaged,
                        private_circuit,
                    );

                    next_free_wire_number += private_circuit.max_wire_number + 1;
                } else {
                    // Set up wire translations
                    var submodule_wire_translations = try builder.gpa.create(WireTranslations);
                    submodule_wire_translations.* = .{};

                    {
                        const ports = modules.get(cell_type).?.Object.get("ports").?.Object;
                        const connections = cell.get("connections").?.Object;

                        var input_translated_port_wires = std.AutoHashMap(Circuit.Node.Index, void).init(builder.gpa);
                        defer input_translated_port_wires.deinit();

                        // Process inputs
                        var iterator = connections.iterator();
                        while (iterator.next()) |entry| {
                            const port_name = entry.key_ptr.*;
                            const port = ports.get(port_name).?.Object;
                            const port_direction = port.get("direction").?.String;
                            if (!std.mem.eql(u8, "input", port_direction)) continue;

                            const port_list = port.get("bits").?.Array;
                            const connection_list = entry.value_ptr.Array;
                            for (connection_list.items) |connection_bit, j| {
                                const translated_connection_wire_number = try builder.translateConnectionBit(
                                    connection_bit,
                                    wire_number_offset,
                                    wire_translations,
                                );
                                const port_bit = port_list.items[j];
                                switch (port_bit) {
                                    .Integer => |int| {
                                        const port_wire_number = @intCast(Circuit.Node.Index, int);
                                        const translated_port_wire_number = port_wire_number + submodule_wire_number_offset;
                                        try input_translated_port_wires.putNoClobber(translated_port_wire_number, {});
                                        try submodule_wire_translations.putNoClobber(
                                            builder.gpa,
                                            translated_port_wire_number,
                                            translated_connection_wire_number,
                                        );
                                    },
                                    else => return builder.fail("Unexpected input port: {}", .{port_bit}),
                                }
                            }
                        }

                        // Process outputs
                        iterator.reset();
                        while (iterator.next()) |entry| {
                            const port_name = entry.key_ptr.*;
                            const port = ports.get(port_name).?.Object;
                            const port_direction = port.get("direction").?.String;
                            if (!std.mem.eql(u8, "output", port_direction)) continue;

                            const port_list = port.get("bits").?.Array;
                            const connection_list = entry.value_ptr.Array;
                            for (connection_list.items) |connection_bit, j| {
                                const translated_connection_wire_number = try builder.translateConnectionBit(
                                    connection_bit,
                                    wire_number_offset,
                                    wire_translations,
                                );
                                const port_bit = port_list.items[j];
                                switch (port_bit) {
                                    .Integer => |int| {
                                        const port_wire_number = @intCast(Circuit.Node.Index, int);
                                        const translated_port_wire_number = port_wire_number + submodule_wire_number_offset;
                                        if (input_translated_port_wires.contains(translated_port_wire_number)) {
                                            // The submodule forwards an input as an output verbatim
                                            const translated_input_connection_wire = submodule_wire_translations.get(translated_port_wire_number).?;
                                            try wire_translations.put(
                                                builder.gpa,
                                                translated_connection_wire_number,
                                                translated_input_connection_wire,
                                            );
                                        } else {
                                            const gop = try submodule_wire_translations.getOrPut(builder.gpa, translated_port_wire_number);
                                            if (gop.found_existing) {
                                                // An output wire is used more than once, e.g.,
                                                // out.bits == [ 42, 1, 42, 2 ]
                                                const canonical_connection_wire_number = gop.value_ptr.*;
                                                try wire_translations.put(
                                                    builder.gpa,
                                                    translated_connection_wire_number,
                                                    canonical_connection_wire_number,
                                                );
                                            } else {
                                                gop.value_ptr.* = translated_connection_wire_number;
                                            }
                                        }
                                    },
                                    .String => |str| {
                                        // Constant outputs
                                        const constant_wire_number: Circuit.Node.Index = blk: {
                                            if (std.mem.eql(u8, "0", str)) {
                                                break :blk constant_zero_wire_number;
                                            } else if (std.mem.eql(u8, "1", str)) {
                                                break :blk constant_one_wire_number;
                                            } else if (std.mem.eql(u8, "x", str)) {
                                                // don't care, just connect output to constant 0
                                                break :blk constant_zero_wire_number;
                                            } else {
                                                return builder.fail("Expected 0 or 1, found {s}", .{str});
                                            }
                                        };
                                        try wire_translations.put(
                                            builder.gpa,
                                            translated_connection_wire_number,
                                            constant_wire_number,
                                        );
                                    },
                                    else => return builder.fail("Unexpected output port: {}", .{port_bit}),
                                }
                            }
                        }
                    }

                    // Save current state to stack
                    try stack.append(.{
                        .instantiation = module_progress.instantiation,
                        .index = i + 1,
                    });

                    // Add a fresh state of the new module to the stack
                    try stack.append(.{
                        .instantiation = .{
                            .module_name = cell_type,
                            .wire_number_offset = submodule_wire_number_offset,
                            .connections = submodule_wire_translations,
                        },
                        .index = 0,
                    });
                    continue :modules;
                }
            } else {
                return builder.fail("Unsupported cell type: {s}", .{cell_type});
            }
        }
    }

    try builder.buildOutputs(
        top_module_name,
        top_module_instantiation.wire_number_offset,
        top_module_instantiation.connections,
    );

    builder.circuit_max_wire_number = next_free_wire_number - 1;
}

fn translateConnectionBit(
    builder: *Builder,
    connection_bit: std.json.Value,
    wire_number_offset: Circuit.Node.Index,
    wire_translations: *const WireTranslations,
) !Circuit.Node.Index {
    switch (connection_bit) {
        .Integer => |int| {
            const connection_wire_number = @intCast(Circuit.Node.Index, int);
            const translated_connection_wire_number = translateWireNumber(
                wire_number_offset,
                wire_translations,
                connection_wire_number,
            );
            return translated_connection_wire_number;
        },
        .String => |str| {
            if (std.mem.eql(u8, "0", str)) {
                return constant_zero_wire_number;
            } else if (std.mem.eql(u8, "1", str)) {
                return constant_one_wire_number;
            } else if (std.mem.eql(u8, "x", str)) {
                // don't care, just connect to constant 0
                return constant_zero_wire_number;
            } else {
                return builder.fail("Expected 0, 1, or x, found {s}", .{str});
            }
        },
        else => return builder.fail("Unexpected connection: {}", .{connection_bit}),
    }
}

fn buildInputs(builder: *Builder, module_name: []const u8) !void {
    const modules = builder.root.Object.get("modules").?;
    const module_node = modules.Object.get(module_name) orelse return builder.fail("Module '{s}' not found", .{module_name});

    const ports = module_node.Object.get("ports") orelse return builder.fail("Module '{s}' does not contain any ports", .{module_name});
    var iterator = ports.Object.iterator();
    while (iterator.next()) |entry| {
        const port = entry.value_ptr.Object;
        const port_direction = port.get("direction").?.String;
        if (!std.mem.eql(u8, "input", port_direction)) continue;

        const bits = port.get("bits").?.Array.items;
        for (bits) |bit| {
            switch (bit) {
                .Integer => |val| try builder.circuit_inputs.append(builder.gpa, @intCast(Circuit.Node.Index, val)),
                else => return builder.fail("Input '{s}' of module '{s}' is invalid", .{ entry.key_ptr.*, module_name }),
            }
        }
    }
}

fn buildOutputs(
    builder: *Builder,
    module_name: []const u8,
    wire_number_offset: Circuit.Node.Index,
    wire_translations: *const WireTranslations,
) !void {
    const modules = builder.root.Object.get("modules").?;
    const module_node = modules.Object.get(module_name) orelse return builder.fail("Module '{s}' not found", .{module_name});

    const ports = module_node.Object.get("ports") orelse return builder.fail("Module '{s}' does not contain any ports", .{module_name});
    var iterator = ports.Object.iterator();
    while (iterator.next()) |entry| {
        const port = entry.value_ptr.Object;
        const port_direction = port.get("direction").?.String;
        if (!std.mem.eql(u8, "output", port_direction)) continue;

        const bits = port.get("bits").?.Array.items;
        for (bits) |bit| {
            switch (bit) {
                .Integer => |val| {
                    const output_wire_number = @intCast(Circuit.Node.Index, val);
                    const traslated_output_wire_number = translateWireNumber(wire_number_offset, wire_translations, output_wire_number);
                    try builder.circuit_outputs.append(builder.gpa, traslated_output_wire_number);
                },
                .String => |str| {
                    if (std.mem.eql(u8, "0", str)) {
                        try builder.circuit_outputs.append(builder.gpa, constant_zero_wire_number);
                    } else if (std.mem.eql(u8, "1", str)) {
                        try builder.circuit_outputs.append(builder.gpa, constant_one_wire_number);
                    } else {
                        return builder.fail("Expected 0 or 1 as connection, found {s}", .{str});
                    }
                },
                else => return builder.fail("Output '{s}' of module '{s}' is invalid", .{ entry.key_ptr.*, module_name }),
            }
        }
    }
}

fn translateWireNumber(
    wire_number_offset: Circuit.Node.Index,
    wire_translations: *const WireTranslations,
    wire_number: Circuit.Node.Index,
) Circuit.Node.Index {
    const adjusted_wire_number = wire_number + wire_number_offset;
    const translated_wire_number = wire_translations.get(adjusted_wire_number) orelse adjusted_wire_number;
    return translated_wire_number;
}

fn buildOneInput(
    builder: *Builder,
    wire_number_offset: Circuit.Node.Index,
    wire_translations: *const WireTranslations,
    cell: std.json.ObjectMap,
    tag: Circuit.Node.Tag,
) !void {
    const connections = cell.get("connections").?.Object;

    const connection_a_list = connections.get("A").?.Array;
    const connection_a = connection_a_list.items[0].Integer;
    const wire_number_a = @intCast(Circuit.Node.Index, connection_a);
    const translated_wire_number_a = translateWireNumber(wire_number_offset, wire_translations, wire_number_a);

    const connection_y_list = (connections.get("Y") orelse connections.get("Z").?).Array;
    const connection_y = connection_y_list.items[0].Integer;
    const wire_number_y = @intCast(Circuit.Node.Index, connection_y);
    const translated_wire_number_y = translateWireNumber(wire_number_offset, wire_translations, wire_number_y);

    try builder.addNode(.{
        .tag = tag,
        .data = .{ .one_input = .{
            .input = translated_wire_number_a,
            .output = translated_wire_number_y,
        } },
    });
}

fn buildTwoInput(
    builder: *Builder,
    wire_number_offset: Circuit.Node.Index,
    wire_translations: *const WireTranslations,
    cell: std.json.ObjectMap,
    tag: Circuit.Node.Tag,
) !void {
    const connections = cell.get("connections").?.Object;

    const connection_a_list = connections.get("A").?.Array;
    const connection_a = connection_a_list.items[0].Integer;
    const wire_number_a = @intCast(Circuit.Node.Index, connection_a);
    const translated_wire_number_a = translateWireNumber(wire_number_offset, wire_translations, wire_number_a);

    const connection_b_list = connections.get("B").?.Array;
    const connection_b = connection_b_list.items[0].Integer;
    const wire_number_b = @intCast(Circuit.Node.Index, connection_b);
    const translated_wire_number_b = translateWireNumber(wire_number_offset, wire_translations, wire_number_b);

    const connection_y_list = (connections.get("Y") orelse connections.get("Z").?).Array;
    const connection_y = connection_y_list.items[0].Integer;
    const wire_number_y = @intCast(Circuit.Node.Index, connection_y);
    const translated_wire_number_y = translateWireNumber(wire_number_offset, wire_translations, wire_number_y);

    try builder.addNode(.{
        .tag = tag,
        .data = .{ .two_input = .{
            .input_a = translated_wire_number_a,
            .input_b = translated_wire_number_b,
            .output = translated_wire_number_y,
        } },
    });
}

fn buildLut(
    builder: *Builder,
    wire_number_offset: Circuit.Node.Index,
    wire_translations: *const WireTranslations,
    cell: std.json.ObjectMap,
    tag: Circuit.Node.Tag,
) !void {
    const offset = builder.circuit_luts.items.len;
    const table_offset = builder.circuit_lut_tables.items.len;

    const parameters = cell.get("parameters").?.Object;
    const connections = cell.get("connections").?.Object;

    const arity: u8 = blk: {
        const raw = parameters.get("WIDTH").?.String;
        break :blk try std.fmt.parseInt(u8, raw, 2);
    };
    // len = 2 ^ arity
    const table_len = @as(usize, 1) << @intCast(std.math.Log2Int(usize), arity);

    try builder.circuit_luts.ensureUnusedCapacity(builder.gpa, arity);
    try builder.circuit_lut_tables.appendNTimes(builder.gpa, undefined, table_len); // will be populated later

    const connection_a_list = connections.get("A").?.Array;
    assert(connection_a_list.items.len == arity);
    for (connection_a_list.items) |connection| {
        switch (connection) {
            .Integer => |connection_a| {
                const wire_number_a = @intCast(Circuit.Node.Index, connection_a);
                const translated_wire_number_a = translateWireNumber(wire_number_offset, wire_translations, wire_number_a);
                builder.circuit_luts.appendAssumeCapacity(translated_wire_number_a);
            },
            .String => |str| {
                if (std.mem.eql(u8, "0", str)) {
                    builder.circuit_luts.appendAssumeCapacity(constant_zero_wire_number);
                } else if (std.mem.eql(u8, "1", str)) {
                    builder.circuit_luts.appendAssumeCapacity(constant_one_wire_number);
                } else {
                    return builder.fail("Expected 0 or 1 as connection, found {s}", .{str});
                }
            },
            else => return builder.fail("Unexpected LUT input {}", .{connection}),
        }
    }

    const connection_y_list = connections.get("Y").?.Array;
    const connection_y = connection_y_list.items[0].Integer;
    const wire_number_y = @intCast(Circuit.Node.Index, connection_y);
    const translated_wire_number_y = translateWireNumber(wire_number_offset, wire_translations, wire_number_y);

    const table_raw = parameters.get("LUT").?.String;
    assert(table_raw.len == table_len);
    for (table_raw) |c, i| {
        const bit: u1 = switch (c) {
            '0' => 0,
            '1' => 1,
            else => return error.InvalidLutBit,
        };
        // Insert into the table in the opposite order
        builder.circuit_lut_tables.items[table_offset + table_len - 1 - i] = bit;
    }

    try builder.addNode(.{
        .tag = tag,
        .data = .{ .lut = .{
            .offset = offset,
            .table_offset = table_offset,
            .arity = arity,
            .output = translated_wire_number_y,
        } },
    });
}

fn buildSubCircuit(
    builder: *Builder,
    wire_number_offset: Circuit.Node.Index,
    wire_translations: *const WireTranslations,
    circuit: Circuit,
) !void {
    // Programming bits can be added as-is
    try builder.circuit_programming_bits.appendSlice(builder.gpa, circuit.programming_bits);

    // LUT inputs all need to be translated
    const prev_luts_len = builder.circuit_luts.items.len;
    try builder.circuit_luts.ensureUnusedCapacity(builder.gpa, circuit.luts.len);
    for (circuit.luts) |wire_number| {
        builder.circuit_luts.appendAssumeCapacity(
            translateWireNumber(wire_number_offset, wire_translations, wire_number),
        );
    }

    // LUT tables can be added as-is
    const prev_lut_tables_len = builder.circuit_lut_tables.items.len;
    try builder.circuit_lut_tables.appendSlice(builder.gpa, circuit.lut_tables);

    // For every node, input and output wires need to be
    // translated. Furthermore, for LUT nodes, the offset into the LUT
    // inputs needs to be adjusted
    try builder.circuit_nodes.ensureUnusedCapacity(builder.gpa, circuit.nodes.len);
    const tags = circuit.nodes.items(.tag);
    const datas = circuit.nodes.items(.data);
    for (tags) |tag, i| {
        const data: Circuit.Node.Data = switch (tag) {
            .zero, .one => blk: {
                const constant = datas[i].constant;
                break :blk .{ .constant = .{
                    .output = translateWireNumber(wire_number_offset, wire_translations, constant.output),
                } };
            },
            .inv => blk: {
                const one_input = datas[i].one_input;
                break :blk .{ .one_input = .{
                    .input = translateWireNumber(wire_number_offset, wire_translations, one_input.input),
                    .output = translateWireNumber(wire_number_offset, wire_translations, one_input.output),
                } };
            },
            .@"and", .xor, .y => blk: {
                const two_input = datas[i].two_input;
                break :blk .{ .two_input = .{
                    .input_a = translateWireNumber(wire_number_offset, wire_translations, two_input.input_a),
                    .input_b = translateWireNumber(wire_number_offset, wire_translations, two_input.input_b),
                    .output = translateWireNumber(wire_number_offset, wire_translations, two_input.output),
                } };
            },
            .x => blk: {
                const two_input_two_output = datas[i].two_input_two_output;
                break :blk .{ .two_input_two_output = .{
                    .input_a = translateWireNumber(wire_number_offset, wire_translations, two_input_two_output.input_a),
                    .input_b = translateWireNumber(wire_number_offset, wire_translations, two_input_two_output.input_b),
                    .output_a = translateWireNumber(wire_number_offset, wire_translations, two_input_two_output.output_a),
                    .output_b = translateWireNumber(wire_number_offset, wire_translations, two_input_two_output.output_b),
                } };
            },
            .lut => blk: {
                const lut = datas[i].lut;
                break :blk .{ .lut = .{
                    .offset = lut.offset + prev_luts_len,
                    .table_offset = lut.table_offset + prev_lut_tables_len,
                    .arity = lut.arity,
                    .output = translateWireNumber(wire_number_offset, wire_translations, lut.output),
                } };
            },
            .ulut => blk: {
                const ulut = datas[i].ulut;
                break :blk .{ .ulut = .{
                    .offset = ulut.offset + prev_luts_len,
                    .arity = ulut.arity,
                    .output = translateWireNumber(wire_number_offset, wire_translations, ulut.output),
                } };
            },
            .y2s, .s2y => return builder.fail("Builder cannot handle Y2S/S2Y gates", .{}),
        };

        builder.circuit_nodes.appendAssumeCapacity(.{
            .tag = tag,
            .data = data,
        });
    }
}
