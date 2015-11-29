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
    output reg        read_req,
    
    input             read_allowed,
    input [31:0]      sampleNumber_Begin,
    input [31:0]      sampleNumber_End
);

localparam NUM_BYTES_PER_PACKET = SAMPLE_PACKET_WIDTH/8;
localparam NUM_WORDS_PER_PACKET = NUM_BYTES_PER_PACKET/MEMORY_WORD_WIDTH;
localparam NUM_MEMORY_WORDS     = MEMORY_CAPACITY/MEMORY_WORD_WIDTH;
localparam MAX_SAMPLE_NUMBER    = NUM_MEMORY_WORDS/NUM_WORDS_PER_PACKET-1;

// A state machine to go through all samples
// in memory and continually read them into the
// FIFOs until there is no more data to get
localparam IDLE = 1'b0, READING = 1'b1;
reg state, nextState;
reg moreData;

reg [31:0] nextSample;

// Calculate what the next memory sample
// should be
always @(*) begin
    if ((readSampleNumber + 4) >= MAX_SAMPLE_NUMBER) begin
        nextSample = readSampleNumber + 3 - MAX_SAMPLE_NUMBER;
    end else begin
        nextSample = readSampleNumber + 4;
    end
end

// Determine if there is more data to get
always @(*) begin
    if (sampleNumber_Begin < sampleNumber_End) begin
        moreData = (nextSample < sampleNumber_End);
    end else begin
        moreData = (nextSample < sampleNumber_End) | ((nextSample >= sampleNumber_Begin) & (nextSample <= MAX_SAMPLE_NUMBER));
    end
end

always @(posedge clk) begin
    $display(MAX_SAMPLE_NUMBER);
    if (reset) begin
        state <= IDLE;
    end else begin
        state <= nextState;
    end
end

always @(*) begin
    case(state)
        IDLE:    begin
                    if (idle & read_trace_data)
                        nextState = READING;
                    else
                        nextState = IDLE;
                 end
        READING: begin
                    if (moreData) begin
                        nextState = READING;
                    end else begin
                        // No more data, make sure to request last sample set
                        if (read_allowed) begin
                            nextState = IDLE;
                        end else begin
                            nextState = READING;
                        end
                    end
                 end
    endcase
end

always @(*) begin
    read_req = 1'b0;
    case(state)
        IDLE:    begin
                 end
        READING: begin
                    read_req = 1'b1;
                 end
    endcase
end

// Update the read sample number
// whenever a read request has been
// issued
always @(posedge clk) begin
    if (reset) begin
        readSampleNumber = 32'd0;
    end else begin
        if (state == IDLE) begin
            readSampleNumber <= sampleNumber_Begin;
        end else begin // READING
            if (read_allowed) begin
                readSampleNumber <= nextSample;
            end else begin
                readSampleNumber <= readSampleNumber;
            end
        end
    end
end


endmodule