/* SampleGen.v - Module generates sample packets
 * to send to the memory interface.
 */
module SampleGen #(
    SAMPLE_WIDTH        = 8,
    SAMPLE_PACKET_WIDTH = 16,
    // MAX_SAMPLE_NUMBER is dependent on
    // the memory being used. The sample
    // number is used to convert to an address
    // in memory, so it must be less than
    // or equal to the number of sample packets
    // that can fit in memory
    MAX_SAMPLE_NUMBER   = 32'd8388607
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

localparam META_WIDTH          = SAMPLE_PACKET_WIDTH-SAMPLE_WIDTH;
localparam MAX_SAMPLE_INTERVAL = {META_WIDTH{1'b1}};

reg [META_WIDTH-1:0] last_transition_count;

always @(posedge clk) begin
    if (reset) begin
        write_enable          <= 1'b0;
        sample_number         <= 32'd0;
        samplePacket          <= {SAMPLE_PACKET_WIDTH{1'b0}};
        last_transition_count <= {META_WIDTH{1'b0}};
    end else begin
        if (running) begin
            if (transition | (last_transition_count === MAX_SAMPLE_INTERVAL)) begin
                samplePacket          <= {last_transition_count, sampleData};
                last_transition_count <= {META_WIDTH{1'b0}};
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
            last_transition_count <= {META_WIDTH{1'b0}};
        end
    end
end

endmodule