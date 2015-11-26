`timescale 1ps/100fs

module nexys4fpga (
	input 				clk,         // 100MHz clock from on-board oscillator
	input				btnCpuReset, // red pushbutton input -> db_btns[0]
	input	[15:0]		sw,          // switch inputs		

    // DDR Interface
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
    output  [0:0]       ddr2_odt
);

/**** DEBUG SIGNALS *****/
wire [26:0] app_addr;
wire [2:0]  app_cmd;
wire        app_en;
wire [63:0] app_wdf_data;
wire        app_wdf_end;
wire        app_wdf_wren;
wire [63:0] app_rd_data;
wire        app_rd_data_end;
wire        app_rd_data_valid;
wire        app_rdy;
wire        app_wdf_rdy;
/************************/

wire traffic_go;

wire clk_mig, clk_ila;
wire soc_clk, soc_resetn;
// traffic gen to req_receiving
wire read_allowed;
wire write_allowed;
wire reads_pending;
wire writes_pending;
wire write_req;
wire read_req;

wire mode;

wire has_return_data;
wire get_return_data;
wire [127:0] return_data;
wire [26:0] return_adx;

wire we;
wire [15:0] sample_data;
wire [31:0] sample_num;

wire [127:0] tr_wr_data;
wire [26:0] tr_adx;
wire [26:0] rd_adx;

assign traffic_go = sw[0];

clk_wiz_0 clkgen (
    .clk_in1(clk),
    .clk_mig(clk_mig),
    .clk_ila(clk_ila)
);

consumer dummy_consumer (
    .clk(soc_clk),
    .resetn(soc_resetn),
    .has_return_data(has_return_data),
    .get_return_data(get_return_data),
    .return_data(return_data),
    .return_adx(return_adx)
);

sampler_stub sampler (
    .clk(soc_clk),
    .resetn(soc_resetn),
    .enable(traffic_go),
    .sample_num(sample_num),
    .sample(sample_data),
    .we(we),
    .read_req(read_req),
    .adx(rd_adx),
    .mode(mode),
    .reads_pending(reads_pending),
    .read_allowed(read_allowed),
    .writes_pending(writes_pending)
);

dram_packer data_packer (
    .clk(soc_clk),
    .resetn(soc_resetn),
    .we(we),
    .write_data(sample_data),
    .sample_num(sample_num),
    .dram_data(tr_wr_data),
    .dram_adx(tr_adx),
    .write_req(write_req),
    .write_allowed(write_allowed)
);

ddr_memory_interface ddr_if(
    .sysclk(clk_mig),               // 200 MHz input clock
    .sysresetn(btnCpuReset),         // Low true system reset
    .soc_clk(soc_clk),              // 100 MHz clock for soc
    .soc_resetn(soc_resetn),        // Low true reset synchronous to soc_clk
    // Command Request Interface
    .wr_adx_in(tr_adx),              // Address for write requests
    .wr_data_in(tr_wr_data),        // Write data for write requests
    .write_req(write_req),          // Write Command Request
    .write_allowed(write_allowed),  // High if write req is allowed
    .writes_pending(writes_pending),// High if there are writes to be issued to dram controller
    .rd_adx_in(rd_adx),             // Address for read requests,
    .read_req(read_req),            // Read Command Request
    .read_allowed(read_allowed),    // High of read req  is allowed
    .reads_pending(reads_pending),  // High if there are reads still pending
    .mode(mode), // Annoying signal - needs to go away
    // Return Read Data
    .rd_data_return(return_data),      // Read data returned from DDR2
    .rd_adx_return(return_adx),        // Address associated with return data
    .has_return_data(has_return_data), // Indicates read data from a read is available
    .get_return_data(get_return_data), // Retrieve stored read data
    // DDR2 Pins
    .ddr2_dq(ddr2_dq),
    .ddr2_dqs_n(ddr2_dqs_n),
    .ddr2_dqs_p(ddr2_dqs_p),
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
    /**** DEBUG SIGNALS ****/
    .app_addr(app_addr),
    .app_cmd(app_cmd),
    .app_en(app_en),
    .app_wdf_data(app_wdf_data),
    .app_wdf_end(app_wdf_end),
    .app_wdf_wren(app_wdf_wren),
    .app_rd_data(app_rd_data),
    .app_rd_data_end(app_rd_data_end),
    .app_rd_data_valid(app_rd_data_valid),
    .app_rdy(app_rdy),
    .app_wdf_rdy(app_wdf_rdy)
);

ila_0 la (
    .clk(clk_ila),
    .probe0(traffic_go),
    .probe1(mode),
    .probe2(we),
    .probe3(reads_pending),
    .probe4(read_req),
    .probe5(writes_pending),
    .probe6(read_allowed),
    .probe7(sample_num),
    .probe8(sample_data),
    .probe9(write_req),
    .probe10(tr_adx),
    .probe11(tr_wr_data),
    .probe12(rd_adx),
    .probe13(return_data),
    .probe14(return_adx),
    .probe15(has_return_data),
    .probe16(get_return_data),
    .probe17(app_addr),
    .probe18(app_cmd[0]),
    .probe19(app_en),
    .probe20(app_wdf_data),
    .probe21(app_wdf_end),
    .probe22(app_wdf_wren),
    .probe23(app_rd_data),
    .probe24(app_rd_data_valid),
    .probe25(app_rdy),
    .probe26(app_wdf_rdy)
);

endmodule