module main(input wire [255:0] a, input wire [255:0] b, output wire [255:0] c);
   mul mul_0({ a, b }, c);
endmodule // main

module mul(input wire [511:0] a, output wire [255:0] c);
   assign c = a[255:0] * a[511:256];
endmodule // mul
