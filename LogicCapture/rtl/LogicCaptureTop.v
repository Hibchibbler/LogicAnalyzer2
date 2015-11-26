module LogicCaptureTop #(
    // Parameter describes physical sample width (ie, max).
    // User may select SAMPLE_WIDTH or less active channels
    parameter SAMPLE_WIDTH        = 8,
    // This is the width of the sample packets saved to memory.
    // A packet consists of the sample plus meta-data about the
    // sample
    parameter SAMPLE_PACKET_WIDTH = 16
) (
    input  clk,
    input  reset,
    
    input  [SAMPLE_WIDTH-1:0] sampleData_async,
);

reg [SAMPLE_WIDTH-1:0] sampleData_sync0;
reg [SAMPLE_WIDTH-1:0] sampleData_sync1;
reg [SAMPLE_WIDTH-1:0] sampleData;

wire [SAMPLE_WIDTH-1:0] desiredPattern;
wire [SAMPLE_WIDTH-1:0] activeChannels;
wire [SAMPLE_WIDTH-1:0] dontCareChannels;
wire [31:0] edgeChannel;
wire patternTriggerEnable;
wire edgeTriggerEnable;
wire edgeType;

// Synchronize sample inputs
always @(posedge clk) begin
        sampleData_sync0 <= sampleData_async;
        sampleData_sync1 <= sampleData_sync0;
        sampleData       <= sampleData_sync1;
    end
end

// Save current and previous samples
reg [SAMPLE_WIDTH-1:0] latestSample;
reg [SAMPLE_WIDTH-1:0] previousSample;

always @(posedge clk) begin
    if (reset) begin
        latestSample   <= {SAMPLE_WIDTH{1'b0}};
        previousSample <= {SAMPLE_WIDTH{1'b0}};
    end else begin
        latestSample   <= sampleData;
        previousSample <= latestSample;
    end
end

// Trigger and Transition Detection
wire triggered,transition;
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
 
LogicCaptureControl #(
    .SAMPLE_WIDTH(SAMPLE_WIDTH),
    .SAMPLE_PACKET_WIDTH(SAMPLE_PACKET_WIDTH)
) controlUnit (
    .clk(clk),
    .reset(reset),
    .triggerDetected(triggered),
    .sampleTransistion(transition),
    .sampleData(latestSample),
    .edgeChannel(edgeChannel),
    .edgeType(edgeType),
    .edgeTriggerEnabled(edgeTriggerEnable),
    .desiredPattern(desiredPattern),
    .dontCareChannels(dontCareChannels),
    .patternTriggerEnabled(patternTriggerEnable),
    .activeChannels(activeChannels)
);

endmodule