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


module nexys4fpga
(
	input  wire        clk,                 
    input  wire        btnW, btnE,             // pushbutton inputs - left (db_btns[4])and right (db_btns[2])
    input  wire        btnN, btnS,             // pushbutton inputs - up (db_btns[3]) and down (db_btns[1])
    input  wire        btnC,                   // pushbutton inputs - center button -> db_btns[5]
    input  wire        btnCpuReset,            // red pushbutton input -> db_btns[0]
    input  wire [15:0] sw,                     // switch inputs    
    output wire [15:0] led,                     // LED outputs   
    input  wire        uart_rxd,
    output wire        uart_txd
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
        .utx_buffer_write(utx_buffer_write)
    );
    
    
   uart_baud_gen ubg
   (
        .clk(clk),
        .reset(sysreset),
        .en_16_x_baud(en_16_x_baud)
   );
            
    uart_rx6 urx
    (
        //Inputs
        .clk(clk),
        .buffer_reset(sysreset),        
        .en_16_x_baud(en_16_x_baud),
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
        .en_16_x_baud(en_16_x_baud),        
        .data_in(data_in),
        .buffer_write(utx_buffer_write),        
        
        //Outputs
        .serial_out(uart_txd),
        .buffer_full(utx_buffer_full),
        .buffer_half_full(utx_buffer_half_full),
        .buffer_data_present(utx_buffer_data_present)
    );    
            
    
endmodule
