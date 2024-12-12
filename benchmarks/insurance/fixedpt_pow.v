module fixedpt_pow(
  input wire [31:0] p,
  input wire [7:0] b,
  output wire [31:0] out
);
  // lint_off MULTIPLY
  function automatic [63:0] umul64b_32b_x_32b (input reg [31:0] lhs, input reg [31:0] rhs);
    begin
      umul64b_32b_x_32b = lhs * rhs;
    end
  endfunction
  // lint_on MULTIPLY
  wire [7:0] b2;
  wire [31:0] result;
  wire [63:0] umul_411;
  wire [31:0] result__2;
  wire [63:0] umul_414;
  wire [63:0] umul_417;
  wire [31:0] result__3;
  wire [63:0] umul_420;
  wire [63:0] umul_423;
  wire [31:0] result__4;
  wire [63:0] umul_426;
  wire [63:0] umul_429;
  wire [31:0] result__5;
  wire [63:0] umul_432;
  wire [63:0] umul_435;
  wire [31:0] result__6;
  wire [63:0] umul_438;
  wire [63:0] umul_441;
  wire [31:0] result__7;
  wire [63:0] umul_444;
  wire [63:0] umul_447;
  wire [31:0] result__8;
  wire [63:0] umul_450;
  wire [31:0] result__9;
  wire [63:0] udiv_457;
  assign b2 = b[7] ? -b : b;
  assign result = 32'h0001_0000;
  assign umul_411 = (p * p);
  assign result__2 = b2[0] ? p : result;
  assign umul_414 = (result__2 *umul_411[47:16]);
  assign umul_417 = (umul_411[47:16] * umul_411[47:16]);
  assign result__3 = b2[1] ? umul_414[47:16] : result__2;
  assign umul_420 = (result__3 * umul_417[47:16]);
  assign umul_423 = (umul_417[47:16] * umul_417[47:16]);
  assign result__4 = b2[2] ? umul_420[47:16] : result__3;
  assign umul_426 = (result__4 * umul_423[47:16]);
  assign umul_429 = (umul_423[47:16] * umul_423[47:16]);
  assign result__5 = b2[3] ? umul_426[47:16] : result__4;
  assign umul_432 = (result__5 * umul_429[47:16]);
  assign umul_435 = (umul_429[47:16] * umul_429[47:16]);
  assign result__6 = b2[4] ? umul_432[47:16] : result__5;
  assign umul_438 = (result__6 * umul_435[47:16]);
  assign umul_441 = (umul_435[47:16] * umul_435[47:16]);
  assign result__7 = b2[5] ? umul_438[47:16] : result__6;
  assign umul_444 = (result__7 * umul_441[47:16]);
  assign umul_447 = (umul_441[47:16] * umul_441[47:16]);
  assign result__8 = b2[6] ? umul_444[47:16] : result__7;
  assign umul_450 = (result__8 * umul_447[47:16]);
  assign result__9 = b2[7] ? umul_450[47:16] : result__8;
  assign udiv_457 = 64'h0000_0001_0000_0000 / {32'h0000_0000, result__9};
  assign out = b[7] ? udiv_457[31:0] : result__9;
endmodule
