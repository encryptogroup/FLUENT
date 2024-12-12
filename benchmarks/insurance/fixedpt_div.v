module fixedpt_div(
  input wire [31:0] a,
  input wire [31:0] b,
  output wire [31:0] out
);
  wire [63:0] udiv_411;
  assign udiv_411 = {16'h0000, a, 16'h0000} / {32'h0000_0000, b};
  assign out = udiv_411[31:0];
endmodule
