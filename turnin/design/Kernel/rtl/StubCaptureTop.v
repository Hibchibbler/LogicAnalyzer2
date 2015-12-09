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
    
    reg [31:0]                      statusCounter;
    

    localparam  CMD_NOP                 = 8'h00,
                CMD_START               = 8'h01,
                CMD_ABORT               = 8'h02,
                CMD_TRIGGER_CONFIGURE   = 8'h03,
                CMD_BUFFER_CONFIGURE    = 8'h04,
                CMD_READ_TRACE_DATA     = 8'h05,
                
                COUNTER_TRIGGER_MAX  =  'd50,
                
                STATUS_IDLE             = 3'h1,
                STATUS_PRETRIGGER       = 3'h2,
                STATUS_POSTTRIGGER      = 3'h4,
                STATUS_DATAVALID        = 4'h8;
                
            
            
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            statusCounter = 0;
            status = {5'h0, STATUS_IDLE};
        end else begin
            if (command_strobe) begin
                case (command)
                    CMD_START: begin
                        currentCommand      <= CMD_START;
                        status[3:0]         <= {1'b0, STATUS_PRETRIGGER};
                    end
                    CMD_ABORT: begin
                        currentCommand          <= CMD_ABORT;
                        status[2:0]             <= STATUS_IDLE;
                    end
                    CMD_TRIGGER_CONFIGURE: begin
                        currentCommand          <= CMD_TRIGGER_CONFIGURE;
                        desiredPattern          <= {regIn1, regIn0};
                        activeChannels          <= {regIn3, regIn2};
                        dontCareChannels        <= {regIn5, regIn4};
                        edgeChannel             <= regIn6;
                        patternTriggerEnable    <= regIn7[0];
                        edgeTriggerEnable       <= regIn7[1];
                        edgeType                <= regIn7[2];
                    end
                    CMD_BUFFER_CONFIGURE: begin
                        currentCommand          <= CMD_BUFFER_CONFIGURE;
                        maxSampleCount          <= {regIn1, regIn0};
                        preTriggerSampleCount   <= {regIn3, regIn2};
                    end
                    CMD_READ_TRACE_DATA: begin
                        currentCommand          <= CMD_READ_TRACE_DATA;
                        regOut0                 <= 8'hAA;//data we are uploading....
                        regOut1                 <= 8'hBB;
                        regOut2                 <= 8'hCC;
                        regOut3                 <= 8'hDD;
                        regOut4                 <= 8'hAA;
                        regOut5                 <= 8'hBB;
                        regOut6                 <= 8'hCC;
                        regOut7                 <= 8'hDD;
                        status[3]               <= 1'b1;
                    end
                    default: begin
                        currentCommand          <= CMD_NOP;
                    end
                endcase
            end else begin
                currentCommand                  <= CMD_NOP;
            end
            if (status[2:0] == STATUS_PRETRIGGER) begin
                if (statusCounter >= COUNTER_TRIGGER_MAX) begin
                    status[2:0] <= STATUS_POSTTRIGGER;
                    statusCounter <= 0;
                end 
                else begin
                    statusCounter <= statusCounter + 1;
                end
            end
            else if (status[2:0] == STATUS_POSTTRIGGER) begin
                if (statusCounter >= COUNTER_TRIGGER_MAX) begin
                    status[2:0] <= STATUS_IDLE;
                    statusCounter <= 0;
                end
                else begin
                    statusCounter <= statusCounter + 1;
                end
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