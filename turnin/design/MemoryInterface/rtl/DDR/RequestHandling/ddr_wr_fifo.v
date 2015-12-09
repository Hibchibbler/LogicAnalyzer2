/* ddr_wr_fifo.v - This module accepts write
 * commands and makes them available to the
 * dispatcher.
 * write_allowed will be de-asserted if the write
 * command buffer is full. The write_req should
 * input will be ignored unless write_allowed is
 * true.
 *
 * Brandon Mousseau bam7@pdx.edu
 */

`timescale 1ps/100fs
module ddr_wr_fifo (
    input          clk,
    input          resetn,
    
    // to/from traffic generator
    input [127:0]  wr_data_in,
    input [26:0]   wr_adx_in,
    input          write_req,
    output reg     write_allowed,
    output reg     writes_pending,
    
    // to/from command dispatch
    input          get_wr_adx,
    input          get_wr_data,
    output [127:0] wr_data_out,
    output [26:0]  wr_adx_out,
    output reg     has_wr_adx,
    output reg     has_wr_data
);

wire reset;
assign reset = ~resetn;

wire data_full, data_almost_full, data_empty;
wire adx_full, adx_almost_full, adx_empty;

wire write_req_legal;
assign write_req_legal = write_req & write_allowed;

always @(*) begin
    write_allowed = ~(data_full | data_almost_full | adx_full | adx_almost_full);
    has_wr_adx    = ~adx_empty;
    has_wr_data   = ~data_empty;
end

reg wrPendingDly;
always @(posedge clk) begin
    if (~resetn) begin
        wrPendingDly <= 1'b0;
        writes_pending <= 1'b0;
    end else begin
        wrPendingDly <= (has_wr_adx | has_wr_data);
        writes_pending <= wrPendingDly;
    end
end

dram_write_fifo wr_data_fifo (
    .clk(clk),
    .srst(reset),
    .din(wr_data_in),
    .wr_en(write_req_legal),
    .rd_en(get_wr_data),
    .dout(wr_data_out),
    .full(data_full),
    .almost_full(data_almost_full),
    .empty(data_empty)
);

dram_write_adx_fifo wr_adx_fifo (
    .clk(clk),
    .srst(reset),
    .din(wr_adx_in),
    .wr_en(write_req_legal),
    .rd_en(get_wr_adx),
    .dout(wr_adx_out),
    .full(adx_full),
    .almost_full(adx_almost_full),
    .empty(adx_empty)
);

endmodule