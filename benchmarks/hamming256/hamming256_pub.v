module main(input wire [255:0] a, input wire [255:0] b, output wire [7:0] c);
   hamming#(256) hamming_0({ a, b }, c);
endmodule // main

module hamming #(parameter WIDTH = 8)
  (
    input [2*WIDTH-1:0] vectors,
    output reg [WIDTH-1:0] distance
  );

   wire [WIDTH-1:0]        vector1;
   wire [WIDTH-1:0]        vector2;

  integer                 i;

   assign vector1 = vectors[WIDTH-1:0];
   assign vector2 = vectors[2*WIDTH-1:WIDTH];


  always @* begin
    distance = 0;
    for (i = 0; i < WIDTH; i = i + 1) begin
      if (vector1[i] != vector2[i]) begin
        distance = distance + 1;
      end
    end
  end

endmodule


// module hamming(input wire [511:0] a, output wire [7:0] c);
//    wire [255:0] xor = a ^ b;

//    always @* begin
//       c = 0;
//       for (int i = 0; i < 256; i++) begin
//          c +=
//       end
//    end
// endmodule // hamming
