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

parameter ABORT_TEST = 1;

integer cmdLog;
initial begin
    cmdLog = $fopen("COMMAND_LOG.txt", "w");
end

// Number of clocks after reset is clear
// to begin issuing commands
parameter CMD_DELAY_CLKS = 8000;
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
            CMD_READ_TRIGGER_SAMPLE = 8'h07,
            CMD_ACK                 = 8'h08,
            CMD_RESET               = 8'h09;

wire ack;
wire idle;
assign ack = status[3];
assign idle =  status[0];

localparam POS = 1'b1, NEG = 1'b0, TRUE = 1'b1, FALSE = 1'b0;

reg sequenceComplete;
initial sequenceComplete = 1'b0;

task commandSequence;
begin
    configBuffer(.preTriggerCount(20),
                 .totalSampleCount(112));
    configTriggers(.edgeTriggerEnable(FALSE),
                   .edgeTriggerChannel(2),
                   .edgeTriggerType(POS),
                   .patternTriggerEnable(TRUE),
                   .desiredPattern(16'h00ff),
                   .dontCare(16'hff00),
                   .activeChannels(16'hffff));
    issueCmd(CMD_START);
    $fdisplay(cmdLog, "Start Command Issued, waiting for idle state..");
    if (ABORT_TEST) begin
        waitNClocks(217);
        issueCmd(CMD_ABORT);
    end
    wait(idle);
    readTriggerSample;
    dataReadback;
    issueCmd(CMD_RESET);
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
            $fclose(cmdLog);
            $finish;
        end
    end
end

task issueCmd;
input [7:0] cmd;
begin
        command <= cmd;
        strobeCmd;
        ackBack;
        @(posedge clk);
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
    $fdisplay(cmdLog, "Buffer Config:");
    $fdisplay(cmdLog, "Total Sample Count: %d   Pre-Trigger Count: %d", totalSampleCount, preTriggerCount);
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
    $fdisplay(cmdLog, "Configuring Triggers:");
    $fdisplay(cmdLog, "Edge Trigger Enable: %b  Type: %b  Channel: %d", edgeTriggerEnable, edgeTriggerType, edgeTriggerChannel);
    $fdisplay(cmdLog, "Pattern Trigger Enable: %b Desired Pattern: %h, Dont Cares: %h", patternTriggerEnable, desiredPattern, dontCare);
    $fdisplay(cmdLog, "Active Channels: %h", activeChannels);
    {regIn1, regIn0} = desiredPattern;
    {regIn3, regIn2} = activeChannels;
    {regIn5, regIn4} = dontCare;
    regIn6 <= edgeTriggerChannel;
    regIn7 <= {5'b00000, edgeTriggerType, edgeTriggerEnable, patternTriggerEnable};
    issueCmd(CMD_TRIGGER_CONFIGURE);
end
endtask

task readTriggerSample;
reg [31:0] tSample;
begin
    issueCmd(CMD_READ_TRIGGER_SAMPLE);
    tSample <= {regOut3, regOut2, regOut1, regOut0};
    $fdisplay(cmdLog, "Read trigger sample value: %d", tSample);
end
endtask

task dataReadback;
reg [31:0] numBytes;
reg [63:0] sampleData;
begin
    $fdisplay(cmdLog, "Beginning readback sequence.");
    issueCmd(CMD_READ_TRACE_SIZE);
    numBytes = {regOut3, regOut2, regOut1, regOut0};
    $fdisplay(cmdLog, "Reading back %d bytes of data from LogCap", numBytes);
    repeat(numBytes/8) begin
        command <= CMD_READ_TRACE_DATA;
        strobeCmd;
        @(posedge clk);
        wait(ack);
        sampleData = {regOut7, regOut6, regOut5, regOut4, regOut3, regOut2, regOut1, regOut0};
        $fdisplay(cmdLog, "Retrieved Sample Data: %h", sampleData);
        command    <= CMD_ACK;
        strobeCmd;
        @(posedge clk);
        wait(!ack);
    end
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
input [63:0] num;
begin
    $fdisplay(cmdLog, "Waiting %d clock cycles...", num);
    repeat(num)
        @(posedge clk);
end
endtask

endmodule