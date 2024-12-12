const std = @import("std");

nodes: std.MultiArrayList(Node).Slice,
luts: []const Node.Index,
inputs: []const Node.Index,
outputs: []const Node.Index,
lut_tables: []const u1,
programming_bits: []const u1,
max_wire_number: Node.Index,

pub const Node = struct {
    tag: Tag,
    data: Data,

    pub const Tag = enum(u8) {
        /// Constant zero. Uses constant field
        zero,
        /// Constant one. Uses constant field
        one,
        /// Invert. Uses one_input field
        inv,
        /// And. Uses two_input field
        @"and",
        /// Exclusive or. Uses two_input field
        xor,
        /// Look-up table. Uses lut field
        lut,
        /// X gate. Uses two_input_two_output field
        x,
        /// Y gate. Uses two_input field
        y,
        /// Universal look-up table. Uses ulut field
        ulut,
        /// Yao to SPLUT gate. Uses one_input field
        y2s,
        /// SPLUT to Yao gate. Uses one_input field
        s2y,
    };

    pub const Index = u64;

    pub const Data = union {
        constant: struct {
            output: Index,
        },
        one_input: struct {
            input: Index,
            output: Index,
        },
        two_input: struct {
            input_a: Index,
            input_b: Index,
            output: Index,
        },
        two_input_two_output: struct {
            input_a: Index,
            input_b: Index,
            output_a: Index,
            output_b: Index,
        },
        lut: struct {
            offset: Index,
            table_offset: Index,
            arity: u8,
            output: Index,
        },
        ulut: struct {
            offset: Index,
            arity: u8,
            output: Index,
        },
    };
};
