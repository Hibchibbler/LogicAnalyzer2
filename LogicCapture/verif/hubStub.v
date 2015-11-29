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

reg [31:0] clkCount;
parameter CMD_DELAY_CLKS = 5000;

wire cmdsAllowed;
assign cmdsAllowed = (clkCount > CMD_DELAY_CLKS);

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

always @(posedge clk) begin
    if (~resetn) begin
        resetMe;
    end else begin
        if (cmdsAllowed) begin
            configBuffer(32'd20, 32'd110);
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
    {regIn3, regIn2, regIn1, regIn0} <= totalSampleCount;
    {regIn7, regIn6, regIn5, regIn4} <= preTriggerCount;
    issueCmd(CMD_BUFFER_CONFIGURE);
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

// Counter to keep track of clk counts since reset
// is deasserted
always @(posedge clk) begin
    if (~resetn) begin
        clkCount <= 32'd0;
    end else begin
        clkCount <= clkCount + 1;
    end
end

endmodule