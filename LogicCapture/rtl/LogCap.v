module LogCap #(
    parameter SAMPLE_WIDTH        = 16,
    parameter SAMPLE_PACKET_WIDTH = 32
) (
    input clk,
    input reset,
    input  [SAMPLE_WIDTH-1:0] sampleData,
    input [31:0] maxSampleCount,
    input [31:0] preTriggerSampleCount,
    input [SAMPLE_WIDTH-1:0] desiredPattern,
    input [SAMPLE_WIDTH-1:0] activeChannels,
    input [SAMPLE_WIDTH-1:0] dontCareChannels,
    input [7:0] edgeChannel,
    input patternTriggerEnable,
    input edgeTriggerEnable,
    input edgeType,
    input start,
    input abort,
    output     [7:0]                 status,
    output [SAMPLE_PACKET_WIDTH-1:0] samplePacket,
    output                           write_enable,
    output [31:0]                    sample_number
);

reg [31:0] triggerSampleNumber;

reg [31:0] postTriggerSamples;
reg [SAMPLE_WIDTH-1:0] latestSample;
reg [SAMPLE_WIDTH-1:0] previousSample;

wire running;

wire postTrigger, preTrigger, idle;

wire triggered, transition;
reg complete;

always @(posedge clk) begin
    if (reset) begin
        triggerSampleNumber <= 32'd0;
    end else begin
        if (triggered & preTrigger) begin
            triggerSampleNumber <= sample_number;
        end else if(postTrigger) begin
            triggerSampleNumber <= triggerSampleNumber;
        end else begin
            triggerSampleNumber <= 32'd0;
        end
    end
end

assign status = {5'b00000, postTrigger, preTrigger, idle};

assign running = preTrigger | postTrigger;

always @(*) begin
    postTriggerSamples = maxSampleCount - preTriggerSampleCount;
    complete = (sample_number - triggerSampleNumber) >= postTriggerSamples;
end

// Capture sample data values
always @(posedge clk) begin
    if (reset) begin
        latestSample   <= {SAMPLE_WIDTH{1'b0}};
        previousSample <= {SAMPLE_WIDTH{1'b0}};
    end else begin
        latestSample   <= sampleData;
        previousSample <= latestSample;
    end
end

TriggerTransDetection #(
    .SAMPLE_WIDTH(SAMPLE_WIDTH)
) triggerModule (
    .latestSample(latestSample),
    .previousSample(previousSample),
    .triggered(triggered),
    .transition(transition),
    .activeChannels(activeChannels),
    .edgeChannel(edgeChannel),
    .edgeType(edgeType),
    .edgeTriggerEnabled(edgeTriggerEnable),
    .patternTriggerEnabled(patternTriggerEnable),
    .desiredPattern(desiredPattern),
    .dontCareChannels(dontCareChannels)
);

AnalyzerControlFSM controlFSM (
    .clk(clk),
    .reset(reset),
    .start(start),
    .sawTrigger(triggered),
    .abort(abort),
    .complete(complete),
    .post_trigger(postTrigger),
    .pre_trigger(preTrigger),
    .idle(idle)
);

SampleGen #(
    .SAMPLE_WIDTH(SAMPLE_WIDTH),
    .SAMPLE_PACKET_WIDTH(SAMPLE_PACKET_WIDTH)
) sampleGen(
    .clk(clk),
    .reset(reset),
    .running(running),
    .transition(transition),
    .sampleData(latestSample),
    .samplePacket(samplePacket),
    .sample_number(sample_number),
    .write_enable(write_enable)
);

endmodule