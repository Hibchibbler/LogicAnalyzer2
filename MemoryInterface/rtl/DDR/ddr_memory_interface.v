/* ddr_memory_interface - This is a top level memory interface
 * that interfaces with the sampler. This module encapsulates
 * the write command buffers, the read command buffers, the
 * buffer to controller command dispatch, and the ddr2 controller.
 * It provides the ddr2 pin memory interface.
 * 
 * It accepts write commands and forwards them to the ddr controller.
 * It also queues reads and saves return data for a data consumer.
 *
 * Brandon Mousseau bam7@pdx.edu
 */

`timescale 1ps/100fs
module ddr_memory_interface (
    input  sysclk,     // 200 MHz input clock
    input  sysresetn,  // Low true system reset
    
    output soc_clk,    // 100 MHz clock for soc
    output soc_resetn, // Low true reset synchronous to soc_clk
    
    // Command Request Interface
    input [26:0]  wr_adx_in,      // Address for write requests
    input [127:0] wr_data_in,     // Write data for write requests
    input         write_req,      // Write Command Request
    output        write_allowed,  // High if write req is allowed
    output        writes_pending, // High if there are writes to be issued to dram controller
    input  [26:0] rd_adx_in,      // Address for read requests,
    input         read_req,       // Read Command Request
    output        read_allowed,   // High of read req  is allowed
    output        reads_pending,  // High if there are reads still pending
    
    // Return Read Data
    output [127:0] rd_data_return,  // Read data returned from DDR2
    output [26:0]  rd_adx_return,   // Address associated with return data
    output         has_return_data, // Indicates read data from a read is available
    input          get_return_data, // Retrieve stored read data
    
    // DDR2 Pins
    inout   [15:0]      ddr2_dq,
    inout   [1:0]       ddr2_dqs_n,
    inout   [1:0]       ddr2_dqs_p,
    output  [12:0]      ddr2_addr,
    output  [2:0]       ddr2_ba,
    output              ddr2_ras_n,
    output              ddr2_cas_n,
    output              ddr2_we_n,
    output  [0:0]       ddr2_ck_p,
    output  [0:0]       ddr2_ck_n,
    output  [0:0]       ddr2_cke,
    output  [0:0]       ddr2_cs_n,
    output  [1:0]       ddr2_dm,
    output  [0:0]       ddr2_odt,
    
    /**** DEBUG SIGNALS ****/
    output [26:0] app_addr,
    output [2:0]  app_cmd,
    output        app_en,
    output [63:0] app_wdf_data,
    output        app_wdf_end,
    output        app_wdf_wren,
    output [63:0] app_rd_data,
    output        app_rd_data_end,
    output        app_rd_data_valid,
    output        app_rdy,
    output        app_wdf_rdy
);

// req_receiving to dispatch
wire [127:0] disp_wr_data;
wire [26:0]  disp_wr_adx;
wire         disp_has_wr_adx;
wire         disp_get_wr_adx;
wire         disp_has_wr_data;
wire         disp_get_wr_data;
wire [26:0]  disp_rd_adx_out;
wire         disp_has_rd_req;
wire         disp_get_rd_req;

// DDR Application Interface Signals
//wire [26:0] app_addr;
//wire [2:0]  app_cmd;
//wire        app_en;
//wire [63:0] app_wdf_data;
//wire        app_wdf_end;
wire [7:0]  app_wdf_mask;
//wire        app_wdf_wren;
//wire [63:0] app_rd_data;
//wire        app_rd_data_end;
//wire        app_rd_data_valid;
//wire        app_rdy;
//wire        app_wdf_rdy;
wire        app_sr_req;
wire        app_ref_req;
wire        app_zq_req;
wire        app_sr_active;
wire        app_ref_ack;
wire        app_zq_ack;
wire        ui_rst;
wire        init_calib_complete;

// Tie off unused inputs
assign app_sr_req  = 1'b0;
assign app_zq_req  = 1'b0;
assign app_ref_req = 1'b0;
assign app_wdf_mask = 8'h00;
assign soc_resetn = ~ui_rst;


// Queue up read and write commands
// and buffer returned read data
ddr_fifo req_receiving (
    .clk(soc_clk),
    .resetn(soc_resetn),
    
    // To/From from traffic gen
    .wr_adx_in(wr_adx_in),
    .wr_data_in(wr_data_in),
    .write_req(write_req),
    .write_allowed(write_allowed),
    .writes_pending(writes_pending),
    .rd_adx_in(rd_adx_in),
    .read_req(read_req),
    .read_allowed(read_allowed),
    .reads_pending(reads_pending),
    
    // To/from command dispatch
    .wr_data_out(disp_wr_data),
    .wr_adx_out(disp_wr_adx),
    .has_wr_adx(disp_has_wr_adx),
    .get_wr_adx(disp_get_wr_adx),
    .has_wr_data(disp_has_wr_data),
    .get_wr_data(disp_get_wr_data),
    .rd_adx_out(disp_rd_adx_out),
    .has_rd_req(disp_has_rd_req),
    .get_rd_req(disp_get_rd_req),
    
    // Inputs from application
    // for data retrieval
    .app_rd_data(app_rd_data),
    .app_rd_data_valid(app_rd_data_valid),
    
    // To/from read data consumer
    .return_data(rd_data_return),
    .return_adx(rd_adx_return),
    .has_return_data(has_return_data),
    .get_return_data(get_return_data)
);

// dispatch requested read or writes to the
// ddr controller
fifo_to_app req_dispatch (
    .clk(soc_clk),
    .resetn(soc_resetn),
    
    // to/from FIFO
    .has_wr_data(disp_has_wr_data),
    .has_wr_adx(disp_has_wr_adx),
    .get_wr_data(disp_get_wr_data),
    .get_wr_adx(disp_get_wr_adx),
    .wr_data_in(disp_wr_data),
    .wr_adx_in(disp_wr_adx),
    .has_rd_req(disp_has_rd_req),
    .get_rd_req(disp_get_rd_req),
    .rd_adx_in(disp_rd_adx_out),
    
    // To/From DDR controller app
    .app_wdf_data(app_wdf_data),
    .app_addr(app_addr),
    .app_en(app_en),
    .app_wdf_end(app_wdf_end),
    .app_wdf_wren(app_wdf_wren),
    .app_cmd(app_cmd),
    .app_rdy(app_rdy),
    .app_wdf_rdy(app_wdf_rdy)
);

mig_7series_0 memoryController(
    // Inouts
    .ddr2_dq(ddr2_dq),
    .ddr2_dqs_n(ddr2_dqs_n),
    .ddr2_dqs_p(ddr2_dqs_p),
    // Outputs
    .ddr2_addr(ddr2_addr),
    .ddr2_ba(ddr2_ba),
    .ddr2_ras_n(ddr2_ras_n),
    .ddr2_cas_n(ddr2_cas_n),
    .ddr2_we_n(ddr2_we_n),
    .ddr2_ck_p(ddr2_ck_p),
    .ddr2_ck_n(ddr2_ck_n),
    .ddr2_cke(ddr2_cke),
    .ddr2_cs_n(ddr2_cs_n),
    .ddr2_dm(ddr2_dm),
    .ddr2_odt(ddr2_odt),
    // Single-ended system clock
    .sys_clk_i(sysclk),
    // Single-ended iodelayctrl clk (reference clock)
    // user interface signals
    .app_addr(app_addr),
    .app_cmd(app_cmd),
    .app_en(app_en),
    .app_wdf_data(app_wdf_data),
    .app_wdf_end(app_wdf_end),
    .app_wdf_mask(app_wdf_mask),
    .app_wdf_wren(app_wdf_wren),
    .app_rd_data(app_rd_data),
    .app_rd_data_end(app_rd_data_end),
    .app_rd_data_valid(app_rd_data_valid),
    .app_rdy(app_rdy),
    .app_wdf_rdy(app_wdf_rdy),
    .app_sr_req(app_sr_req),
    .app_ref_req(app_ref_req),
    .app_zq_req(app_zq_req),
    .app_sr_active(app_sr_active),
    .app_ref_ack(app_ref_ack),
    .app_zq_ack(app_zq_ack),
    .ui_clk(soc_clk),
    .ui_clk_sync_rst(ui_rst),
    .init_calib_complete(init_calib_complete),
    .sys_rst(sysresetn)
);

endmodule