module LogicCaptureControl #(
    parameter CPU_DW           = 8,
    parameter SRAM_DW         = 16,
    parameter SRAM_AW         = 16,
    parameter SAMPLE_WIDTH = 8
) (
    input  clock,
    input  reset,
    input  triggerDetected,
    input  sampleTransistion,
    input  [SAMPLE_WIDTH-1:0] sampleData,

    // CPU Interface
    input  [CPU_DW-1:0] cpu_address,
    input cpu_rdnwr, // True is read, false is write
    inout  [CPU_DW-1:0]  cpu_data,
    
    //SRAM Interface Signals
    inout   [SRAM_DW-1:0] sram_data,
    output [SRAM_AW-1:0] sram_address,
    output sram_oe,
    output sram_ce,
    output sram_we,
    
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
    localparam START_REG                             = 0;
    localparam ABORT_REG                             = 1;
    localparam ACTIVE_CHANNELS_REG           = 2;
    localparam EDGE_CHANNEL_REG                = 3;
    localparam EDGE_TYPE_REG                      = 4;
    localparam EDGE_TRIGGER_ENABLED_REG = 5;
    localparam DESIRED_PATTERN_REG           = 6;
    localparam DONT_CARE_REG                     = 7;
    localparam PATTERN_TRIGG_ENABLE_REG  = 8;
    localparam STATUS_REG                            = 9;
    
    // Assign configuration outputs to the desired registers
    assign activeChannels          = configRegisters[ACTIVE_CHANNELS_REG][SAMPLE_WIDTH-1:0];
    assign edgeChannel              = configRegisters[EDGE_CHANNEL_REG];
    assign edgeType                  = configRegisters[EDGE_TYPE_REG][0];
    assign edgeTriggerEnabled    = configRegisters[EDGE_TRIGGER_ENABLED_REG][0];
    assign desiredPattern            = configRegisters[DESIRED_PATTERN_REG][SAMPLE_WIDTH-1:0];
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
        statusRegister = {idleState, runningState, triggeredState};
    end
    
    AnalyzerControlFSM controlFSM (
        .clock(clock),
        .reset(reset),
        .start(start),
        .sawTrigger(triggerDetected),
        .abort(abort),
        .complete(complete),
        .triggered(triggeredState),
        .running(runningState),
        .idle(idleState)
    );
    
    always @(posedge clock) begin
        
    end
    
    //TODO: Implement means to write samples to memory.
    // This involves a couple of things. It involves using the FSM
    // state to determine if it is an "appropriate" time to be writing to
    // memory (ie, not writing in IDLE state). It also involves
    // using a combination of the transition detection signal, and a count of
    // samples since last sample to package up a data packet to be
    // written to sram, and providing appropriate control signals to write
    

endmodule