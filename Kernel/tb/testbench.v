`timescale 1ns / 100ps

`define TB_MODE 1

// testbench for command and control + hub
module testbench();

reg         clk;                            // clock of nexys4fpga
reg         btnW, btnE, btnN, btnS, btnC,   // buttons of nexys4fpga
            btnCpuReset;
reg  [15:0] sw;                             // switches on nexys4fpga
wire [15:0] led;                            // output leds from nexys4fpga
wire        uart_rxd,                       // UART input to nexys4fpga
            uart_txd;                       // UART output of nexys4fpga
reg   [7:0] JA, JB;                         // J connectors of nexys4FPGA


// UART
reg        urx_buffer_read;
wire [7:0] data_out;
wire       urx_buffer_full;
wire       urx_buffer_half_full;
wire       urx_buffer_data_present;

reg  [7:0] data_in;
reg        utx_buffer_write;
wire       utx_buffer_full;
wire       utx_buffer_half_full;
wire       utx_buffer_data_present;

initial begin
    clk = 1'b0;
    {btnW, btnE, btnN, btnS, btnC} = 5'h00;
    sw = 16'h0000;
    data_in = 8'h00;
    utx_buffer_write = 1'b0;
    urx_buffer_read = 1'b0;
    JA = 8'h00;
    JB = 8'h00;
end

// 100MHz clock
always #5 clk = ~clk;

uart_rx6 uart_rx
(
    //Inputs
    .clk(clk),
    .buffer_reset(btnCpuReset),
    .en_16_x_baud(1'b1),
    .serial_in(uart_rxd),
    .buffer_read(urx_buffer_read),

    //Outputs
    .data_out(data_out),
    .buffer_full(urx_buffer_full),
    .buffer_half_full(urx_buffer_half_full),
    .buffer_data_present(urx_buffer_data_present)
);

uart_tx6 uart_tx
(
    //Inputs
    .clk(clk),
    .buffer_reset(btnCpuReset),
    .en_16_x_baud(1'b1),
    .data_in(data_in),
    .buffer_write(utx_buffer_write),

    //Outputs
    .serial_out(uart_txd),
    .buffer_full(utx_buffer_full),
    .buffer_half_full(utx_buffer_half_full),
    .buffer_data_present(utx_buffer_data_present)
);

nexys4fpga target (
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
    .JB(JB)
);


// print any uart data coming out of the nexys4fpga
always @(data_out) begin
    $display("UART data out: %s", data_out);
end

initial begin
    // reset the system
    #5   btnCpuReset = 1'b1;
    #100 btnCpuReset = 1'b0;
    
    // send it something, apparently it needs a little nudge to get going
    #10 write_uart(8'h11);
    // wait a long time - let FPGA do its thing for a while, should see "HELLO WORLD" come out on UART
    //#1000000;
    
    // stop simulation
    //$finish;
end

task write_uart;
input [7:0] data;
begin
    // make sure buffer isn't full
    //while (utx_buffer_full) 
    @(posedge clk);
        data_in = data;
        utx_buffer_write = 1'b1;
    @(posedge clk);
        data_in = 8'h00;
        utx_buffer_write = 1'b0;
end
endtask

endmodule
