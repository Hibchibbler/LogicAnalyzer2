`timescale 1ps/100fs

// -----------------------------------------------------------------
// Version:  0.0
// Author: Chip Wood
// Date:     
//
// Testbench for CCProg/CCHub for LogicAnalyzer2
// Portland State University Electrical and Computer Engineering
// Course - ECE540
// Final Project
// ----------------------------------------------------------------- 

`define TB_MODE 1
`define RESET 0


// testbench for command and control + hub
module testbench();

/************************ PARAMETERS  *************************/
parameter CLOCK_PERIOD_IN  = 10000;    // 10000 ps - 100 MHz base clock.
parameter RESET_PERIOD     = 20000;    //  20000 ps reset delay
parameter INIT_DELAY       = 80000000; // 80 usec delay before issuing commands

// Some parameters for proper instantiation of DDR FBM
localparam MEMORY_WIDTH    = 16;
localparam DQ_WIDTH        = 16;                      // # of DQ (data)
localparam NUM_COMP        = DQ_WIDTH/MEMORY_WIDTH;
localparam CS_WIDTH        = 1;                       // # of unique CS outputs to memory.
localparam DM_WIDTH        = 2;                       // # of DM (data mask)
localparam DQS_WIDTH       = 2;
parameter  ROW_WIDTH       = 13;                      // # of memory Row Address bits.
parameter  BANK_WIDTH      = 3;                       // # of memory Bank Address bits.
parameter  CKE_WIDTH       = 1;                       // # of CKE outputs to memory.
parameter  CK_WIDTH        = 1;                       // # of CK/CK# outputs to memory.
parameter  ODT_WIDTH       = 1;                       // # of ODT outputs to memory.
parameter  nCS_PER_RANK    = 1;                       // # of unique CS outputs per rank for phy

// wire delay parameters
localparam real TPROP_PCB_DATA     = 0.00; // Delay for data signal during Write operation
localparam real TPROP_PCB_DATA_RD  = 0.00; // Delay for data signal during Read operation
localparam real TPROP_DQS          = 0.00; // Delay for DQS signal during Write Operation
localparam real TPROP_DQS_RD       = 0.00; // Delay for DQS signal during Read Operation
localparam real TPROP_PCB_CTRL     = 0.00; // Delay for Address and Ctrl signals
parameter  ECC                     = "OFF";
localparam ECC_TEST 		   	   = "OFF" ;
localparam ERR_INSERT              = (ECC_TEST == "ON") ? "OFF" : ECC ;
/************************ END PARAMETERS **********************/

reg  clk;                               // onboard oscillator
reg         btnW, btnE, btnN, btnS, btnC,   // buttons of nexys4fpga
            btnCpuReset;
reg  [15:0] sw;                             // switches on nexys4fpga
wire [15:0] led;                            // output leds from nexys4fpga
wire        uart_rxd,                       // UART data RECEIVED from nexys4fpga
            uart_txd;                       // UART data TRANSMITTED to nexys4fpga
reg   [7:0] JA, JB;                         // J connectors of nexys4FPGA


// UART
wire [7:0] data_rx;
wire       urx_buffer_read;
wire       urx_buffer_full;
wire       urx_buffer_half_full;
wire       urx_buffer_data_present;

reg  [7:0] data_tx;
reg        utx_buffer_write;
wire       utx_buffer_full;
wire       utx_buffer_half_full;
wire       utx_buffer_data_present;

// DDR Memory Wires
// memory model - signals into BFM, delayed version of *fpga
wire [DQ_WIDTH-1:0]                ddr2_dq_sdram;
reg  [ROW_WIDTH-1:0]               ddr2_addr_sdram;
reg  [BANK_WIDTH-1:0]              ddr2_ba_sdram;
reg                                ddr2_ras_n_sdram;
reg                                ddr2_cas_n_sdram;
reg                                ddr2_we_n_sdram;
wire [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr2_cs_n_sdram;
wire [ODT_WIDTH-1:0]               ddr2_odt_sdram;
reg  [CKE_WIDTH-1:0]               ddr2_cke_sdram;
wire [DM_WIDTH-1:0]                ddr2_dm_sdram;
wire [DQS_WIDTH-1:0]               ddr2_dqs_p_sdram;
wire [DQS_WIDTH-1:0]               ddr2_dqs_n_sdram;
reg  [CK_WIDTH-1:0]                ddr2_ck_p_sdram;
reg  [CK_WIDTH-1:0]                ddr2_ck_n_sdram;
// fpga pad - signals direct out of controller
wire [DQ_WIDTH-1:0]                ddr2_dq_fpga;
wire [DQS_WIDTH-1:0]               ddr2_dqs_p_fpga;
wire [DQS_WIDTH-1:0]               ddr2_dqs_n_fpga;
wire [ROW_WIDTH-1:0]               ddr2_addr_fpga;
wire [BANK_WIDTH-1:0]              ddr2_ba_fpga;
wire                               ddr2_ras_n_fpga;
wire                               ddr2_cas_n_fpga;
wire                               ddr2_we_n_fpga;
wire [CKE_WIDTH-1:0]               ddr2_cke_fpga;
wire [CK_WIDTH-1:0]                ddr2_ck_p_fpga;
wire [CK_WIDTH-1:0]                ddr2_ck_n_fpga;
wire [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr2_cs_n_fpga;
wire [DM_WIDTH-1:0]                ddr2_dm_fpga;
wire [ODT_WIDTH-1:0]               ddr2_odt_fpga;
reg  [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr2_cs_n_sdram_tmp;
reg  [DM_WIDTH-1:0]                ddr2_dm_sdram_tmp;
reg  [ODT_WIDTH-1:0]               ddr2_odt_sdram_tmp;

integer i;

// Generate source clock
initial clk = 1'b0;
always clk = #(CLOCK_PERIOD_IN/2.0) ~clk;

// RESETS
// Generate soc reset
initial begin
    btnCpuReset = 1'b0;
    #RESET_PERIOD btnCpuReset = 1'b1;
end

initial begin
    {btnW, btnE, btnN, btnS, btnC} = 5'h00;
    sw = 16'h0000;
    data_tx = 8'h00;
    utx_buffer_write = 1'b0;
    JA = 8'h00;
    JB = 8'h00;
end

uart_rx6 uart_rx
(
    //Inputs
    .clk(clk),
    .buffer_reset(~btnCpuReset),
    .en_16_x_baud(1'b1),
    .serial_in(uart_rxd),
    .buffer_read(urx_buffer_read),

    //Outputs
    .data_out(data_rx),
    .buffer_full(urx_buffer_full),
    .buffer_half_full(urx_buffer_half_full),
    .buffer_data_present(urx_buffer_data_present)
);

uart_tx6 uart_tx
(
    //Inputs
    .clk(clk),
    .buffer_reset(~btnCpuReset),
    .en_16_x_baud(1'b1),
    .data_in(data_tx),
    .buffer_write(utx_buffer_write),

    //Outputs
    .serial_out(uart_txd),
    .buffer_full(utx_buffer_full),
    .buffer_half_full(utx_buffer_half_full),
    .buffer_data_present(utx_buffer_data_present)
);

nexys4fpga #(.TB_MODE(1)) target
(
    .clk(clk),
    .btnW(btnW),
    .btnE(btnE),
    .btnN(btnN),
    .btnS(btnS),
    .btnC(btnC),
    .btnCpuReset(btnCpuReset),
    .sw(sw),
    .led(led),
    .uart_rxd(uart_txd),
    .uart_txd(uart_rxd),
    .JA(JA),
    .JB(JB),
    // DDR2 Pins
    .ddr2_dq(ddr2_dq_fpga),
    .ddr2_dqs_n(ddr2_dqs_n_fpga),
    .ddr2_dqs_p(ddr2_dqs_p_fpga),
    .ddr2_addr(ddr2_addr_fpga),
    .ddr2_ba(ddr2_ba_fpga),
    .ddr2_ras_n(ddr2_ras_n_fpga),
    .ddr2_cas_n(ddr2_cas_n_fpga),
    .ddr2_we_n(ddr2_we_n_fpga),
    .ddr2_ck_p(ddr2_ck_p_fpga),
    .ddr2_ck_n(ddr2_ck_n_fpga),
    .ddr2_cke(ddr2_cke_fpga),
    .ddr2_cs_n(ddr2_cs_n_fpga),
    .ddr2_dm(ddr2_dm_fpga),
    .ddr2_odt(ddr2_odt_fpga)
);


// UART READS
// just read them as they come out - data present wire will go high, simply drive the buffer_read signal high to get data onto data_rx
assign urx_buffer_read = urx_buffer_data_present;
// print any uart data coming out of the nexys4fpga
always @(negedge urx_buffer_read) $display("%5d UART data out: %h", $time, data_rx);

initial begin
    #INIT_DELAY
//    #10 cmd_abort;
    cmd_write_trig_cfg({{56{1'b0}},8'h55});
    #(CLOCK_PERIOD_IN*2) cmd_read_trig_cfg;
    // takes a total of ~22uS to get the full "HELLO World" back
    #22000;
end

task cmd_start;
begin
    write_uart({{64{1'b0}}, 8'h01});
end
endtask

task cmd_abort;
begin
    write_uart({{64{1'b0}}, 8'h02});
end
endtask

task cmd_write_trig_cfg;
input [63:0] trig_cfg;
begin
    write_uart({trig_cfg, 8'h03});
end
endtask

task cmd_write_buff_cfg;
input [63:0] buff_cfg;
begin
    write_uart({buff_cfg, 8'h04});
end
endtask

task cmd_read_trace_data;
begin
    write_uart({{64{1'b0}}, 8'h05});
end
endtask

task cmd_read_trace_size;
begin
    write_uart({{64{1'b0}}, 8'h06});
end
endtask

task cmd_read_trig_sample;
begin
    write_uart({{64{1'b0}}, 8'h07});
end
endtask

task cmd_reset_logcap;
begin
    write_uart({{64{1'b0}}, 8'h09});
end
endtask

task cmd_read_buff_cfg;
begin
    write_uart({{64{1'b0}}, 8'h0A});
end
endtask

task cmd_read_trig_cfg;
begin
    write_uart({{64{1'b0}}, 8'h0B});
end
endtask



task write_uart;
input [71:0] data;
integer count;
begin
    // make sure buffer isn't full
    //while (utx_buffer_full) 
    count = 0;
    while (count < 9) begin
        if (utx_buffer_full) begin // wait a cycle
            @(posedge clk);
        end 
        else begin
            @(posedge clk);
                data_tx = data[count*8-+7-:8];
                utx_buffer_write = 1'b1;
            @(posedge clk);
                utx_buffer_write = 1'b0;
                count = count + 1;
        end
    end
end
endtask

 // Intantiate the Bus Functional Model of DDR2 memory + Wire Delay modeling
 /*********************** WIRE DELAY GENERATION ******************************/
  always @( * ) begin
    ddr2_ck_p_sdram   <=  #(TPROP_PCB_CTRL) ddr2_ck_p_fpga;
    ddr2_ck_n_sdram   <=  #(TPROP_PCB_CTRL) ddr2_ck_n_fpga;
    ddr2_addr_sdram   <=  #(TPROP_PCB_CTRL) ddr2_addr_fpga;
    ddr2_ba_sdram     <=  #(TPROP_PCB_CTRL) ddr2_ba_fpga;
    ddr2_ras_n_sdram  <=  #(TPROP_PCB_CTRL) ddr2_ras_n_fpga;
    ddr2_cas_n_sdram  <=  #(TPROP_PCB_CTRL) ddr2_cas_n_fpga;
    ddr2_we_n_sdram   <=  #(TPROP_PCB_CTRL) ddr2_we_n_fpga;
    ddr2_cke_sdram    <=  #(TPROP_PCB_CTRL) ddr2_cke_fpga;
  end
    

  always @( * )
    ddr2_cs_n_sdram_tmp   <=  #(TPROP_PCB_CTRL) ddr2_cs_n_fpga;
  assign ddr2_cs_n_sdram =  ddr2_cs_n_sdram_tmp;
    

  always @( * )
    ddr2_dm_sdram_tmp <=  #(TPROP_PCB_DATA) ddr2_dm_fpga;//DM signal generation
  assign ddr2_dm_sdram = ddr2_dm_sdram_tmp;
    

  always @( * )
    ddr2_odt_sdram_tmp  <=  #(TPROP_PCB_CTRL) ddr2_odt_fpga;
  assign ddr2_odt_sdram =  ddr2_odt_sdram_tmp;
    
 
  genvar dqwd;
  generate
    for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
      WireDelay #
       (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dq
       (
        .A             (ddr2_dq_fpga[dqwd]),
        .B             (ddr2_dq_sdram[dqwd]),
        .reset         (pad_resetn),
        .phy_init_done (init_calib_complete)
       );
    end
    // For ECC ON case error is inserted on LSB bit from DRAM to FPGA
          WireDelay #
       (
        .Delay_g    (TPROP_PCB_DATA),
        .Delay_rd   (TPROP_PCB_DATA_RD),
        .ERR_INSERT (ERR_INSERT)
       )
      u_delay_dq_0
       (
        .A             (ddr2_dq_fpga[0]),
        .B             (ddr2_dq_sdram[0]),
        .reset         (pad_resetn),
        .phy_init_done (init_calib_complete)
       );
  endgenerate

  genvar dqswd;
  generate
    for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
      WireDelay #
       (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dqs_p
       (
        .A             (ddr2_dqs_p_fpga[dqswd]),
        .B             (ddr2_dqs_p_sdram[dqswd]),
        .reset         (pad_resetn),
        .phy_init_done (init_calib_complete)
       );

      WireDelay #
       (
        .Delay_g    (TPROP_DQS),
        .Delay_rd   (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dqs_n
       (
        .A             (ddr2_dqs_n_fpga[dqswd]),
        .B             (ddr2_dqs_n_sdram[dqswd]),
        .reset         (pad_resetn),
        .phy_init_done (init_calib_complete)
       );
    end
  endgenerate
  /******************** END DELAY GENERATION **********************/
  
  // BFM instantiation
  genvar r,q;
  generate
    for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
      if(DQ_WIDTH/16) begin: mem
        for (q = 0; q < NUM_COMP; q = q + 1) begin: gen_mem
          ddr2_model u_comp_ddr2
            (
             .ck      (ddr2_ck_p_sdram[0+(NUM_COMP*r)]),
             .ck_n    (ddr2_ck_n_sdram[0+(NUM_COMP*r)]),
             .cke     (ddr2_cke_sdram[0+(NUM_COMP*r)]),
             .cs_n    (ddr2_cs_n_sdram[0+(NUM_COMP*r)]),
             .ras_n   (ddr2_ras_n_sdram),
             .cas_n   (ddr2_cas_n_sdram),
             .we_n    (ddr2_we_n_sdram),
             .dm_rdqs (ddr2_dm_sdram[(2*(q+1)-1):(2*q)]),
             .ba      (ddr2_ba_sdram),
             .addr    (ddr2_addr_sdram),
             .dq      (ddr2_dq_sdram[16*(q+1)-1:16*(q)]),
             .dqs     (ddr2_dqs_p_sdram[(2*(q+1)-1):(2*q)]),
             .dqs_n   (ddr2_dqs_n_sdram[(2*(q+1)-1):(2*q)]),
             .rdqs_n  (),
             .odt     (ddr2_odt_sdram[0+(NUM_COMP*r)])
             );
        end
      end
      if (DQ_WIDTH%16) begin: gen_mem_extrabits
        ddr2_model u_comp_ddr2
          (
           .ck      (ddr2_ck_p_sdram[0+(NUM_COMP*r)]),
           .ck_n    (ddr2_ck_n_sdram[0+(NUM_COMP*r)]),
           .cke     (ddr2_cke_sdram[0+(NUM_COMP*r)]),
           .cs_n    (ddr2_cs_n_sdram[0+(NUM_COMP*r)]),
           .ras_n   (ddr2_ras_n_sdram),
           .cas_n   (ddr2_cas_n_sdram),
           .we_n    (ddr2_we_n_sdram),
           .dm_rdqs ({ddr2_dm_sdram[DM_WIDTH-1],ddr2_dm_sdram[DM_WIDTH-1]}),
           .ba      (ddr2_ba_sdram),
           .addr    (ddr2_addr_sdram),
           .dq      ({ddr2_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)],
                      ddr2_dq_sdram[DQ_WIDTH-1:(DQ_WIDTH-8)]}),
           .dqs     ({ddr2_dqs_p_sdram[DQS_WIDTH-1],
                      ddr2_dqs_p_sdram[DQS_WIDTH-1]}),
           .dqs_n   ({ddr2_dqs_n_sdram[DQS_WIDTH-1],
                      ddr2_dqs_n_sdram[DQS_WIDTH-1]}),
           .rdqs_n  (),
           .odt     (ddr2_odt_sdram[0+(NUM_COMP*r)])
           );
      end
    end
  endgenerate

endmodule
