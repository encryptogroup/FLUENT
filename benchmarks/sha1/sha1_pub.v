`include "sha1.v"

module main(
  input wire [511:0] block,
  input wire [159:0] current_hash,
  output wire [159:0] new_hash
);
   sha1_wrapper sha1_wrapper_0({ block, current_hash }, new_hash);
endmodule // main

module sha1_wrapper(
  input wire [671:0] block_current_hash,
  output wire [159:0] new_hash
);
   sha1 sha1_0(block_current_hash[511:0], block_current_hash[671:512], new_hash);
endmodule // sha256
