`include "sha256.opt.v"

module main(
  input wire [511:0] message,
  output wire [255:0] out
);
   sha256 sha256_0(message, out);
endmodule // main

module sha256(
  input wire [511:0] message,
  output wire [255:0] out
);
   __sha256__main main(message, out);
endmodule // sha256
