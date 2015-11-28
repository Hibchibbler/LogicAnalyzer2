module StubCaptureTop #(
    // Parameter describes physical sample width (ie, max).
    // User may select SAMPLE_WIDTH or less active channels
    parameter SAMPLE_WIDTH        = 16,
    // This is the width of the sample packets saved to memory.
    // A packet consists of the sample plus meta-data about the
    // sample
    parameter SAMPLE_PACKET_WIDTH = 32
) (
    input wire                      clk,
    input wire                      reset,
    input wire [SAMPLE_WIDTH-1:0]   sampleData_async,
    
    input wire [7:0]                regIn0,
    input wire [7:0]                regIn1,
    input wire [7:0]                regIn2,
    input wire [7:0]                regIn3,
    input wire [7:0]                regIn4,
    input wire [7:0]                regIn5,
    input wire [7:0]                regIn6,
    input wire [7:0]                regIn7,    
    output reg [7:0]                regOut0,
    output reg [7:0]                regOut1,
    output reg [7:0]                regOut2,
    output reg [7:0]                regOut3,
    output reg [7:0]                regOut4,
    output reg [7:0]                regOut5,
    output reg [7:0]                regOut6,
    output reg [7:0]                regOut7,
    input wire                      command_strobe,
    input wire [7:0]                command,
        
    output reg [7:0]                status

);

    reg [SAMPLE_WIDTH-1:0]          sampleData_sync0;
    reg [SAMPLE_WIDTH-1:0]          sampleData_sync1;
    reg [SAMPLE_WIDTH-1:0]          sampleData;

    reg [7:0]                       currentCommand;
    
    reg [SAMPLE_WIDTH-1:0]          desiredPattern;
    reg [SAMPLE_WIDTH-1:0]          activeChannels;
    reg [SAMPLE_WIDTH-1:0]          dontCareChannels;
    reg [7:0]                       edgeChannel;
    reg                             patternTriggerEnable;
    reg                             edgeTriggerEnable;
    reg                             edgeType;
    
    reg [31:0]                      maxSampleCount;
    reg [31:0]                      preTriggerSampleCount;
    

    localparam  CMD_NOP                 = 8'h00,
                CMD_START               = 8'h01,
                CMD_ABORT               = 8'h02,
                CMD_TRIGGER_CONFIGURE   = 8'h03,
                CMD_BUFFER_CONFIGURE    = 8'h04,
                CMD_READ_TRACE_DATA     = 8'h05;
            
            
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            //
        end else begin
            if (command_strobe) begin
               
                case (command)
                    CMD_START: currentCommand    <= CMD_START;
                    CMD_ABORT: currentCommand    <= CMD_ABORT;
                    CMD_TRIGGER_CONFIGURE: begin
                        currentCommand           <= CMD_TRIGGER_CONFIGURE;
                        desiredPattern           <= {regIn0, regIn1};
                        activeChannels           <= {regIn2, regIn3};
                        dontCareChannels         <= {regIn4, regIn5};
                        edgeChannel              <= regIn6;
                        patternTriggerEnable     <= regIn7[0];
                        edgeTriggerEnable        <= regIn7[1];
                        edgeType                 <= regIn7[2];
                    end
                    CMD_BUFFER_CONFIGURE: begin
                        currentCommand           <= CMD_BUFFER_CONFIGURE;
                        maxSampleCount           <= {regIn0, regIn1};
                        preTriggerSampleCount    <= {regIn2, regIn3};
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

    // Synchronize sample inputs
    always @(posedge clk) begin
            sampleData_sync0 <= sampleData_async;
            sampleData_sync1 <= sampleData_sync0;
            sampleData       <= sampleData_sync1;
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

endmodule