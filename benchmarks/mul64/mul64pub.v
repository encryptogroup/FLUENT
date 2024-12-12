module main(input wire [63:0] a, input wire [63:0] b, output wire [63:0] c);
   mul mul_0({ a, b }, c);
endmodule // main

module mul(input wire [127:0] a, output wire [63:0] c);
   assign c = a[63:0] * a[127:63];
endmodule // mul
