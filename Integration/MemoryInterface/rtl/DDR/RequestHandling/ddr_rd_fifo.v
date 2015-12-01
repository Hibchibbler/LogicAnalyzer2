/* ddr_rd_fifo.v - 
 * This module accepts read commands and makes them
 * available to dispatch. The module also monitors
 * for incoming data from the memory controller and
 * captures the results in a buffer. It signals
 * to a consumer that the data is available.
 * The read_allowed signal will be de-asserted
 * if the number of read commands issued reaches
 * the capacity for the data buffer until a consumer
 * reads the return data. The read_req signal will be
 * ignored if read_allowed is not true.
 *
 * Brandon Mousseau bam7@pdx.edu
 */

`timescale 1ps/100fs
module ddr_rd_fifo (
    input clk,
    input resetn,
    
    // requests from traffic generation
    input  [26:0] read_address,
    input  read_req,
    // control to traffic generation
    output reg read_allowed,
    output reg reads_pending,
    
    // Outputs to fifo_to_app module
    output [26:0] f2a_app_adx,
    output        f2a_has_rd_req,
    input         f2a_get_rd_adr,
    
    // data valid signal from app
    input app_rd_data_valid,
    input [63:0] app_rd_data,
    
    // returned read data - connections
    // go to consumer of read data
    output [127:0] return_data,
    output [26:0]  return_adx,
    output return_data_available,
    input get_return_data
);

// FIFOs need to be the same depth and this needs
// to be equal to that depth. This maximum is to
// ensure the number of read requests sent out does
// not cause an overflow condition with the FIFO buffers
localparam MAX_READ_REQ = 64;

localparam IDLE = 2'b00, CHUNK1 = 2'b01, CHUNK2 = 2'b10;
reg [1:0] state, nextState;

reg [63:0] chunk1;
reg [63:0] chunk2;

reg [63:0] rd_data_capture;
reg rd_data_fifo_wren;
reg adx_pending_rden;

wire get_return_data_legal;
assign get_return_data_legal = get_return_data & return_data_available;

wire return_data_empty;
wire adx_stack_empty;
wire [5:0] pending_adx_count;
wire [5:0] rd_data_count;
wire [26:0] pending_adx_out;
reg  [31:0] cmd_count;

wire read_req_legal;
assign read_req_legal = read_req & read_allowed;

// Create high true reset
wire reset;
assign reset = ~resetn;

// flag to control flow of incoming
// read requests
always @(*) begin
    cmd_count = (pending_adx_count + rd_data_count + rd_data_fifo_wren);
    read_allowed  = cmd_count < MAX_READ_REQ;
    reads_pending = pending_adx_count > 32'd0;
end

always @(posedge clk) begin
    if (~resetn) begin
        state <= IDLE;
    end else begin
        state <= nextState;
    end
end

always @(*) begin
    nextState = IDLE;
    case(state)
        IDLE:   begin
                    if ((pending_adx_count != 5'd0) & app_rd_data_valid) begin
                        nextState = CHUNK1;
                    end else begin
                        nextState = IDLE;
                    end
                end
        CHUNK1: begin
                    if (app_rd_data_valid) begin
                        nextState = CHUNK2;
                    end else begin
                        nextState = CHUNK1;
                    end
                end
        CHUNK2: begin
                    if ((pending_adx_count != 5'd0) & app_rd_data_valid) begin
                        nextState = CHUNK1;
                    end else begin
                        nextState = IDLE;
                    end
                end
    endcase
end

always @(*) begin
    adx_pending_rden  = 1'b0;
    rd_data_fifo_wren = 1'b0;
    case(state)
        IDLE:   begin
                end
        CHUNK1: begin
                    if (nextState == CHUNK2) begin
                        adx_pending_rden = 1'b1;
                    end else begin
                        adx_pending_rden = 1'b0;
                    end
                end
        CHUNK2: begin
                    rd_data_fifo_wren = 1'b1;
                end
    endcase
end

always @(posedge clk) begin
    if (~resetn) begin
        chunk1 <= 64'd0;
        chunk2 <= 64'd0;
    end else begin
        if (nextState == CHUNK1) begin
            chunk1 <= app_rd_data;
        end else begin
            chunk1 <= chunk1;
        end
        if (nextState == CHUNK2) begin
            chunk2 <= app_rd_data;
        end else begin
            chunk2 <= chunk2;
        end
    end
end

// Signal to indicate to the fifo_to_app
// module when there is a read address it should send
assign f2a_has_rd_req = ~adx_stack_empty;

// indicate to consumer that return data and address
// are available to get
assign return_data_available = ~return_data_empty;


// This fifo keeps address that will
// be pulled off and sent to the fifo_to_app
// module in order to be sent to the ddr controller
fifo_rd_adx_stack iadx_queue (
    .clk(clk),
    .srst(reset),
    .rd_en(f2a_get_rd_adr),
    .wr_en(read_req_legal),
    .din(read_address),
    .dout(f2a_app_adx),
    .empty(adx_stack_empty)
);

// This fifo holds onto a copy of all addresses
// that have been requested. when data comes back,
// the front of the queue is combined/associated with the
// returned data
fifo_rd_adx_stack  ipending_adx (
    .clk(clk),
    .srst(reset),
    .data_count(pending_adx_count),
    .rd_en(adx_pending_rden),
    .wr_en(read_req_legal),
    .din(read_address),
    .dout(pending_adx_out)
);

// This fifo is the buffer saving return data/adx
// for the consumer
rd_data_fifo ird_data_fifo (
    .clk(clk),
    .srst(reset),
    .data_count(rd_data_count),
    .rd_en(get_return_data_legal),
    .wr_en(rd_data_fifo_wren),
    .din({pending_adx_out, chunk2, chunk1}),
    .dout({return_adx, return_data}),
    .empty(return_data_empty)
);

endmodule