const std = @import("std");

const Circuit = @import("Circuit.zig");

const Eval = @This();

circuit: Circuit,
wire_values: std.DynamicBitSetUnmanaged,

programming_bit_counter: usize = 0,

pub fn evaluateCircuit(
    gpa: std.mem.Allocator,
    circuit: Circuit,
    inputs: []const u1,
) ![]const u1 {
    var eval = Eval{
        .circuit = circuit,
        .wire_values = try std.DynamicBitSetUnmanaged.initEmpty(gpa, circuit.max_wire_number + 1),
    };

    if (inputs.len != circuit.inputs.len) return error.InvalidNumberOfInputs;
    for (inputs) |bit, i| {
        switch (bit) {
            0 => eval.wire_values.unset(circuit.inputs[i]),
            1 => eval.wire_values.set(circuit.inputs[i]),
        }
    }

    try eval.evalCircuit();

    const outputs = try gpa.alloc(u1, circuit.outputs.len);
    for (circuit.outputs) |wire_number, i| {
        outputs[i] = @boolToInt(eval.wire_values.isSet(wire_number));
    }
    return outputs;
}

fn evalCircuit(eval: *Eval) !void {
    const circuit_tags = eval.circuit.nodes.items(.tag);
    for (circuit_tags) |tag, index| {
        switch (tag) {
            .zero => try eval.evalConstant(index),
            .one => try eval.evalConstant(index),

            .inv => try eval.evalOneInput(index),
            .y2s => try eval.evalOneInput(index),
            .s2y => try eval.evalOneInput(index),

            .@"and" => try eval.evalTwoInput(index),
            .xor => try eval.evalTwoInput(index),
            .y => try eval.evalTwoInput(index),

            .x => try eval.evalTwoInputTwoOutput(index),

            .lut => try eval.evalLut(index),

            .ulut => try eval.evalUlut(index),
        }
    }
}

fn evalConstant(eval: *Eval, node: Circuit.Node.Index) !void {
    const tag = eval.circuit.nodes.items(.tag)[node];
    const constant = eval.circuit.nodes.items(.data)[node].constant;

    const output = switch (tag) {
        .zero => false,
        .one => true,
        else => unreachable,
    };

    eval.wire_values.setValue(constant.output, output);
}

fn evalOneInput(eval: *Eval, node: Circuit.Node.Index) !void {
    const tag = eval.circuit.nodes.items(.tag)[node];
    const one_input = eval.circuit.nodes.items(.data)[node].one_input;

    const input = eval.wire_values.isSet(one_input.input);
    const output = switch (tag) {
        .inv => !input,
        .y2s => input,
        .s2y => input,
        else => unreachable,
    };

    eval.wire_values.setValue(one_input.output, output);
}

fn evalTwoInput(eval: *Eval, node: Circuit.Node.Index) !void {
    const tag = eval.circuit.nodes.items(.tag)[node];
    const two_input = eval.circuit.nodes.items(.data)[node].two_input;

    const input_a = eval.wire_values.isSet(two_input.input_a);
    const input_b = eval.wire_values.isSet(two_input.input_b);
    const output = switch (tag) {
        .@"and" => input_a and input_b,
        .xor => input_a != input_b,
        .y => blk: {
            const prog_bit = eval.circuit.programming_bits[eval.programming_bit_counter];
            eval.programming_bit_counter += 1;

            switch (prog_bit) {
                1 => break :blk input_a,
                0 => break :blk input_b,
            }
        },
        else => unreachable,
    };

    eval.wire_values.setValue(two_input.output, output);
}

fn evalTwoInputTwoOutput(eval: *Eval, node: Circuit.Node.Index) !void {
    const tag = eval.circuit.nodes.items(.tag)[node];
    const two_input_two_output = eval.circuit.nodes.items(.data)[node].two_input_two_output;

    const input_a = eval.wire_values.isSet(two_input_two_output.input_a);
    const input_b = eval.wire_values.isSet(two_input_two_output.input_b);
    const Outputs = struct { a: bool, b: bool };
    const outputs: Outputs = switch (tag) {
        .x => blk: {
            const prog_bit = eval.circuit.programming_bits[eval.programming_bit_counter];
            eval.programming_bit_counter += 1;

            switch (prog_bit) {
                0 => break :blk Outputs{ .a = input_a, .b = input_b },
                1 => break :blk Outputs{ .a = input_b, .b = input_a },
            }
        },
        else => unreachable,
    };

    eval.wire_values.setValue(two_input_two_output.output_a, outputs.a);
    eval.wire_values.setValue(two_input_two_output.output_b, outputs.b);
}

fn evalLut(eval: *Eval, node: Circuit.Node.Index) !void {
    const tag = eval.circuit.nodes.items(.tag)[node];
    const lut = eval.circuit.nodes.items(.data)[node].lut;

    const input_wires = eval.circuit.luts[lut.offset..][0..lut.arity];
    const output = switch (tag) {
        .lut => blk: {
            // len = 2 ^ arity
            const table_len = @as(usize, 1) << @intCast(std.math.Log2Int(usize), lut.arity);
            const table = eval.circuit.lut_tables[lut.table_offset..][0..table_len];

            var index_into_table: usize = 0;
            for (input_wires) |input_wire, i| {
                const input = @boolToInt(eval.wire_values.isSet(input_wire));
                index_into_table |= @as(usize, input) << @intCast(std.math.Log2Int(usize), i);
            }

            break :blk switch (table[index_into_table]) {
                0 => false,
                1 => true,
            };
        },
        else => unreachable,
    };

    eval.wire_values.setValue(lut.output, output);
}

fn evalUlut(eval: *Eval, node: Circuit.Node.Index) !void {
    const tag = eval.circuit.nodes.items(.tag)[node];
    const ulut = eval.circuit.nodes.items(.data)[node].ulut;

    const input_wires = eval.circuit.luts[ulut.offset..][0..ulut.arity];
    const output = switch (tag) {
        .ulut => blk: {
            // len = 2 ^ arity
            const programming_bits_len = @as(usize, 1) << @intCast(std.math.Log2Int(usize), ulut.arity);
            const prog_bits = eval.circuit.programming_bits[eval.programming_bit_counter..][0..programming_bits_len];
            eval.programming_bit_counter += programming_bits_len;

            var index_into_prog_bits: usize = 0;
            for (input_wires) |input_wire, i| {
                const input = @boolToInt(eval.wire_values.isSet(input_wire));
                index_into_prog_bits |= @as(usize, input) << @intCast(std.math.Log2Int(usize), input_wires.len - i - 1);
            }

            break :blk switch (prog_bits[index_into_prog_bits]) {
                0 => false,
                1 => true,
            };
        },
        else => unreachable,
    };

    eval.wire_values.setValue(ulut.output, output);
}
