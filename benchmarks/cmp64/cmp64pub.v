module main(input wire [63:0] a, input wire [63:0] b, output wire c);
   cmp cmp_0({ a, b }, c);
endmodule // main

module cmp(input wire [127:0] a, output wire c);
   assign c = a[63:0] > a[127:63];
endmodule // add
