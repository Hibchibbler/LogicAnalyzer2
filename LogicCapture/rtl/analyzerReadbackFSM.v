/* analyzerReadbackFSM.v - Module is responsible for issuing
 * read requests to the memory interface at the rate throttled
 * by the data consumer.
 */

module analyzerReadbackFSM #(
    parameter SAMPLE_WIDTH        = 16,
    parameter SAMPLE_PACKET_WIDTH = 32,
    parameter MEMORY_CAPACITY     = 2**27,
    parameter MEMORY_WORD_WIDTH   = 2
)(
    input             clk,
    input             reset,
    input             idle, // sampler is in idle state
    input             read_trace_data,  
    output reg [31:0] readSampleNumber,
    output            read_req,
    
    input             read_allowed,
    input             sampleNumber_Begin,
    input             sampleNumber_End
);

localparam NUM_BYTES_PER_PACKET = SAMPLE_PACKET_WIDTH/8;
localparam NUM_WORDS_PER_PACKET = NUM_BYTES_PER_PACKET/MEMORY_WORD_WIDTH;
localparam NUM_MEMORY_WORDS     = MEMORY_CAPACITY/MEMORY_WORD_WIDTH;
localparam MAX_SAMPLE_NUMBER    = NUM_MEMORY_WORDS/NUM_WORDS_PER_PACKET-1;

// A state machine to go through all samples
// in memory and continually read them into the
// FIFOs until there is no more data to get
localparam BUF_IDLE = 1'b0, BUF_RDG = 1'b1;
reg bufDataState; bufDataNextState;
reg moreDramData;

always @(posedge clk) begin
    if (reset) begin
        bufDataState <= IDLE;
    end else begni
        bufDataState <= bufDataNextState;
    end
end

always @(*) begin
    case(bufDataState)
        BUF_IDLE: begin
                    if (read_trace_data & idle) begin
                        bufDataNextState = BUF_RDG;
                    end else begin
                        bufDataNextState = BUF_IDLE;
                    end
                  end
        BUF_RDG:  begin
                    if (moreDramData) begin
                        bufDataNextState = BUF_RDG;
                    end else begin
                        bufDataNextState = BUF_IDLE;
                    end
                  end
    endcase
end

always @(posedge clk) begin
    if (reset) begin
        read_req         <= 1'b0;
        readSampleNumber <= 32'd0;
        moreDramData     <= 1'b0;
    end else begin
        if (state === BUF_RDG) begin
            read_req <= 1'b1;
            if (readSampleNumber === sampleNumber_End) begin
                moreDramData <= 1'b0;
            end else begin
                moreDramData <= 1'b1;
            end
            if (read_allowed) begin
                if (readSampleNumber === MAX_SAMPLE_NUMBER) begin
                    readSampleNumber <= 32'd0;
                end else begin
                    readSampleNumber <= readSampleNumber + 32'd1;
                end
            end else begin
                readSampleNumber <= readSampleNumber;
            end
        end else if (state == BUF_IDLE) begin
            read_req         <= 1'b0;
            readSampleNumber <= sampleNumber_Begin;
            moreDramData     <= 1'b1;
        end
    end
end



endmodule