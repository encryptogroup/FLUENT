module fixedpt_mul(
  input wire [31:0] a,
  input wire [31:0] b,
  output wire [31:0] out
);
  // lint_off MULTIPLY
  function automatic [63:0] umul64b_32b_x_32b (input reg [31:0] lhs, input reg [31:0] rhs);
    begin
      umul64b_32b_x_32b = lhs * rhs;
    end
  endfunction
  // lint_on MULTIPLY
  wire [63:0] umul_406;
  assign umul_406 = (a * b);
  assign out = umul_406[47:16];
endmodule
