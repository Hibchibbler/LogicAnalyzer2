/* Simulation only test generation for command
 * inputs to the LogicCaptureTop module
 */
module hubStub (
    input clk,
    input resetn,
    
    output reg [7:0] command,
    output reg commandStrobe,
    
    // Registers into the LogicCaptureTop
    output reg [7:0]         regIn0,
    output reg [7:0]         regIn1,
    output reg [7:0]         regIn2,
    output reg [7:0]         regIn3,
    output reg [7:0]         regIn4,
    output reg [7:0]         regIn5,
    output reg [7:0]         regIn6,
    output reg [7:0]         regIn7,
    // Registers out of the LogicCaptureTop
    input [7:0]          regOut0,
    input [7:0]          regOut1,
    input [7:0]          regOut2,
    input [7:0]          regOut3,
    input [7:0]          regOut4,
    input [7:0]          regOut5,
    input [7:0]          regOut6,
    input [7:0]          regOut7,
    input [7:0]          status
);

// Number of clocks after reset is clear
// to begin issuing commands
parameter CMD_DELAY_CLKS = 50;
// Number of clocks after the command
// sequence to delay;
parameter POST_DELAY = 20;

// Function code definitions
localparam  CMD_NOP                 = 8'h00,
            CMD_START               = 8'h01,
            CMD_ABORT               = 8'h02,
            CMD_TRIGGER_CONFIGURE   = 8'h03,
            CMD_BUFFER_CONFIGURE    = 8'h04,
            CMD_READ_TRACE_DATA     = 8'h05,
            CMD_READ_TRACE_SIZE     = 8'h06,
            CMD_READ_TRIGGER_SAMP   = 8'h07,
            CMD_ACK                 = 8'h08,
            CMD_RESET               = 8'h09,
            CMD_READ_TRIGGER_SAMPLE = 8'h10;

wire ack;
assign ack = status[3];

localparam POS = 1'b1, NEG = 1'b0, TRUE = 1'b1, FALSE = 1'b0;

reg sequenceComplete;
initial sequenceComplete = 1'b0;

task commandSequence;
begin
    configBuffer(.preTriggerCount(20),
                 .totalSampleCount(110));
    configTriggers(.edgeTriggerEnable(TRUE),
                   .edgeTriggerChannel(2),
                   .edgeTriggerType(POS),
                   .patternTriggerEnable(TRUE),
                   .desiredPattern(16'b1100110010011101),
                   .dontCare(16'h0000),
                   .activeChannels(16'hffff));
    issueCmd(CMD_START);
end
endtask

always @(posedge clk) begin
    if (~resetn) begin
        resetMe;
    end else begin
        if (~sequenceComplete) begin
            waitNClocks(CMD_DELAY_CLKS);
            commandSequence;
            waitNClocks(POST_DELAY);
            sequenceComplete = 1;
        end
    end
end

task issueCmd;
input [7:0] cmd;
begin
        command <= cmd;
        strobeCmd;
        ackBack;
end
endtask

task strobeCmd;
begin
        commandStrobe <= 1'b1;
        @(posedge clk);
        commandStrobe <= 1'b0;
end
endtask

task ackBack;
begin
        wait(ack);
        command <= CMD_ACK;
        strobeCmd;
end
endtask

task configBuffer;
input [31:0] preTriggerCount;
input [31:0] totalSampleCount;
begin
    {regIn7, regIn6, regIn5, regIn4} = preTriggerCount;
    {regIn3, regIn2, regIn1, regIn0} = totalSampleCount;
    issueCmd(CMD_BUFFER_CONFIGURE);
end
endtask

task configTriggers;
input edgeTriggerEnable;
input [7:0] edgeTriggerChannel;
input edgeTriggerType;
input patternTriggerEnable;
input [15:0] desiredPattern;
input [15:0] dontCare;
input [15:0] activeChannels;
begin
    {regIn1, regIn0} = desiredPattern;
    {regIn3, regIn2} = activeChannels;
    {regIn5, regIn4} = dontCare;
    regIn6 <= edgeTriggerChannel;
    regIn7 <= {5'b00000, edgeTriggerType, edgeTriggerEnable, patternTriggerEnable};
    issueCmd(CMD_TRIGGER_CONFIGURE);
end
endtask

task resetMe;
begin
    regIn0          <= 8'h00;
    regIn1          <= 8'h00;
    regIn2          <= 8'h00;
    regIn3          <= 8'h00;
    regIn4          <= 8'h00;
    regIn5          <= 8'h00;
    regIn6          <= 8'h00;
    regIn7          <= 8'h00;
    command         <= CMD_NOP;
    commandStrobe   <= 1'b0;
end
endtask

task waitNClocks;
input [31:0] num;
begin
    repeat(num)
        @(posedge clk);
end
endtask

endmodule