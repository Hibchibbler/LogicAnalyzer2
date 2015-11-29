`timescale 1ps/100fs

module nexys4fpga (
	input 				clk,         // 100MHz clock from on-board oscillator
	input				btnCpuReset, // red pushbutton input -> db_btns[0]
    input   [15:0]      sampleData_async,
    
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

wire clk_mig;
wire soc_clk, soc_resetn, soc_reset;
// traffic gen to req_receiving
wire read_allowed;
wire write_allowed;
wire reads_pending;
wire writes_pending;
wire write_req;
wire read_req;

wire has_return_data;
wire get_return_data;
wire [127:0] return_data;
wire [26:0]  return_adx;

wire we;
reg  [15:0] sampleData;
reg  [15:0] sampleData_sync0;
reg  [15:0] sampleData_sync1;
wire [31:0] samplePacket;
wire [31:0] sample_num;

wire [127:0] wr_data;
wire [26:0]  wr_adx;
wire [26:0]  rd_adx;


wire pageFull;
assign soc_reset = ~soc_resetn;

wire [7:0] command;
wire commandStrobe;

// Registers into the LogicCaptureTop
wire [7:0]         regIn0;
wire [7:0]         regIn1;
wire [7:0]         regIn2;
wire [7:0]         regIn3;
wire [7:0]         regIn4;
wire [7:0]         regIn5;
wire [7:0]         regIn6;
wire [7:0]         regIn7;
// Registers out of the LogicCaptureTop
wire [7:0]          regOut0;
wire [7:0]          regOut1;
wire [7:0]          regOut2;
wire [7:0]          regOut3;
wire [7:0]          regOut4;
wire [7:0]          regOut5;
wire [7:0]          regOut6;
wire [7:0]          regOut7;
wire [7:0]          status;

hubStub hubstub (
    .clk(soc_clk),
    .resetn(soc_resetn),
    
    .command(command),
    .commandStrobe(commandStrobe),
    
    // Registers into the LogicCaptureTop
    .regIn0(regIn0),
    .regIn1(regIn1),
    .regIn2(regIn2),
    .regIn3(regIn3),
    .regIn4(regIn4),
    .regIn5(regIn5),
    .regIn6(regIn6),
    .regIn7(regIn7),
    // Registers out of the LogicCaptureTop
    .regOut0(regOut0),
    .regOut1(regOut1),
    .regOut2(regOut2),
    .regOut3(regOut3),
    .regOut4(regOut4),
    .regOut5(regOut5),
    .regOut6(regOut6),
    .regOut7(regOut7),
    .status(status)
);

LogicCaptureTop ilogcap (
    .clk(soc_clk),
    .reset(soc_reset),
    // Asynchronous sample data input
    .sampleData_async(sampleData_async),
    // Communication interface to HUB
    // 8 Input Registers
    .regIn0(regIn0),
    .regIn1(regIn1),
    .regIn2(regIn2),
    .regIn3(regIn3),
    .regIn4(regIn4),
    .regIn5(regIn5),
    .regIn6(regIn6),
    .regIn7(regIn7),
    // 8 Output Registers
    .regOut0(regOut0),
    .regOut1(regOut1),
    .regOut2(regOut2),
    .regOut3(regOut3),
    .regOut4(regOut4),
    .regOut5(regOut5),
    .regOut6(regOut6),
    .regOut7(regOut7),
    
    // Command input from HUB
    .command(command),
    .command_strobe(command_strobe),
    
    // status register
    .status(status),
    
    // Interface to memory
    .samplePacket(samplePacket),
    .write_enable(we),
    .sample_number(sample_num),
    .pageFull(pageFull),
    
    // Data readback
    .has_return_data(has_return_data),
    .return_data(return_data),
    .get_return_data(get_return_data),
    .read_sample_address(rd_adx),
    .read_req(read_req),
    // TODO: make sure this gets real read_allowed when doing end to end sim
    .read_allowed(1'b1)
);

dram_packer data_packer (
    .clk(soc_clk),
    .resetn(soc_resetn),
    .we(we),
    .write_data(samplePacket),
    .sample_num(sample_num),
    .dram_data(wr_data),
    .dram_adx(wr_adx),
    .write_req(write_req),
    // TODO: make sure this gets real write_allowed when doing end to end sim
    .write_allowed(1'b1),
    .pageFull(pageFull)
);

ddr_memory_interface ddr_if(
    .sysclk(clk_mig),               // 200 MHz input clock
    .sysresetn(btnCpuReset),         // Low true system reset
    .soc_clk(soc_clk),              // 100 MHz clock for soc
    .soc_resetn(soc_resetn),        // Low true reset synchronous to soc_clk
    // Command Request Interface
    .wr_adx_in(wr_adx),              // Address for write requests
    .wr_data_in(wr_data),        // Write data for write requests
    .write_req(write_req),          // Write Command Request
    .write_allowed(write_allowed),  // High if write req is allowed
    .writes_pending(writes_pending),// High if there are writes to be issued to dram controller
    .rd_adx_in(rd_adx),             // Address for read requests,
    .read_req(read_req),            // Read Command Request
    .read_allowed(read_allowed),    // High of read req  is allowed
    .reads_pending(reads_pending),  // High if there are reads still pending
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

clk_wiz_0 clkgen (
    .clk_in1(clk),
    .clk_mig(clk_mig),
    .clk_ila(clk_ila)
);

endmodule