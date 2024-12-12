module __f32cmp__main(
  input wire [31:0] x,
  input wire [31:0] y,
  output wire out
);
  wire [7:0] x_bexp__1;
  wire [7:0] y_bexp__1;
  wire [22:0] x_fraction__1;
  wire [22:0] y_fraction__2;
  wire x_sign__1;
  wire y_sign__2;
  wire [22:0] x__1_fraction__1;
  wire [22:0] y__1_fraction__1;
  wire eq_1108;
  wire eq_exp;
  wire gt_fraction;
  wire and_1114;
  wire and_1115;
  wire and_1117;
  wire gt_exp;
  wire nor_1120;
  wire abs_gt;
  wire [2:0] concat_1130;
  wire result;
  assign x_bexp__1 = x[30:23];
  assign y_bexp__1 = y[30:23];
  assign x_fraction__1 = x[22:0];
  assign y_fraction__2 = y[22:0];
  assign x_sign__1 = x[31:31];
  assign y_sign__2 = y[31:31];
  assign x__1_fraction__1 = x_fraction__1 & {23{x_bexp__1 != 8'h00}};
  assign y__1_fraction__1 = y_fraction__2 & {23{y_bexp__1 != 8'h00}};
  assign eq_1108 = x_sign__1 == y_sign__2;
  assign eq_exp = x_bexp__1 == y_bexp__1;
  assign gt_fraction = x__1_fraction__1 > y__1_fraction__1;
  assign and_1114 = x_bexp__1 == 8'hff & x_fraction__1 != 23'h00_0000;
  assign and_1115 = y_bexp__1 == 8'hff & y_fraction__2 != 23'h00_0000;
  assign and_1117 = x_bexp__1 == 8'h00 & y_bexp__1 == 8'h00;
  assign gt_exp = x_bexp__1 > y_bexp__1;
  assign nor_1120 = ~(and_1114 | and_1115);
  assign abs_gt = gt_exp | eq_exp & gt_fraction;
  assign concat_1130 = {x_sign__1 & y_sign__2, ~(x_sign__1 | ~y_sign__2), ~(x_sign__1 | y_sign__2)};
  assign result = abs_gt & concat_1130[0] | 1'h1 & concat_1130[1] | ~abs_gt & ~(nor_1120 & (eq_1108 & eq_exp & x__1_fraction__1 == y__1_fraction__1 | and_1117)) & concat_1130[2];
  assign out = ~(and_1114 | and_1115 | (~(and_1114 | and_1115 | ~result) | nor_1120 & (eq_1108 & eq_exp & x_fraction__1 == y_fraction__2 | and_1117)));
endmodule
