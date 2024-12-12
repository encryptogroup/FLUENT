module main(input wire [7:0] a, input wire [7:0] b, output wire [7:0] c);
   mul mul_0({ a, b }, c);
endmodule // main

(* private *)
module mul(input wire [15:0] a, output wire [7:0] c);
   assign c = a[7:0] * a[15:8];
endmodule // mul
