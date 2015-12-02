`timescale 1ps/100fs

module nexys4fpga (
	input 		       clk,               // 100MHz clock from on-board oscillator
	
	//Nexys4 Peripherals
	input			   btnCpuReset,       // red pushbutton input -> db_btns[0]
    input  wire        btnW, btnE,             // pushbutton inputs - left (db_btns[4])and right (db_btns[2])
    input  wire        btnN, btnS,             // pushbutton inputs - up (db_btns[3]) and down (db_btns[1])
    input  wire        btnC,                   // pushbutton inputs - center button -> db_btns[5]    
    input  wire [15:0] sw,                     // switch inputs    
    output wire [15:0] led,                     // LED outputs   
    input  wire        uart_rxd,
    output wire        uart_txd,    
    input wire  [7:0]  JA,
    input wire  [7:0]  JB,
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
//Parameters
parameter TB_MODE = 0;


//Command & Control --> Hub
wire       interrupt;
wire [7:0] port_id;
wire [7:0] port_out;
wire [7:0] port_in;
wire       write_strobe;
wire       kwrite_strobe;
wire       read_strobe;
wire       interrupt_ack;

// UART
wire [7:0] data_rx;
wire       urx_buffer_full;
wire       urx_buffer_half_full;
wire       urx_buffer_data_present;
wire       urx_buffer_read;

wire [7:0] data_tx;
wire       utx_buffer_full;
wire       utx_buffer_half_full;
wire       utx_buffer_data_present;
wire       utx_buffer_write;

//UART Baud Generator
wire         en_16_x_baud;
wire         uart_baud;
assign       uart_baud = TB_MODE ? 1'b1 : en_16_x_baud;

// Clk input to the memory interface
wire clk_mig;
// Output Clocks and resets from the Memory interface
// **** Use these clocks/resets for all logic **** //
wire soc_clk, soc_resetn, soc_reset;

// LogCap/MemIF interconnect
wire         read_allowed;
wire         write_allowed;
wire         reads_pending;
wire         writes_pending;
wire         write_req;
wire         read_req;
wire         has_return_data;
wire         get_return_data;
wire [127:0] return_data;
wire [26:0]  return_adx;
wire         we;
wire [31:0]  samplePacket;
wire [31:0]  sample_num;
wire [127:0] wr_data;
wire [26:0]  wr_adx;
wire [26:0]  rd_adx;
wire         pageFull;

/*** HUB TO LOGCAP COMMAND INTERFACE ****/
wire [7:0]   command;
wire         commandStrobe;
/*** COMMUNICATION HUB/LOGCAP INTERFACE REGISTERS ****/
wire [7:0]   regIn0;
wire [7:0]   regIn1;
wire [7:0]   regIn2;
wire [7:0]   regIn3;
wire [7:0]   regIn4;
wire [7:0]   regIn5;
wire [7:0]   regIn6;
wire [7:0]   regIn7;
wire [7:0]   regOut0;
wire [7:0]   regOut1;
wire [7:0]   regOut2;
wire [7:0]   regOut3;
wire [7:0]   regOut4;
wire [7:0]   regOut5;
wire [7:0]   regOut6;
wire [7:0]   regOut7;
wire [7:0]   status;

wire [15:0]  fakeSignals;

// Create a high true reset
assign soc_reset = ~soc_resetn;
/*** InternalSignal Generator for Testing **/
SignalGenerator
#(
    .NUM_CHANNELS(16),
    .UPDATE_COUNT_BITS(16)
)
sg
(
    .clk(soc_clk),
    .reset(soc_reset),
    
    .chanSignals(fakeSignals)
);

/*********   C&C PICOBLAZE + ROM ***********/
command_control cc(
    .clk(soc_clk),
    .reset(soc_reset),
    
    .interrupt(interrupt),
    .interrupt_ack(interrupt_ack),
    .port_id(port_id),
    .port_out(port_out),
    .port_in(port_in),
    .write_strobe(write_strobe),
    .kwrite_strobe(kwrite_strobe),
    .read_strobe(read_strobe)
);

/*********   C&C COMMUNICATION HUB ********/

  command_control_hub cchub
  (
      //General
      .clk(soc_clk),
      .reset(soc_reset),
      
      //Nexys4 Peripherals
      //o
      .led(led),
      //i        
      .button({2'b00, btnN, btnE, btnS, btnW, btnC, btnCpuReset}),
      .switch(sw),
      
      //Command & Control
      .interrupt(interrupt),
      .interrupt_ack(interrupt_ack),
      .port_id(port_id),
      .port_out(port_out),
      .port_in(port_in),
      .write_strobe(write_strobe),
      .kwrite_strobe(kwrite_strobe),
      .read_strobe(read_strobe),
      
      //UART Rxd
      //in
      .data_rx(data_rx),
      //in
      .urx_buffer_full(urx_buffer_full),
      .urx_buffer_half_full(urx_buffer_half_full),
      .urx_buffer_data_present(urx_buffer_data_present),
      //out
      .urx_buffer_read(urx_buffer_read),
      
      //UART Txd
      //out
      .data_tx(data_tx),
      //in
      .utx_buffer_full(utx_buffer_full),
      .utx_buffer_half_full(utx_buffer_half_full),
      .utx_buffer_data_present(utx_buffer_data_present),
      //out
      .utx_buffer_write(utx_buffer_write),
      
      
      //LogCap
      //i
      .regIn0(regOut0),//Out from LogCap, Into Hub
      .regIn1(regOut1),
      .regIn2(regOut2),
      .regIn3(regOut3),
      .regIn4(regOut4),
      .regIn5(regOut5),
      .regIn6(regOut6),
      .regIn7(regOut7),
      //o
      .regOut0(regIn0),//Out from Hub, Into LogCap
      .regOut1(regIn1),
      .regOut2(regIn2),
      .regOut3(regIn3),
      .regOut4(regIn4),
      .regOut5(regIn5),
      .regOut6(regIn6),
      .regOut7(regIn7),        
      //o
      .command_strobe(commandStrobe),
      .command(command),        
      //i
      .status(status)                
  );
  
`ifndef TB_MODE
 uart_baud_gen ubg
 (
      .clk(soc_clk),
      .reset(soc_reset),
      .en_16_x_baud(en_16_x_baud)
 );
