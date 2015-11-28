/* SampleGen.v - Module generates sample packets
 * to send to the memory interface. A packet
 * includes the data associated with the packet +
 * the number of sample clock cycles since the
 * last transition.
 *
 * Parameters -
 *  SAMPLE_WIDTH              - The number of data channels
 *  SAMPLE_PACKET_WIDTH       - The width of the packets to memory
 *  MEMORY_CAPCITY            - Total number of bytes in the memory
 *  MEMORY_WORD_WIDTH         - The number of bytes per data word in memory
 *
 */
module SampleGen #(
    parameter SAMPLE_WIDTH             = 16,
    parameter SAMPLE_PACKET_WIDTH      = 32,
    parameter MEMORY_CAPACITY          = 2**27,
    parameter MEMORY_WORD_WIDTH        = 2
) (
    input clk,
    input reset,
    
    input running,
    input transition,
    
    input [SAMPLE_WIDTH-1:0] sampleData,
    
    output reg [SAMPLE_PACKET_WIDTH-1:0] samplePacket,
    output reg [31:0]                    sample_number,
    output reg                           write_enable
);

localparam TRANSITION_COUNTER_WIDTH = SAMPLE_PACKET_WIDTH - SAMPLE_WIDTH;
localparam NUM_BYTES_PER_PACKET = SAMPLE_PACKET_WIDTH/8;
localparam NUM_WORDS_PER_PACKET = NUM_BYTES_PER_PACKET/MEMORY_WORD_WIDTH;
localparam NUM_MEMORY_WORDS     = MEMORY_CAPACITY/MEMORY_WORD_WIDTH;
localparam MAX_SAMPLE_INTERVAL  = {TRANSITION_COUNTER_WIDTH{1'b1}};
localparam MAX_SAMPLE_NUMBER    = NUM_MEMORY_WORDS/NUM_WORDS_PER_PACKET-1;

reg [TRANSITION_COUNTER_WIDTH-1:0] last_transition_count;

always @(posedge clk) begin
    if (reset) begin
        write_enable          <= 1'b0;
        sample_number         <= 32'd0;
        samplePacket          <= {SAMPLE_PACKET_WIDTH{1'b0}};
        last_transition_count <= {TRANSITION_COUNTER_WIDTH{1'b0}};
    end else begin
        if (running) begin
            if (transition | (last_transition_count === MAX_SAMPLE_INTERVAL)) begin
                samplePacket          <= {last_transition_count, sampleData};
                last_transition_count <= {TRANSITION_COUNTER_WIDTH{1'b0}};
                write_enable          <= 1'b1;
                if (sample_number === MAX_SAMPLE_NUMBER) begin
                    sample_number <= 32'd0;
                end else begin
                    sample_number <= sample_number + 1'd1;
                end
            end else begin
                samplePacket          <= samplePacket;
                last_transition_count <= last_transition_count + 1'd1;
                write_enable          <= 1'b0;
            end
        end else begin
            sample_number         <= 32'd0;
            write_enable          <= 1'b0;
            samplePacket          <= {SAMPLE_PACKET_WIDTH{1'b0}};
            last_transition_count <= {TRANSITION_COUNTER_WIDTH{1'b0}};
        end
    end
end

endmodule