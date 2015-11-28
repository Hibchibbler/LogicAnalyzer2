`timescale 1ps/100fs

module nexys4fpga (
	input 				clk,         // 100MHz clock from on-board oscillator
	input				btnCpuReset, // red pushbutton input -> db_btns[0]
	input	[15:0]		sw,          // switch inputs
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
wire soc_clk, soc_resetn;
// traffic gen to req_receiving
wire read_allowed;
wire write_allowed;
wire reads_pending;
wire writes_pending;
wire write_req;
wire read_req;
assign read_req = 1'b0;

wire mode;
assign mode = 1'b0;

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

wire [127:0] tr_wr_data;
wire [26:0]  tr_adx;
wire [26:0]  rd_adx;

wire [7:0] status;
wire pageFull;

wire [15:0] activeChannels;
wire [7:0]  edgeChannel;
wire        edgeType;
wire        edgeTriggerEnable;
wire        patternTriggerEnable;
wire [15:0] desiredPattern;
wire [15:0] dontCareChannels;

assign activeChannels       = 16'hffff;
assign edgeChannel          = 3;
assign edgeType             = 1;
assign edgeTriggerEnable    = 1;
assign patternTriggerEnable = 0;
assign dontCareChannels     = 16'hffff;
assign desiredPattern       = 16'h0000;

wire [31:0] preTriggerSampleCount;
wire [31:0] maxSampleCount;

assign maxSampleCount = 100;
assign preTriggerSampleCount = 30;

reg   abort;
initial begin
    abort = 1'b0;
    #5000000 abort = 1'b1;
end

assign start = sw[0];
assign rd_adx = 27'd0;

// Synchronize sample inputs to this clock domain
always @(posedge soc_clk) begin
    sampleData_sync0 <= sampleData_async;
    sampleData_sync1 <= sampleData_sync0;
    sampleData       <= sampleData_sync1;
end

wire idle, preTrigger, postTrigger;

LogCap ilogcap (
    .clk(soc_clk),
    .reset(~soc_resetn),
    .sampleData(sampleData),
    .maxSampleCount(maxSampleCount),
    .preTriggerSampleCountMax(preTriggerSampleCount),
    .desiredPattern(desiredPattern),
    .activeChannels(activeChannels),
    .dontCareChannels(dontCareChannels),
    .edgeChannel(edgeChannel),
    .patternTriggerEnable(patternTriggerEnable),
    .edgeTriggerEnable(edgeTriggerEnable),
    .edgeType(edgeType),
    .start(start),
    .abort(abort),
    .idle(idle),
    .preTrigger(preTrigger),
    .postTrigger(postTrigger),
    .samplePacket(samplePacket),
    .write_enable(we),
    .sample_number(sample_num),
    .pageFull(pageFull)
);

dram_packer data_packer (
    .clk(soc_clk),
    .resetn(soc_resetn),
    .we(we),
    .write_data(samplePacket),
    .sample_num(sample_num),
    .dram_data(tr_wr_data),
    .dram_adx(tr_adx),
    .write_req(write_req),
    .write_allowed(1'b1),
    .pageFull(pageFull)
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

consumer dummy_consumer (
    .clk(soc_clk),
    .resetn(soc_resetn),
    .has_return_data(has_return_data),
    .get_return_data(get_return_data),
    .return_data(return_data),
    .return_adx(return_adx)
);

clk_wiz_0 clkgen (
    .clk_in1(clk),
    .clk_mig(clk_mig),
    .clk_ila(clk_ila)
);

endmodule