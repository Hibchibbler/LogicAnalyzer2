/* dram_packer.v - This module is used to collect samples from the
 *                 sampler potentially every clock edge and pull them 
 *                 up into groups of samples that are the correct size
 *                 for the memory width.
 *                 The sample size is32 bits, but
 *                 the memory interface has a data width of 128 bits.
 *                 This module will accumulate 4 32 bit samples and
 *                 send a 128 bit chunk to the memory interface.
 *                 It will also supply the proper address to memory
 *                 by converting the provided sample number.
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
 *
 *  Brandon Mousseau
 *  bam7@pdx.edu
 */
module dram_packer #(
    parameter SAMPLE_PACKET_WIDTH = 32,
    parameter MEM_IF_WIDTH        = 128,
    parameter ADX_WIDTH           = 27,
    parameter MEMORY_WORD_WIDTH   = 2
)(
    input clk,
    input resetn,
    
    // Connectivity to LogCap
    input                           we,
    input [SAMPLE_PACKET_WIDTH-1:0] write_data,
    input [31:0]                    sample_num,
    output reg                      pageFull,
    
    // Connectivity to memory interface
    output reg [MEM_IF_WIDTH-1:0]   dram_data,
    output     [ADX_WIDTH-1:0]      dram_adx,
    output reg                      write_req,
    input                           write_allowed
);

localparam IDLE = 1'b0, SENDING = 1'b1;
reg sendState, sendNextState;

localparam W0 = 2'b00, W1 = 2'b01, W2 = 2'b10,  W3 = 2'b11;
reg [1:0] state, nextState;

reg [SAMPLE_PACKET_WIDTH-1:0] w0,w1,w2;

reg go;

// Ensures address be will always be multiples of 8.
reg [31:0] capturedSampleNum;
sampleToAdx #(
    .SAMPLE_PACKET_WIDTH(SAMPLE_PACKET_WIDTH),
    .ADX_WIDTH(ADX_WIDTH),
    .MEMORY_WORD_WIDTH(MEMORY_WORD_WIDTH)
) adxConversion(
    .sample_num(capturedSampleNum),
    .adx(dram_adx)
);


// This state machine handles accumuluating the
// sample data
always @(posedge clk) begin
    if (~resetn) begin
        state <= W0;
    end else begin
        state <= nextState;
    end
end

always @(posedge clk) begin
    if (~resetn) begin
        w0 <= {SAMPLE_PACKET_WIDTH{1'b0}};
        w1 <= {SAMPLE_PACKET_WIDTH{1'b0}};
        w2 <= {SAMPLE_PACKET_WIDTH{1'b0}};
        capturedSampleNum <= 32'd0;
    end else begin
        if (we) begin
            case(state)
                W0: begin
                        w0 <= write_data;
                        w1 <= w1;
                        w2 <= w2;
                        capturedSampleNum <= capturedSampleNum;
                    end
                W1: begin
                        w0 <= w0;
                        w1 <= write_data;
                        w2 <= w2;
                        capturedSampleNum <= capturedSampleNum;
                    end
                W2: begin
                        w0 <= w0;
                        w1 <= w1;
                        w2 <= write_data;
                        capturedSampleNum <= capturedSampleNum;
                    end
                W3: begin
                        w0 <= w0;
                        w1 <= w1;
                        w2 <= w2;
                        capturedSampleNum <= sample_num;
                    end
            endcase
        end else begin
            w0 <= w0;
            w1 <= w1;
            w2 <= w2;
            capturedSampleNum <= capturedSampleNum;
        end
    end
end

always @(posedge clk) begin
    if (~resetn) begin
        dram_data <= {MEM_IF_WIDTH{1'b0}};
    end else begin
        if (state == W3) begin
            if (we) begin
                dram_data <= {write_data,w2,w1,w0};
            end else begin
                dram_data <= dram_data;
            end
        end else begin
            dram_data <= dram_data;
        end
    end
end

always @(*) begin
    pageFull = 1'b0;
    case(state)
        W0: begin
                if (we)
                    nextState = W1;
                 else
                    nextState = W0;
            end
        W1: begin
                if (we)
                    nextState = W2;
                 else
                    nextState = W1;
            end
        W2: begin
                if (we)
                    nextState = W3;
                 else
                    nextState = W2;
            end
        W3: begin
                if (we) begin
                    pageFull  = 1'b1;
                    nextState = W0;
                 end else
                    nextState = W3;
            end
    endcase
end

always @(*) begin
    go = 1'b0;
    case(state)
        W0: begin
            end
        W1: begin
            end
        W2: begin
            end
        W3: begin
                go = we;
            end
    endcase
end

// This state machine handles sending the accumulated data
// to the memory interface
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


endmodule