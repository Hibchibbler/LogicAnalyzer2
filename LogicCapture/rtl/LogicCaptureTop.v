module LogicCaptureTop #(
    // Parameter describes physical sample width (ie, max).
    // User may select SAMPLE_WIDTH or less active channels
    parameter SAMPLE_WIDTH        = 16,
    // This is the width of the sample packets saved to memory.
    // A packet consists of the sample plus meta-data about the
    // sample
    parameter SAMPLE_PACKET_WIDTH = 32
) (
    input  clk,
    input  reset,
    input  [SAMPLE_WIDTH-1:0] sampleData_async,
    
    input  [7:0]      config0,
    input  [7:0]      config1,
    input  [7:0]      config2,
    input  [7:0]      config3,
    input  [7:0]      config4,
    input  [7:0]      config5,
    input  [7:0]      config6,
    input  [7:0]      config7,
    input  [7:0]      config8,
    input  [7:0]      config9,
    input  [7:0]      config10,
    input  [7:0]      config11,
    input  [7:0]      config12,
    input  [7:0]      config13,
    input  [7:0]      config14,
    input  [7:0]      config15,
    input  [7:0]      config16,
    input  [7:0]      config17,
    output [7:0]      status,
    output reg [7:0] traceData_0,
    output reg [7:0] traceData_1,
    output reg [7:0] traceData_2,
    output reg [7:0] traceData_3,
    
    // Interface to memory
    output [SAMPLE_PACKET_WIDTH-1:0] samplePacket,
    output                           write_enable,
    output [31:0]                    sample_number
);

reg [SAMPLE_WIDTH-1:0] sampleData_sync0;
reg [SAMPLE_WIDTH-1:0] sampleData_sync1;
reg [SAMPLE_WIDTH-1:0] sampleData;
// Save current and previous samples
reg [SAMPLE_WIDTH-1:0] latestSample;
reg [SAMPLE_WIDTH-1:0] previousSample;

wire preTrigger, postTrigger,idle;
wire triggered,transition, complete;
wire running;
wire start;
wire abort;

wire [31:0] maxSampleCount;
wire [31:0] preTriggerSampleCount;
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
assign start = config0_reg[0];
assign abort = config1_reg[0];
// Note, this wont function correctly if input parameters
// are changed from defaults
assign desiredPattern        = {config3_reg, config2_reg};
assign activeChannels        = {config5_reg, config4_reg};
assign dontCareChannels      = {config7_reg, config6_reg};
assign edgeChannel           = config8_reg;
assign patternTriggerEnable  = config9_reg[0];
assign edgeTriggerEnable     = config9_reg[1];
assign edgeType              = config9_reg[2];
assign maxSampleCount        = {config13,config12,config11,config10};
assign preTriggerSampleCount = {config17,config16,config15,config14};

assign running = preTrigger | postTrigger;

always @(posedge clk) begin
    if (reset) begin
        config0_reg  <= 8'h00;
        config1_reg  <= 8'h00;
        config2_reg  <= 8'h00;
        config3_reg  <= 8'h00;
        config4_reg  <= 8'h00;
        config5_reg  <= 8'h00;
        config6_reg  <= 8'h00;
        config7_reg  <= 8'h00;
        config8_reg  <= 8'h00;
        config9_reg  <= 8'h00;
        config10_reg <= 8'h00;
        config11_reg <= 8'h00;
        config12_reg <= 8'h00;
        config13_reg <= 8'h00;
        config14_reg <= 8'h00;
        config15_reg <= 8'h00;
        config16_reg <= 8'h00;
        config17_reg <= 8'h00;
    end else begin
        config0_reg  <= config0;
        config1_reg  <= config1;
        config2_reg  <= config2;
        config3_reg  <= config3;
        config4_reg  <= config4;
        config5_reg  <= config5;
        config6_reg  <= config6;
        config7_reg  <= config7;
        config8_reg  <= config8;
        config9_reg  <= config9;
        config10_reg <= config10;
        config11_reg <= config11;
        config12_reg <= config12;
        config13_reg <= config13;
        config14_reg <= config14;
        config15_reg <= config15;
        config16_reg <= config16;
        config17_reg <= config17;
    end
end

// assign the status register
assign status = {5'b00000, postTrigger, preTrigger, idle};

// Synchronize sample inputs
always @(posedge clk) begin
        sampleData_sync0 <= sampleData_async;
        sampleData_sync1 <= sampleData_sync0;
        sampleData       <= sampleData_sync1;
    end
end

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
    .triggered(postTrigger),
    .running(preTrigger),
    .idle(idle)
);

SampleGen sampleGen(
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