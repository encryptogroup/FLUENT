`include "f32mul.opt.v"

module main(input wire [31:0] a, input wire [31:0] b, output wire [31:0] c);
   add add_0({ a, b }, c);
endmodule // main

(* private *)
module add(input wire [63:0] a, output wire [31:0] c);
   __f32mul__main main(a[31:0], a[63:32], c);
endmodule // add
