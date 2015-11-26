module LogicCaptureControl #(
    parameter SAMPLE_WIDTH = 8,
    parameter SAMPLE_PACKET_WIDTH = 16
) (
    input  clk,
    input  reset,
    input  triggerDetected,
    input  sampleTransistion,
    input  [SAMPLE_WIDTH-1:0] sampleData,
    
    /* Configuration Outputs */
    output [SAMPLE_WIDTH-1:0] activeChannels,
    
    // Edge Trigger Configurations
    output [7:0] edgeChannel,
    output edgeType,
    output edgeTriggerEnabled,
    
    // Pattern Trigger Configurations
    output [SAMPLE_WIDTH-1:0] desiredPattern,
    output [SAMPLE_WIDTH-1:0] dontCareChannels,
    output patternTriggerEnabled
);

// Create config registers
localparam CONFIG_REG_COUNT = 10;
localparam CONFIG_REG_WIDTH = 8;
reg [CONFIG_REG_WIDTH-1:0] configRegisters [CONFIG_REG_COUNT-1:0]
reg [CONFIG_REG_WIDTH-1:0] statusRegister;

// Define which registers belong to which configuration or control mechanism
localparam START_REG                 = 0;
localparam ABORT_REG                 = 1;
localparam ACTIVE_CHANNELS_REG       = 2;
localparam EDGE_CHANNEL_REG          = 3;
localparam EDGE_TYPE_REG             = 4;
localparam EDGE_TRIGGER_ENABLED_REG  = 5;
localparam DESIRED_PATTERN_REG       = 6;
localparam DONT_CARE_REG             = 7;
localparam PATTERN_TRIGG_ENABLE_REG  = 8;
localparam STATUS_REG                = 9;

// Assign configuration outputs to the desired registers
assign activeChannels        = configRegisters[ACTIVE_CHANNELS_REG][SAMPLE_WIDTH-1:0];
assign edgeChannel           = configRegisters[EDGE_CHANNEL_REG];
assign edgeType              = configRegisters[EDGE_TYPE_REG][0];
assign edgeTriggerEnabled    = configRegisters[EDGE_TRIGGER_ENABLED_REG][0];
assign desiredPattern        = configRegisters[DESIRED_PATTERN_REG][SAMPLE_WIDTH-1:0];
assign dontCareChannels      = configRegisters[DONT_CARE_REG][SAMPLE_WIDTH-1:0];
assign patternTriggerEnabled = configRegisters[PATTERN_TRIGG_ENABLE_REG][0];

// FSM is responsible for determining status
// of the logic capture module. It is influenced
// through a combination of control from CPU
// and events with the module
// TODO: Create start/abort/complete/ inputs
wire start, abort;
assign start = configRegisters[START_REG][0];
assign abort = configRegisters[ABORT_REG][0];
wire triggeredState;
wire runningState;
wire idleState;
//assign to status register
always @* begin
    statusRegister = {5'b00000, idleState, runningState, triggeredState};
end

AnalyzerControlFSM controlFSM (
    .clk(clk),
    .reset(reset),
    .start(start),
    .sawTrigger(triggerDetected),
    .abort(abort),
    .complete(complete),
    .triggered(triggeredState),
    .running(runningState),
    .idle(idleState)
);

endmodule