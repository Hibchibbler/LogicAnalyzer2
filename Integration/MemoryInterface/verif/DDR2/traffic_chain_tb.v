`timescale 1ps/100fs

module traffic_chain_tb;
    
    /************************ PARAMETERS  *************************/
    parameter CLOCK_PERIOD_IN  = 10000;  // 10000 ps - 100 MHz base clock.
    parameter RESET_PERIOD     = 20000; //  20000 ps reset delay
    
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
    
    /************************ WIRE/REG Declarations *************************/
    // CLOCKS
    reg  pad_clk; // clock from clocking wizard
    // Generate source clock
    initial pad_clk = 1'b0;
    always pad_clk = #(CLOCK_PERIOD_IN/2.0) ~pad_clk;
    
    // RESETS
    reg  pad_resetn; // Low true reset from system
    // Generate soc reset
    initial begin
        pad_resetn = 1'b0;
        #RESET_PERIOD pad_resetn = 1'b1;
    end
    
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
      wire                               init_calib_complete;
          
    /************************ END WIRE/REG DECLARATIONS *********************/

    parameter MAX_SAMPLE_DATA = 16'h00ff;
    // Generate random sample data
    reg [15:0] sampleData;
    reg [4:0] flipCount;
    always @(posedge pad_clk) begin
        if (~pad_resetn) begin
            flipCount <= 0;
        end else begin
            flipCount <= flipCount + 1;
        end
    end
    always @(posedge pad_clk) begin
        if (~pad_resetn) begin
                sampleData <= 16'd0;
        end else begin
            if (flipCount == 5'b11111) begin
                if (sampleData == MAX_SAMPLE_DATA) begin
                    sampleData <= 16'h0000;
                end else begin
                    sampleData <= sampleData + 16'h0001;
                end
//                sampleData <= $random;
            end else begin
                sampleData <= sampleData;
            end
        end
    end
        
    nexys4fpga top (
        .clk(pad_clk),
        .btnCpuReset(pad_resetn),
        .sampleData_async(sampleData),
        
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
  genvar r,i;
  generate
    for (r = 0; r < CS_WIDTH; r = r + 1) begin: mem_rnk
      if(DQ_WIDTH/16) begin: mem
        for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
          ddr2_model u_comp_ddr2
            (
             .ck      (ddr2_ck_p_sdram[0+(NUM_COMP*r)]),
             .ck_n    (ddr2_ck_n_sdram[0+(NUM_COMP*r)]),
             .cke     (ddr2_cke_sdram[0+(NUM_COMP*r)]),
             .cs_n    (ddr2_cs_n_sdram[0+(NUM_COMP*r)]),
             .ras_n   (ddr2_ras_n_sdram),
             .cas_n   (ddr2_cas_n_sdram),
             .we_n    (ddr2_we_n_sdram),
             .dm_rdqs (ddr2_dm_sdram[(2*(i+1)-1):(2*i)]),
             .ba      (ddr2_ba_sdram),
             .addr    (ddr2_addr_sdram),
             .dq      (ddr2_dq_sdram[16*(i+1)-1:16*(i)]),
             .dqs     (ddr2_dqs_p_sdram[(2*(i+1)-1):(2*i)]),
             .dqs_n   (ddr2_dqs_n_sdram[(2*(i+1)-1):(2*i)]),
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
