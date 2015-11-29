/* SampleGen.v - Module generates sample packets
 * to send to the memory interface. A packet
 * includes the data associated with the packet +
 * the number of sample clock cycles since the
 * last transition.
 *
 * The module is also responsible for calculating and
 * outputting sample numbers that correspond to the
 * first sample in the trace, the last sample in the trace
 * and the sample that caused a trigger.
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
    
    input transition,
    input triggered,
    input preTrigger,
    input postTrigger,
    input idle,
    input start,
    input abort,
    
    input [SAMPLE_WIDTH-1:0] sampleData,
    
    output reg [SAMPLE_PACKET_WIDTH-1:0] samplePacket,
    output reg [31:0]                    sample_number,
    output reg                           write_enable,
    
    // Strobe to indicate all samples taken
    output reg complete,
    
    // Sample buffer configs
    input [31:0] maxSampleCount,
    input [31:0] preTriggerSampleCountMax,
    
    // Data about sample numbers
    output reg [31:0] sampleNum_Begin,
    output reg [31:0] sampleNum_End,
    output reg [31:0] sampleNum_Trig,
    output reg [31:0] traceSizeBytes
);

localparam TRANSITION_COUNTER_WIDTH = SAMPLE_PACKET_WIDTH - SAMPLE_WIDTH;
localparam NUM_BYTES_PER_PACKET = SAMPLE_PACKET_WIDTH/8;
localparam NUM_WORDS_PER_PACKET = NUM_BYTES_PER_PACKET/MEMORY_WORD_WIDTH;
localparam NUM_MEMORY_WORDS     = MEMORY_CAPACITY/MEMORY_WORD_WIDTH;
localparam MAX_SAMPLE_INTERVAL  = {TRANSITION_COUNTER_WIDTH{1'b1}};
localparam MAX_SAMPLE_NUMBER    = NUM_MEMORY_WORDS/NUM_WORDS_PER_PACKET-1;

reg [TRANSITION_COUNTER_WIDTH-1:0] last_transition_count;

reg [31:0] triggerSampleNumber;
reg [31:0] postTriggerSamplesMax;
reg [31:0] preTriggerSampleCount;
reg [31:0] postTriggerSampleCount;
reg [31:0] totalSamplesTaken;

// These are for status reporting and readback memory calculations
reg [31:0] capturedSampleCount;

wire running;
assign running =  preTrigger | postTrigger;

always @(posedge clk) begin
    if (reset) begin
        write_enable          <= 1'b0;
        sample_number         <= 32'hffffffff;
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
            sample_number         <= 32'hffffffff;
            write_enable          <= 1'b0;
            samplePacket          <= {SAMPLE_PACKET_WIDTH{1'b0}};
            last_transition_count <= {TRANSITION_COUNTER_WIDTH{1'b0}};
        end
    end
end

// Capture the sample number the trigger occurs at
always @(posedge clk) begin
    if (reset) begin
        triggerSampleNumber <= 32'd0;
    end else begin
        if (triggered & preTrigger) begin
            // Sample number of the triggered sample will
            // be the next sample written to memory
            triggerSampleNumber <= sample_number + 1;
        end else if(postTrigger) begin
            triggerSampleNumber <= triggerSampleNumber;
        end else begin
            triggerSampleNumber <= 32'd0;
        end
    end
end

// Keep track of sample count before/after the trigger
always @(posedge clk) begin
    if (reset) begin
        postTriggerSampleCount <= 32'd0;
        preTriggerSampleCount  <= 32'd0;
    end else begin
        if (postTrigger) begin
            if (write_enable) begin
                postTriggerSampleCount <= postTriggerSampleCount + 1;
            end else begin
                postTriggerSampleCount <= postTriggerSampleCount;
            end
        end else begin
            postTriggerSampleCount <= 32'd0;
        end
        if (preTrigger) begin
            if (write_enable) begin
                if (preTriggerSampleCount === preTriggerSampleCountMax) begin
                    preTriggerSampleCount <= preTriggerSampleCount;
                end else begin
                    preTriggerSampleCount <= preTriggerSampleCount + 1;
                end
            end else begin
                preTriggerSampleCount <= preTriggerSampleCount;
            end
        end else begin
            preTriggerSampleCount <= preTriggerSampleCount;
        end
    end
end

// Capture the final sample number, trigger sample,
// and total sample count to use for reading back data
always @(posedge clk) begin
    if (reset) begin
        sampleNum_End        <= 32'd0;
        sampleNum_Trig       <= 32'd0;
        capturedSampleCount  <= 32'd0;
    end else begin
        if ((complete | abort) & running) begin
            sampleNum_End       <= sample_number;
            sampleNum_Trig      <= triggerSampleNumber;
            capturedSampleCount <= totalSamplesTaken;
        end else begin
            sampleNum_End       <= sampleNum_End;
            sampleNum_Trig      <= sampleNum_Trig;
            capturedSampleCount <= capturedSampleCount;
        end
    end
end

// Various calculations on sample numbers
always @(*) begin
    if ((sampleNum_End - capturedSampleCount + 1) >= 0) begin
        sampleNum_Begin = sampleNum_End - capturedSampleCount + 1;
    end else begin
        sampleNum_Begin = sampleNum_End - capturedSampleCount + 1 + MAX_SAMPLE_NUMBER;
    end
    totalSamplesTaken     = postTriggerSampleCount + preTriggerSampleCount;
    postTriggerSamplesMax = maxSampleCount - preTriggerSampleCountMax;
    traceSizeBytes        = capturedSampleCount*NUM_BYTES_PER_PACKET;
    if (postTrigger) begin
        complete = (totalSamplesTaken === maxSampleCount);
    end else begin
        complete = 0;
    end
end


endmodule