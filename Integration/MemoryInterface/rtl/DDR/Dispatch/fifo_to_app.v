/* fifo_to_app.v - This module is responsible for taking
 * queued up read commands from the read/write fifos
 * and dispatching the commands to the memory controller.
 * This module encapsulates the separate read and write
 * conversion modules and handles multiplexing the control
 * signals.
 *
 * Brandon Mousseau bam7@pdx.edu
 */

`timescale 1ps/100fs

module fifo_to_app (
    input clk,
    input resetn,
    
    // From ddr_fifo
    input         has_wr_data,
    input         has_wr_adx,
    output        get_wr_data,
    output        get_wr_adx,
    input [127:0] wr_data_in,
    input [26:0]  wr_adx_in,
    input         has_rd_req,
    output        get_rd_req,
    input [26:0]  rd_adx_in,
    
    // To DDR controller
    output     [63:0] app_wdf_data,
    output reg [26:0] app_addr,
    output reg        app_en,
    output reg        app_wdf_end,
    output reg        app_wdf_wren,
    output reg [2:0]  app_cmd,
    // From DDR controller
    input             app_rdy,
    input             app_wdf_rdy
);

localparam READ_MODE = 1'b1, WRITE_MODE = 1'b0;

// mode selects which dispatch unit is
// able to dispatch commands (either read or write).
// The arbitration here is selfish for it's current state.
// In other words: if the current mode is write mode, and there are
// pending write requests, the mode will stay locked in
// write mode until there are no more write requests, even
// if read requests come. The same behaviour occurs
// for read requests. If mode is currently read mode,
// and there are pending read requests, the mode will stay locked
// in read mode until there are no more read requests.
reg mode;
always @(posedge clk) begin
    if (~resetn) begin
        mode = WRITE_MODE;
    end else begin
        if (mode === WRITE_MODE) begin
            if (has_wr_adx | has_wr_data) begin
                mode <= WRITE_MODE;
            end else if (~(has_wr_adx | has_wr_data) & has_rd_req) begin
                mode <= READ_MODE;
            end else begin
                mode <= WRITE_MODE;
            end
        end else begin // READ MODE
            if (has_rd_req) begin
                mode <= READ_MODE;
            end else if (~has_rd_req & (has_wr_adx | has_wr_data)) begin
                mode <= WRITE_MODE;
            end else begin
                mode <= READ_MODE;
            end
        end
    end
end

wire [26:0] wr_address_out;
wire wr_app_en, wr_app_wdf_end, wr_app_wdf_wren;
wire [2:0]  wr_app_cmd;

wire [26:0] rd_address_out;
wire rd_app_en, rd_app_wdf_end, rd_app_wdf_wren;
wire [2:0] rd_app_cmd;

always @(*) begin
    if (mode == READ_MODE) begin
        app_en       = rd_app_en;
        app_wdf_end  = rd_app_wdf_end;
        app_wdf_wren = rd_app_wdf_wren;
        app_cmd      = rd_app_cmd;
        app_addr     = rd_address_out;
    end else if (mode == WRITE_MODE) begin
        app_en       = wr_app_en;
        app_wdf_end  = wr_app_wdf_end;
        app_wdf_wren = wr_app_wdf_wren;
        app_cmd      = wr_app_cmd;
        app_addr     = wr_address_out;    
    end
end

fifo_to_app_wr  i_f2a_wr (
    .clk(clk),
    .resetn(resetn),
    .mode(mode),
    
    // From ddr_fifo
    .has_wr_data(has_wr_data),
    .has_wr_adx(has_wr_adx),
    .write_data_in(wr_data_in),
    .address_in(wr_adx_in),
    
    // To DDR controller
    .write_data_out(app_wdf_data),
    .address_out(wr_address_out),
    .app_en(wr_app_en),
    .app_wdf_end(wr_app_wdf_end),
    .app_wdf_wren(wr_app_wdf_wren),
    .app_cmd(wr_app_cmd),
    
    // From DDR controller
    .app_rdy(app_rdy),
    .app_wdf_rdy(app_wdf_rdy),
    
    // To ddr_fifo
    .get_wr_data(get_wr_data),
    .get_wr_adx(get_wr_adx)
);

fifo_to_app_rd i_f2a_rd (
    .clk(clk),
    .resetn(resetn),
    .mode(mode),
    
    .read_adx_in(rd_adx_in),
    .has_rd_req(has_rd_req),
    .get_rd_adr(get_rd_req),
    
    // to application
    .address_out(rd_address_out),
    .app_en(rd_app_en),
    .app_wdf_end(rd_app_wdf_end),
    .app_wdf_wren(rd_app_wdf_wren),
    .app_cmd(rd_app_cmd),
    
    // From DDR controller
    .app_rdy(app_rdy)
);

endmodule