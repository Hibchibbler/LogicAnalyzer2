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
    input wire [7:0]                regIn0,
    input wire [7:0]                regIn1,
    input wire [7:0]                regIn2,
    input wire [7:0]                regIn3,
    input wire [7:0]                regIn4,
    input wire [7:0]                regIn5,
    input wire [7:0]                regIn6,
    input wire [7:0]                regIn7,
    
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
    input wire [7:0]                command,
    input wire                      command_strobe,
    
    // Special output - status register
    output     [7:0]                status
    
    // Interface to memory
    output [SAMPLE_PACKET_WIDTH-1:0] samplePacket,
    output                           write_enable,
    output [31:0]                    sample_number
);

localparam  CMD_NOP                 = 8'h00,
            CMD_START               = 8'h01,
            CMD_ABORT               = 8'h02,
            CMD_TRIGGER_CONFIGURE   = 8'h03,
            CMD_BUFFER_CONFIGURE    = 8'h04,
            CMD_READ_TRACE_DATA     = 8'h05;

reg [SAMPLE_WIDTH-1:0] sampleData_sync0;
reg [SAMPLE_WIDTH-1:0] sampleData_sync1;
reg [SAMPLE_WIDTH-1:0] sampleData;

reg start;
reg abort;

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

// assign the status register
assign status = {5'b00000, postTrigger, preTrigger, idle};

always @(posedge clk) begin
    if (reset == 1'b1) begin
        desiredPattern        <= {SAMPLE_WIDTH{1'b0}};
        activeChannels        <= {SAMPLE_WIDTH{1'b0}};
        dontCareChannels      <= {SAMPLE_WIDTH{1'b0}};
        edgeChannel           <= 32'd0;
        patternTriggerEnable  <= 1'b0;
        edgeTriggerEnable     <= 1'b0;
        edgeType              <= 1'b0;
        currentCommand        <= CMD_NOP;
        maxSampleCount        <= 32'd0;
        preTriggerSampleCountMax <= 32'd0;
    end else begin
        if (command_strobe) begin
            case (command)
                CMD_START: currentCommand    <= CMD_START;
                CMD_ABORT: currentCommand    <= CMD_ABORT;
                CMD_TRIGGER_CONFIGURE: begin
                    currentCommand           <= CMD_TRIGGER_CONFIGURE;
                    desiredPattern           <= {regIn1, regIn0};
                    activeChannels           <= {regIn3, regIn2};
                    dontCareChannels         <= {regIn5, regIn4};
                    edgeChannel              <= regIn6;
                    patternTriggerEnable     <= regIn7[0];
                    edgeTriggerEnable        <= regIn7[1];
                    edgeType                 <= regIn7[2];
                end
                CMD_BUFFER_CONFIGURE: begin
                    currentCommand           <= CMD_BUFFER_CONFIGURE;
                    maxSampleCount           <= {regIn3, regIn2, regIn1, regIn0};
                    preTriggerSampleCountMax    <= {regIn7, regIn6, regIn5, regIn4};
                end
                CMD_READ_TRACE_DATA: begin
                    currentCommand           <= CMD_READ_TRACE_DATA;
                    regOut0                  <= 8'hAA;//data we are uploading....
                    regOut1                  <= 8'hBB;
                    regOut2                  <= 8'hCC;
                    regOut3                  <= 8'hDD;
                    regOut4                  <= 8'hAA;
                    regOut5                  <= 8'hBB;
                    regOut6                  <= 8'hCC;
                    regOut7                  <= 8'hDD;
                end
                default: begin
                    currentCommand           <= CMD_NOP;
                end
            endcase
        end else begin
            currentCommand                   <= CMD_NOP;
        end
    end
end

// Handle setting and clearing start/abort bits
always @(posedge clk) begin
    if (reset) begin
        start <= 1'b0;
        abort <= 1'b0;
    end else begin
        case(currentCommand)
            CMD_START: start <= 1'b1;
            CMD_ABORT: abort <= 1'b1
            default:   begin
                         start <= 1'b0;
                         abort <= 1'b0;
                       end
        endcase
    end
end

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
    .reset(reset),
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
    .start(start),
    .abort(abort),
    .status(status),
    .samplePacket(samplePacket),
    .write_enable(write_enable),
    .sample_number(sample_number)
);
 
endmodule