`endif
  uart_rx6 urx
  (
      //Inputs
      .clk(soc_clk),
      .buffer_reset(soc_reset), 
      .en_16_x_baud(uart_baud),
      .serial_in(uart_rxd),
      .buffer_read(urx_buffer_read),
      
      //Outputs
      .data_out(data_rx),
      .buffer_full(urx_buffer_full),
      .buffer_half_full(urx_buffer_half_full),
      .buffer_data_present(urx_buffer_data_present)
  );
  
  uart_tx6 utx
  (
      //Inputs
      .clk(soc_clk),
      .buffer_reset(soc_reset),
      .en_16_x_baud(uart_baud),
      .data_in(data_tx),
      .buffer_write(utx_buffer_write),        
      
      //Outputs
      .serial_out(uart_txd),
      .buffer_full(utx_buffer_full),
      .buffer_half_full(utx_buffer_half_full),
      .buffer_data_present(utx_buffer_data_present)
  );  
/************ LOGIC CAPTURE PERIPHERAL **********/
LogicCaptureTop ilogcap (
    .clk(soc_clk),
    .reset(soc_reset),
    // Asynchronous sample data input
    //.sampleData_async({JA,JB}),
    .sampleData_async(fakeSignals),
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
    .command_strobe(commandStrobe),
    
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
    .read_allowed(read_allowed)
);

/************* SAMPLE TO MEMORY INTERFACE DATA PACKER ************/
dram_packer data_packer (
    .clk(soc_clk),
    .resetn(soc_resetn),
    .we(we),
    .write_data(samplePacket),
    .sample_num(sample_num),
    .dram_data(wr_data),
    .dram_adx(wr_adx),
    .write_req(write_req),
    .write_allowed(write_allowed),
    .pageFull(pageFull)
);

/******************** MEMORY INTERFACE ******************/
/* Includes DDR2 Controller, Read/Write command buffers,
 * and a read data buffer for return data               */
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
    .ddr2_odt(ddr2_odt)
);

// Input: 100 Mhz External Clock
// Outputs: 200 MHz clock for input to memory interface
//          200 MHz clock for Integrated Logic Analyzer (debug only)
clk_wiz_0 clkgen (
    .clk_in1(clk),
    .clk_mig(clk_mig),
    .clk_ila()
);

endmodule