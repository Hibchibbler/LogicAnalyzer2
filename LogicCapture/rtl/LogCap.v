module #(
    SAMPLE_WIDTH        = 16,
    SAMPLE_PACKET_WIDTH = 32
) LogCap (
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
    
    output     [7:0]                status,
    
    output [SAMPLE_PACKET_WIDTH-1:0] samplePacket,
    output                           write_enable,
    output [31:0]                    sample_number
);

reg [31:0] postTriggerSamples;
reg [SAMPLE_WIDTH-1:0] latestSample;
reg [SAMPLE_WIDTH-1:0] previousSample;

wire running;

wire postTrigger, preTrigger, idle;

wire triggered, transition;
reg complete;

assign status = {5'b00000, postTrigger, preTrigger, idle};

assign running = preTrigger | postTrigger;

always @(*) begin
    postTriggerSamples = totalSamples - preTriggerSamples;
    complete = (sample_num - triggerSampleNumber) >= postTriggerSamples;
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