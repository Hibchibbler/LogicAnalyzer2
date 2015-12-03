`timescale 1ns / 100ps

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

reg         clk;                            // clock of nexys4fpga
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

wire [15:0] ddr2_dq;
wire [1:0]  ddr2_dqs_n;
wire [1:0]  ddr2_dqs_p;
wire [12:0] ddr2_addr;
wire [2:0]  ddr2_ba;
wire        ddr2_ras_n;
wire        ddr2_cas_n;
wire        ddr2_we_n;
wire [0:0]  ddr2_ck_p;
wire [0:0]  ddr2_ck_n;
wire [0:0]  ddr2_cke;
wire [0:0]  ddr2_cs_n;
wire [1:0]  ddr2_dm;
wire [0:0]  ddr2_odt;


integer i;

initial begin
    clk = 1'b0;
    {btnW, btnE, btnN, btnS, btnC} = 5'h00;
    sw = 16'h0000;
    data_tx = 8'h00;
    utx_buffer_write = 1'b0;
    JA = 8'h00;
    JB = 8'h00;
end

// 100MHz clock
always #5 clk = ~clk;

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
    // ddr pins
    .(ddr2_dq),
    .(ddr2_dqs_n),
    .(ddr2_dqs_p),
    .(ddr2_addr),
    .(ddr2_ba),
    .(ddr2_ras_n),
    .(ddr2_cas_n),
    .(ddr2_we_n),
    .(ddr2_ck_p),
    .(ddr2_ck_n),
    .(ddr2_cke),
    .(ddr2_cs_n),
    .(ddr2_dm),
    .(ddr2_odt)
);


// UART READS
// just read them as they come out - data present wire will go high, simply drive the buffer_read signal high to get data onto data_rx
assign urx_buffer_read = urx_buffer_data_present;
// print any uart data coming out of the nexys4fpga
always @(negedge urx_buffer_read) $display("%5d UART data out: %h", $time, data_rx);

initial begin
    // reset the system
    #5   btnCpuReset = `RESET;
    #100 btnCpuReset = ~`RESET;

    //for (i=0; i<100; i=i+1)
    #10 cmd_abort();
    #100 cmd_write_trig_cfg({{56{1'b0},8'h55});
    #100 cmd_read_trig_cfg();
    
    // takes a total of ~22uS to get the full "HELLO World" back
    #22000;
    
    
    //$finish;
end

task cmd_start;
begin
    write_uart({64{1'b0}, 8'h01});
end
endtask

task cmd_abort;
begin
    write_uart({64{1'b0}, 8'h02});
end
endtask

task cmd_write_trig_cfg;
input [63:0] trig_cfg;
begin
    write_uart(trig_cfg, 8'h03});
end
endtask

task cmd_write_buff_cfg;
input [63:0] buff_cfg;
begin
    write_uart(buff_cfg, 8'h04});
end
endtask

task cmd_read_trace_data;
begin
    write_uart({64{1'b0}, 8'h05});
end
endtask

task cmd_read_trace_size;
begin
    write_uart({64{1'b0}, 8'h06});
end
endtask

task cmd_read_trig_sample;
begin
    write_uart({64{1'b0}, 8'h07});
end
endtask

task cmd_reset_logcap;
begin
    write_uart({64{1'b0}, 8'h09});
end
endtask

task cmd_read_buff_cfg;
begin
    write_uart({64{1'b0}, 8'h0A});
end
endtask

task cmd_read_trig_cfg;
begin
    write_uart({64{1'b0}, 8'h0B});
end
endtask



task write_uart;
input [71:0] data;
integer count = 0;
begin
    // make sure buffer isn't full
    //while (utx_buffer_full) 
    
    while (count < 9) begin
        if (utx_buffer_full) begin // wait a cycle
            @(posedge clk);
        end 
        else begin
            @(posedge clk);
                data_tx = data[count+7:count];
                utx_buffer_write = 1'b1;
            @(posedge clk);
                utx_buffer_write = 1'b0;
                count = count + 1;
        end
    end
end
endtask

endmodule
