/* dram_packer.v - This module is used to collect samples from the
*                  sampler every clock edge and pull them up into
*                  groups of samples that are the correct size for
*                  the memory width.
*                  For example, the sample size may be 16 bits, but
*                  the memory interface has a data width of 128 bits.
*                  This module will accumulate 8 16 bit samples and
*                  send a 128 bit chunk to the memory interface.
* Interface:
*       Inputs:
*         clk           - system clock
*         resetn        - low true reset
*         we            - write enable from sampler
*         write_data    - sample data
*         sample_num    - a number for the sample - converted to address
*         write_allowed - input from memory interface indicating a write command
*                         currently allowed
*       Outputs:
*         dram_data     - the data output to the memory interface
*         dram_adx      - the address otuput to the memory interface
*         write_req     - the write_req signal to the memory interface.
*  Brandon Mousseau
*  bam7@pdx.edu
*/
module dram_packer #(
    parameter DATA_WIDTH = 16,
    parameter DRAM_WIDTH = 128,
    parameter ADX_WIDTH  = 27
)(
    input clk,
    input resetn,
    
    input we,
    input [DATA_WIDTH-1:0] write_data,
    input [31:0] sample_num,
    
    output reg [DRAM_WIDTH-1:0] dram_data,
    output     [ADX_WIDTH-1:0]  dram_adx,
    output reg write_req,
    input write_allowed
);

localparam PACK_SIZE  = DRAM_WIDTH/DATA_WIDTH;
localparam MAX_PACK   = PACK_SIZE*2;
localparam BUFF_WIDTH = DRAM_WIDTH*2;

// Ensures addresses will always be
// multiples of 8.
// TODO: This needs to be fixed
// if data_width/dram_width are not defaults!!!!!!!
reg [31:0] capturedSampleNum;
localparam SAMPLE_MASK_WIDTH = 3;
assign dram_adx = {capturedSampleNum[31:SAMPLE_MASK_WIDTH], 3'b000};

reg [8:0] flushCount;
reg [8:0] packCount;
reg [BUFF_WIDTH-1:0] dBuff;
reg dramSendFlag;
reg buffSelect;

localparam IDLE = 1'b0, SENDING = 1'b1;
reg go;
reg sendState, sendNextState;

always @(posedge clk) begin
    if (~resetn) begin
        sendState <= IDLE;
    end else begin 
        sendState <= sendNextState;
    end
end

always @(*) begin
    case(sendState)
        IDLE:    begin
                    if (go)
                        sendNextState = SENDING;
                    else
                        sendNextState = IDLE;
                 end
        SENDING: begin
                    if (write_allowed)
                        sendNextState = IDLE;
                    else
                        sendNextState = SENDING;
                 end
    endcase
end

always @(*) begin
    case(sendState)
        IDLE:    begin
                    write_req = 1'b0;
                 end
        SENDING: begin
                    write_req = write_allowed;
                 end
    endcase
end

always @(posedge clk) begin
    if (~resetn) begin
        dBuff        <= 0;
        dramSendFlag <= 0;
        packCount    <= 0;
        flushCount   <= 0;
        buffSelect   <= 0;
        dram_data    <= 0;
        go           <= 1'b0;
        capturedSampleNum <= 32'd0;
    end else begin
        if (we) begin
            dBuff[packCount*DATA_WIDTH+DATA_WIDTH-1 -: DATA_WIDTH] <= write_data;
            packCount  <= packCount + 1'b1;
            flushCount <= flushCount + 1;
            if (flushCount === PACK_SIZE) begin
                if (buffSelect) begin
                    dram_data <= dBuff[BUFF_WIDTH-1 -: DRAM_WIDTH];
                end else begin
                    dram_data <= dBuff[DRAM_WIDTH-1 -: DRAM_WIDTH];
                end
                flushCount   <= 4'b1;
                buffSelect   <= ~buffSelect;
                go           <= 1'b1;
                capturedSampleNum <= sample_num-1;
            end else begin
                go <= 1'b0;
                capturedSampleNum <= capturedSampleNum;
            end
            if (packCount === MAX_PACK-1) begin
                packCount <= 0;
            end
        end else begin
            capturedSampleNum <= capturedSampleNum;
            go <= 1'b0;
        end
    end
end

endmodule