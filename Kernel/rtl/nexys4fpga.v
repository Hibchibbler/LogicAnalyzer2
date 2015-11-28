`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2015 09:08:01 PM
// Design Name: 
// Module Name: nexys4fpga
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module nexys4fpga (
	input  wire        clk,                 
    input  wire        btnW, btnE,             // pushbutton inputs - left (db_btns[4])and right (db_btns[2])
    input  wire        btnN, btnS,             // pushbutton inputs - up (db_btns[3]) and down (db_btns[1])
    input  wire        btnC,                   // pushbutton inputs - center button -> db_btns[5]
    input  wire        btnCpuReset,            // red pushbutton input -> db_btns[0]
    input  wire [15:0] sw,                     // switch inputs    
    output wire [15:0] led,                     // LED outputs   
    input  wire        uart_rxd,
    output wire        uart_txd,
    
    input wire  [7:0]  JA,
    input wire  [7:0]  JB
);
    
    //General System
    wire        sysreset;
    
    assign sysreset = ~btnCpuReset;
    
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
    wire [7:0] data_out;
    wire       urx_buffer_full;
    wire       urx_buffer_half_full;
    wire       urx_buffer_data_present;
    wire       urx_buffer_read;
    
    wire [7:0] data_in;
    wire       utx_buffer_full;
    wire       utx_buffer_half_full;
    wire       utx_buffer_data_present;
    wire       utx_buffer_write;
    
    //UART Baud Generator
    wire       en_16_x_baud;
    
        //LogCap
    wire [7:0] regIn0;
    wire [7:0] regIn1;
    wire [7:0] regIn2;
    wire [7:0] regIn3;
    wire [7:0] regIn4;
    wire [7:0] regIn5;
    wire [7:0] regIn6;
    wire [7:0] regIn7;    
    wire [7:0] regOut0;
    wire [7:0] regOut1;
    wire [7:0] regOut2;
    wire [7:0] regOut3;
    wire [7:0] regOut4;
    wire [7:0] regOut5;
    wire [7:0] regOut6;
    wire [7:0] regOut7;    
    wire       command_strobe;
    wire [7:0] command;
    wire [7:0] status;
    
    command_control cc
    (
        .clk(clk),
        .reset(sysreset),
        
        .interrupt(interrupt),
        .interrupt_ack(interrupt_ack),
        .port_id(port_id),
        .port_out(port_out),
        .port_in(port_in),
        .write_strobe(write_strobe),
        .kwrite_strobe(kwrite_strobe),
        .read_strobe(read_strobe)
    );
    
    command_control_hub cchub
    (
        //General
        .clk(clk),
        .reset(sysreset),
        
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
        .data_out(data_out),
        //in
        .urx_buffer_full(urx_buffer_full),
        .urx_buffer_half_full(urx_buffer_half_full),
        .urx_buffer_data_present(urx_buffer_data_present),
        //out
        .urx_buffer_read(urx_buffer_read),
        
        //UART Txd
        //out
        .data_in(data_in),
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
        .command_strobe(command_strobe),
        .command(command),        
        //i
        .status(status)                
    );
    
`ifndef TB_MODE
   uart_baud_gen ubg
   (
        .clk(clk),
        .reset(sysreset),
        .en_16_x_baud(en_16_x_baud)
   );
`endif
    uart_rx6 urx
    (
        //Inputs
        .clk(clk),
        .buffer_reset(sysreset),       
`ifdef TB_MODE
        .en_16_x_baud(1'b1),
`else
        .en_16_x_baud(en_16_x_baud),
`endif
        .serial_in(uart_rxd),
        .buffer_read(urx_buffer_read),
        
        //Outputs
        .data_out(data_out),
        .buffer_full(urx_buffer_full),
        .buffer_half_full(urx_buffer_half_full),
        .buffer_data_present(urx_buffer_data_present)
    );
    
    uart_tx6 utx
    (
        //Inputs
        .clk(clk),
        .buffer_reset(sysreset),
`ifdef TB_MODE
        .en_16_x_baud(1'b1),
`else
        .en_16_x_baud(en_16_x_baud),
`endif
        .data_in(data_in),
        .buffer_write(utx_buffer_write),        
        
        //Outputs
        .serial_out(uart_txd),
        .buffer_full(utx_buffer_full),
        .buffer_half_full(utx_buffer_half_full),
        .buffer_data_present(utx_buffer_data_present)
    );    
    
    StubCaptureTop
    #(
        .SAMPLE_WIDTH(16),
        .SAMPLE_PACKET_WIDTH(32)
    )
    sct
    (
        //i
        .clk(clk),
        .reset(sysreset),
        .sampleData_async({JA, JB}),
        
        //i
        .regIn0(regIn0),
        .regIn1(regIn1),
        .regIn2(regIn2),
        .regIn3(regIn3),
        .regIn4(regIn4),
        .regIn5(regIn5),
        .regIn6(regIn6),
        .regIn7(regIn7),
        //o
        .regOut0(regOut0),
        .regOut1(regOut1),
        .regOut2(regOut2),
        .regOut3(regOut3),
        .regOut4(regOut4),
        .regOut5(regOut5),
        .regOut6(regOut6),
        .regOut7(regOut7),
        //i  
        .command_strobe(command_strobe),
        .command(command),
        //o
        .status(status)              
    );
            
    
endmodule
