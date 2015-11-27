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
    
    input [7:0]      config0,
    input [7:0]      config1,
    input [7:0]      config2,
    input [7:0]      config3,
    input [7:0]      config4,
    input [7:0]      config5,
    input [7:0]      config6,
    input [7:0]      config7,
    input [7:0]      config8,
    input [7:0]      config9,
    output reg [7:0] status,
    output reg [7:0] traceData_0,
    output reg [7:0] traceData_1,
    output reg [7:0] traceData_2,
    output reg [7:0] traceData_3
);

reg [SAMPLE_WIDTH-1:0] sampleData_sync0;
reg [SAMPLE_WIDTH-1:0] sampleData_sync1;
reg [SAMPLE_WIDTH-1:0] sampleData;

wire startBit;
wire abortBit;

wire [SAMPLE_WIDTH-1:0] desiredPattern;
wire [SAMPLE_WIDTH-1:0] activeChannels;
wire [SAMPLE_WIDTH-1:0] dontCareChannels;
wire [7:0] edgeChannel;
wire patternTriggerEnable;
wire edgeTriggerEnable;
wire edgeType;

reg [7:0] config0_reg;
reg [7:0] config1_reg;
reg [7:0] config2_reg;
reg [7:0] config3_reg;
reg [7:0] config4_reg;
reg [7:0] config5_reg;
reg [7:0] config6_reg;
reg [7:0] config7_reg;
reg [7:0] config8_reg;
reg [7:0] config9_reg;

// Assign the config registers
assign startBit = config0[0];
assign abortBit = config1[0];
// Note, this wont function correctly if input parameters
// are changed from defaults
assign desiredPattern       = {config3, config2};
assign activeChannels       = {config5, config4};
assign dontCareChannels     = {config7, config6};
assign edgeChannel          = config8;
assign patternTriggerEnable = config9[0];
assign edgeTriggerEnable    = config9[1];
assign edgeType             = config9[2];


always @(posedge clk) begin
    if (reset) begin
        config0_reg <= 8'h00;
        config1_reg <= 8'h00;
        config2_reg <= 8'h00;
        config3_reg <= 8'h00;
        config4_reg <= 8'h00;
        config5_reg <= 8'h00;
        config6_reg <= 8'h00;
        config7_reg <= 8'h00;
        config8_reg <= 8'h00;
        config9_reg <= 8'h00;
    end else begin
        config0_reg <= config0;
        config1_reg <= config1;
        config2_reg <= config2;
        config3_reg <= config3;
        config4_reg <= config4;
        config5_reg <= config5;
        config6_reg <= config6;
        config7_reg <= config7;
        config8_reg <= config8;
        config9_reg <= config9;
    end
end

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