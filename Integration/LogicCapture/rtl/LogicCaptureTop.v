`timescale 1ps/100fs
/* Module provides the register interface to the command and
 * control hub, encapsulate the base logic capturing peripheral,
 * and the logic required to read back data from memory and transfer
 * the data to the hub.
 *
 */
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
    
    // Asynchronous sample data input
    input  [SAMPLE_WIDTH-1:0]       sampleData_async,
    
    // Communication interface to HUB
    // 8 Input Registers
    input [7:0]                regIn0,
    input [7:0]                regIn1,
    input [7:0]                regIn2,
    input [7:0]                regIn3,
    input [7:0]                regIn4,
    input [7:0]                regIn5,
    input [7:0]                regIn6,
    input [7:0]                regIn7,
    
    // 8 Output Registers
    output reg [7:0]                regOut0,
    output reg [7:0]                regOut1,
    output reg [7:0]                regOut2,
    output reg [7:0]                regOut3,
    output reg [7:0]                regOut4,
    output reg [7:0]                regOut5,
    output reg [7:0]                regOut6,
    output reg [7:0]                regOut7,
    
    // Command input from HUB
    input [7:0]                command,
    input                      command_strobe,
    
    // Special output - status register
    output     [7:0]                status,
    
    // Interface to memory
    output [SAMPLE_PACKET_WIDTH-1:0] samplePacket,
    output                           write_enable,
    output [31:0]                    sample_number,
    input                            pageFull,
    
    input         has_return_data,
    input [127:0] return_data,
    output        get_return_data,
    output        read_req,
    input         read_allowed,
    output [26:0] read_sample_address
);

// Function code definitions
localparam  CMD_NOP                 = 8'h00,
            CMD_START               = 8'h01,
            CMD_ABORT               = 8'h02,
            CMD_TRIGGER_CONFIGURE   = 8'h03,
            CMD_BUFFER_CONFIGURE    = 8'h04,
            CMD_READ_TRACE_DATA     = 8'h05,
            CMD_READ_TRACE_SIZE     = 8'h06,
            CMD_READ_TRIGGER_SAMPLE = 8'h07,
            CMD_ACK                 = 8'h08,
            CMD_RESET               = 8'h09,
            CMD_READ_BUFF_CFG       = 8'h0A,
            CMD_READ_TRIG_CFG       = 8'h0B;

reg [SAMPLE_WIDTH-1:0] sampleData_sync0;
reg [SAMPLE_WIDTH-1:0] sampleData_sync1;
reg [SAMPLE_WIDTH-1:0] sampleData;

reg [7:0] currentCommand;
reg readbackMode;
wire start;
wire abort;
wire readTrace;
reg acknowledge;

wire cmdReset;
wire logCapReset;

/* Local Configuration Registers */
/* - Buffer Configuration - */
reg [31:0]             maxSampleCount;
reg [31:0]             preTriggerSampleCountMax;
reg [SAMPLE_WIDTH-1:0] activeChannels;

/* - Trigger Configuration - */
reg [SAMPLE_WIDTH-1:0] desiredPattern;
reg [SAMPLE_WIDTH-1:0] dontCareChannels;
reg                    patternTriggerEnable;
reg [7:0]              edgeChannel;
reg                    edgeType;
reg                    edgeTriggerEnable;

// some status data
wire [31:0] sampleNumber_Begin;
wire [31:0] sampleNumber_End;
wire [31:0] sampleNumber_Trig;
wire [31:0] traceSizeBytes;
wire [31:0] readSampleNumber;
wire postTrigger, preTrigger,idle,logIdle;
wire load_l, load_u;

// de-assert idle when start command is
// being issued;
assign idle = logIdle & ~start & (currentCommand != CMD_START);

// assign the status register
assign status      = {4'b0000, acknowledge, postTrigger, preTrigger, idle};

// Assign special logcap reset
assign logCapReset = reset | cmdReset;

// Register the applied command
always @(posedge clk) begin
    if (reset) begin
        currentCommand <= CMD_NOP;
    end else begin
        if (command_strobe) begin
            currentCommand <= command;
        end else begin
            currentCommand <= CMD_NOP;
        end
    end
end

pulseGen startPulser(
    .clk(clk),
    .reset(reset),
    .start(currentCommand == CMD_START),
    // Minimum pulses
    .pulseCount(32'd1),
    // Wait signal before deaasserting (tie to 1 if no wait)
    .waitOnMe(1'b1),
    .pulse(start)
);

pulseGen abortPulser(
    .clk(clk),
    .reset(reset),
    .start(currentCommand == CMD_ABORT),
    // Minimum pulses
    .pulseCount(32'd1),
    // Wait signal before deaasserting (tie to 1 if no wait)
    .waitOnMe(idle),
    .pulse(abort)
);

pulseGen readTracePulser(
    .clk(clk),
    .reset(reset),
    .start(currentCommand == CMD_READ_TRACE_DATA),
    // Minimum pulses
    .pulseCount(32'd1),
    // Wait signal before deaasserting (tie to 1 if no wait)
    .waitOnMe(1'b1),
    .pulse(readTrace)
);

pulseGen resetPulser(
    .clk(clk),
    .reset(reset),
    .start(currentCommand == CMD_RESET),
    // Minimum pulses
    .pulseCount(32'd1),
    // Wait signal before deaasserting (tie to 1 if no wait)
    .waitOnMe(1'b1),
    .pulse(cmdReset)
);

always @(posedge clk) begin
    if (reset) begin
        resetMe;
    end else begin
        executeCommand;
        if (readbackMode) begin
            loadTraceData;
        end
    end
end

task resetMe;
begin
    desiredPattern           <= {SAMPLE_WIDTH{1'b0}};
    activeChannels           <= {SAMPLE_WIDTH{1'b1}};
    dontCareChannels         <= {SAMPLE_WIDTH{1'b1}};
    edgeChannel              <= 32'd0;
    patternTriggerEnable     <= 1'b0;
    edgeTriggerEnable        <= 1'b0;
    edgeType                 <= 1'b0;
    maxSampleCount           <= 32'd100;
    preTriggerSampleCountMax <= 32'd0;
    readbackMode             <= 32'd0;
    regOut0                  <= 8'h00;
    regOut1                  <= 8'h00;
    regOut2                  <= 8'h00;
    regOut3                  <= 8'h00;
    regOut4                  <= 8'h00;
    regOut5                  <= 8'h00;
    regOut6                  <= 8'h00;
    regOut7                  <= 8'h00;
    acknowledge              <= 1'b0;
end
endtask

task executeCommand;
begin
   case (currentCommand)
        CMD_START:               executeStart;
        CMD_ABORT:               executeAbort;
        CMD_TRIGGER_CONFIGURE:   executeConfigTrigger;
        CMD_BUFFER_CONFIGURE:    executeConfigBuffer;
        CMD_READ_TRACE_DATA:     executeReadTraceData;
        CMD_ACK:                 clearAck;
        CMD_READ_TRACE_SIZE:     executeReadTraceSize;
        CMD_READ_TRIGGER_SAMPLE: executeReadTriggerSample;
        CMD_RESET:               executeReset;
        CMD_READ_BUFF_CFG:       readBufferConfig;
        CMD_READ_TRIG_CFG:       readTriggerConfig;
    endcase
end
endtask

// Synchronize sample inputs to this clock domain
always @(posedge clk) begin
    sampleData_sync0 <= sampleData_async;
    sampleData_sync1 <= sampleData_sync0;
    sampleData       <= sampleData_sync1;
end

LogCap #(
    .SAMPLE_WIDTH(SAMPLE_WIDTH),
    .SAMPLE_PACKET_WIDTH(SAMPLE_PACKET_WIDTH)
) ilogcap (
    .clk(clk),
    .reset(logCapReset),
    .sampleData(sampleData),
    .maxSampleCount(maxSampleCount),
    .preTriggerSampleCountMax(preTriggerSampleCountMax),
    .desiredPattern(desiredPattern),
    .activeChannels(activeChannels),
    .dontCareChannels(dontCareChannels),
    .edgeChannel(edgeChannel),
    .patternTriggerEnable(patternTriggerEnable),
    .edgeTriggerEnable(edgeTriggerEnable),
    .edgeType(edgeType),
    .postTrigger(postTrigger),
    .preTrigger(preTrigger),
    .idle(logIdle),
    .start(start),
    .abort(abort),
    .samplePacket(samplePacket),
    .write_enable(write_enable),
    .sample_number(sample_number),
    .pageFull(pageFull),
    .sampleNumber_Begin(sampleNumber_Begin),
    .sampleNumber_End(sampleNumber_End),
    .sampleNumber_Trig(sampleNumber_Trig),
    .traceSizeBytes(traceSizeBytes)
);

sampleToAdx #(
    .SAMPLE_PACKET_WIDTH(SAMPLE_PACKET_WIDTH)
) adxConversion(
    .sample_num(readSampleNumber),
    .adx(read_sample_address)
);

analyzerReadbackFSM readBackFsm(
    .clk(clk),
    .reset(logCapReset),
    .idle(idle),
    .read_trace_data(readTrace),  
    .readSampleNumber(readSampleNumber),
    .read_req(read_req),
    .read_allowed(read_allowed),
    .sampleNumber_Begin(sampleNumber_Begin),
    .sampleNumber_End(sampleNumber_End)
);

dataDumpFSM dumpFSM(
    .clk(clk),
    .reset(logCapReset),
    .dumpCmd(readTrace),
    .logcapAck(acknowledge),
    .idle(idle),
    .has_return_data(has_return_data),
    .get_return_data(get_return_data),
    .load_l(load_l),
    .load_u(load_u)
);

/*  BEGIN COMMAND TASK DEFINITIONS  */

task clearAck;
begin
    acknowledge = 1'b0;
end
endtask

task acknowledgeCmd;
begin
    acknowledge <= 1'b1;
end
endtask

task executeReset;
begin
    resetMe;
    acknowledgeCmd;
end
endtask

task executeReadTraceSize;
begin
    regOut3 <= traceSizeBytes[31:24];
    regOut2 <= traceSizeBytes[23:16];
    regOut1 <= traceSizeBytes[15:8];
    regOut0 <= traceSizeBytes[7:0];
    acknowledgeCmd;
end
endtask

task executeReadTriggerSample;
begin
    regOut3 <= sampleNumber_Trig[31:24];
    regOut2 <= sampleNumber_Trig[23:16];
    regOut1 <= sampleNumber_Trig[15:8];
    regOut0 <= sampleNumber_Trig[7:0];
    acknowledgeCmd;
end
endtask

task executeReadTraceData;
begin
    readbackMode <= 1'b1;
end
endtask

task executeConfigBuffer;
begin
    maxSampleCount           <= {regIn3, regIn2, regIn1, regIn0};
    preTriggerSampleCountMax <= {regIn7, regIn6, regIn5, regIn4};
    acknowledgeCmd;
end
endtask

task readBufferConfig;
begin
    {regOut3, regOut2, regOut1, regOut0} <= maxSampleCount;
    {regOut7, regOut6, regOut5, regOut4} <= preTriggerSampleCountMax;
    acknowledgeCmd;
end
endtask

task executeConfigTrigger;
begin
    desiredPattern       <= {regIn1, regIn0};
    activeChannels       <= {regIn3, regIn2};
    dontCareChannels     <= {regIn5, regIn4};
    edgeChannel          <= regIn6;
    patternTriggerEnable <= regIn7[0];
    edgeTriggerEnable    <= regIn7[1];
    edgeType             <= regIn7[2];
    acknowledgeCmd;
end
endtask

task readTriggerConfig;
begin
    {regOut1, regOut0} <= desiredPattern;
    {regOut3, regOut2} <= activeChannels;
    {regOut5, regOut4} <= dontCareChannels;
    regOut6            <= edgeChannel;
    regOut7            <= {5'b00000, edgeType, edgeTriggerEnable, patternTriggerEnable};
    acknowledgeCmd;
end
endtask

task executeStart;
begin
    acknowledgeCmd;
end
endtask

task executeAbort;
begin
    acknowledgeCmd;
end
endtask

task loadTraceData;
begin
    if (load_u) begin
        loadData_U;
    end else if (load_l) begin
        loadData_L;
    end
end
endtask

task loadData_L;
begin
    regOut7 <= return_data[63:56];
    regOut6 <= return_data[55:48];
    regOut5 <= return_data[47:40];
    regOut4 <= return_data[39:32];
    regOut3 <= return_data[31:24];
    regOut2 <= return_data[23:16];
    regOut1 <= return_data[15:8];
    regOut0 <= return_data[7:0];
    acknowledgeCmd;
end
endtask

task loadData_U;
begin
    regOut7 <= return_data[127:120];
    regOut6 <= return_data[119:112];
    regOut5 <= return_data[111:104];
    regOut4 <= return_data[103:96];
    regOut3 <= return_data[95:88];
    regOut2 <= return_data[87:80];
    regOut1 <= return_data[79:72];
    regOut0 <= return_data[71:64];
    acknowledgeCmd;
end
endtask
 
endmodule