module main(input wire [63:0] a, input wire [63:0] b, output wire [63:0] c);
   add add_0({ a, b }, c);
endmodule // main

module add(input wire [127:0] a, output wire [63:0] c);
   assign c = a[63:0] + a[127:63];
endmodule // add
