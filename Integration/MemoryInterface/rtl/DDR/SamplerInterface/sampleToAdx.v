/* sampleToAdx.v
 * Converts a sample number to a legal address for memory
 *
 * Author: Brandon Mousseau bam7@pdx.edu
 */
module sampleToAdx #(
    parameter SAMPLE_PACKET_WIDTH = 32,
    parameter ADX_WIDTH           = 27,
    parameter MEMORY_WORD_WIDTH   = 2
) (
    input [31:0]                    sample_num,
    output     [ADX_WIDTH-1:0]      adx
);

localparam NUM_BYTES_PER_PACKET = SAMPLE_PACKET_WIDTH/8;
localparam NUM_WORDS_PER_PACKET = NUM_BYTES_PER_PACKET/MEMORY_WORD_WIDTH; //2
localparam SAMPLE_MASK_WIDTH = 3;

wire [31:0] sampleNumMod;
assign sampleNumMod = sample_num*NUM_WORDS_PER_PACKET;
assign adx = {sampleNumMod[31:SAMPLE_MASK_WIDTH], {SAMPLE_MASK_WIDTH{1'b0}}};

endmodule