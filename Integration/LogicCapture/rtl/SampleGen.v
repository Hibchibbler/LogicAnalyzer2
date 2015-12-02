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
    
    input pageFull,
    
    input [SAMPLE_WIDTH-1:0] sampleData,
    
    output reg [SAMPLE_PACKET_WIDTH-1:0] samplePacket,
    output reg [31:0]                    sample_number,
    output reg                           write_enable,
    
    // Strobe to indicate all samples taken
    output reg complete,
    
    // Sample buffer configs
    input [31:0] maxSampleCount,
    input [31:0] preTriggerSampleCountMax,
    
    // Page aligned data about sample numbers
    output [31:0] sampleNum_Begin_pa,
    output [31:0] sampleNum_End_pa,
    output [31:0] sampleNum_Trig_pa,
    output reg [31:0] traceSizeBytes
);

localparam TRANSITION_COUNTER_WIDTH = SAMPLE_PACKET_WIDTH - SAMPLE_WIDTH;
localparam NUM_BYTES_PER_PACKET = SAMPLE_PACKET_WIDTH/8;
localparam NUM_WORDS_PER_PACKET = NUM_BYTES_PER_PACKET/MEMORY_WORD_WIDTH;
localparam NUM_MEMORY_WORDS     = MEMORY_CAPACITY/MEMORY_WORD_WIDTH;
localparam MAX_SAMPLE_INTERVAL  = {TRANSITION_COUNTER_WIDTH{1'b1}};
localparam MAX_SAMPLE_NUMBER    = NUM_MEMORY_WORDS/NUM_WORDS_PER_PACKET-1;

reg [TRANSITION_COUNTER_WIDTH-1:0] last_transition_count;
reg [31:0] sampleNum_Begin;
reg [31:0] sampleNum_End;
reg [31:0] sampleNum_Trig;
reg [31:0] triggerSampleNumber;
reg [31:0] postTriggerSamplesMax;
reg [31:0] preTriggerSampleCount;
reg [31:0] postTriggerSampleCount;
reg [31:0] totalSamplesTaken;

// Create some page aligned versions of the values
// to play nicely with memory interface
reg signed [31:0] pageAlignedSampleCount;
reg signed [31:0] sampleNum_End_pageAligned;
reg signed [31:0] sampleNum_Begin_pageAligned;
reg signed [31:0] sampleNum_Trig_pageAligned;

assign sampleNum_Begin_pa = sampleNum_Begin_pageAligned;
assign sampleNum_End_pa   = sampleNum_End_pageAligned;
assign sampleNum_Trig_pa  = sampleNum_Trig_pageAligned;

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
    if (postTrigger) begin
        complete = (totalSamplesTaken >= maxSampleCount) & pageFull;
    end else begin
        complete = 0;
    end
end

// Create the page aligned final sample numbers/byte size.
// This will shift the capture window a few samples such that
// the data returned to the client is page aligned with what
// is in memory.
always @(*) begin
    if (sampleNum_End[1:0] == 2'b11) begin
        sampleNum_End_pageAligned = sampleNum_End;
    end else begin
        if (sampleNum_End == 32'd0) begin
            sampleNum_End_pageAligned = MAX_SAMPLE_NUMBER;
        end else begin
            sampleNum_End_pageAligned = sampleNum_End-1;
            sampleNum_End_pageAligned = {sampleNum_End_pageAligned[31:2], 2'b11};
        end
    end
    if (sampleNum_Begin[1:0] == 2'b00) begin
        sampleNum_Begin_pageAligned = sampleNum_Begin;
    end else begin
        sampleNum_Begin_pageAligned = {sampleNum_Begin[31:2], 2'b00};
    end
    if (sampleNum_End_pageAligned >= sampleNum_Begin_pageAligned) begin
        pageAlignedSampleCount = sampleNum_End_pageAligned - sampleNum_Begin_pageAligned + 1;
    end else begin
        pageAlignedSampleCount = MAX_SAMPLE_NUMBER - sampleNum_Begin_pageAligned + sampleNum_End_pageAligned + 2;
    end
    traceSizeBytes = pageAlignedSampleCount*NUM_BYTES_PER_PACKET;
    sampleNum_Trig_pageAligned = sampleNum_Trig + (sampleNum_Begin - sampleNum_Begin_pageAligned);
end

endmodule