`include "f32cmp.opt.v"

module main(input wire [31:0] a, input wire [31:0] b, output wire c);
   cmp cmp_0({ a, b }, c);
endmodule // main

module cmp(input wire [63:0] a, output wire [31:0] c);
   __f32cmp__main main(a[31:0], a[63:32], c);
endmodule // cmp
