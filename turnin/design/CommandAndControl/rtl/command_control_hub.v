`timescale 1ps/100fs
//////////////////////////////////////////////////////////////////////////////////
// Command and Control Interface/Hub
// 
// Logic Analyzer
// Portland State University, 2015
//  Dan Ferguson
//  Brandon Mousseau
//  Chip Wood
//
// This module is intended to interface several other modules together:
//  LogCap
//  Command_control
//  UART
//
// LogCap talks with Command_control through the reg in/out registers,
// while Command_control talks to the outside world through UART
//////////////////////////////////////////////////////////////////////////////////
module  command_control_hub
(
    input  wire       clk,
    input  wire       reset,
    
    //Nexys4 IO Peripherals
    output reg [15:0] led,
    input wire  [7:0] button,
    input wire [15:0] switch,
    
    //Command & Control
    output wire       interrupt,
    input  wire       interrupt_ack,
    input  wire [7:0] port_id,
    input  wire [7:0] port_out,
    output reg  [7:0] port_in,
    input  wire       write_strobe,
    input  wire       kwrite_strobe,
    input  wire       read_strobe,
    
    //UART Receive
    input  wire [7:0] data_rx,
    input  wire       urx_buffer_full,
    input  wire       urx_buffer_half_full,
    input  wire       urx_buffer_data_present,
    output reg        urx_buffer_read,
    
    //UART Transmit
    output wire [7:0] data_tx,
    input  wire       utx_buffer_full,
    input  wire       utx_buffer_half_full,
    input  wire       utx_buffer_data_present,
    output wire       utx_buffer_write,
    
    //LogCap
    input  wire [7:0] regIn0,
    input  wire [7:0] regIn1,
    input  wire [7:0] regIn2,
    input  wire [7:0] regIn3,
    input  wire [7:0] regIn4,
    input  wire [7:0] regIn5,
    input  wire [7:0] regIn6,
    input  wire [7:0] regIn7,    
    output reg  [7:0] regOut0,
    output reg  [7:0] regOut1,
    output reg  [7:0] regOut2,
    output reg  [7:0] regOut3,
    output reg  [7:0] regOut4,
    output reg  [7:0] regOut5,
    output reg  [7:0] regOut6,
    output reg  [7:0] regOut7,    
    output reg        command_strobe,
    output reg  [7:0] command,
    input  wire [7:0] status
    
);

    localparam  PA_READ_LOGCAP_REGISTER0    = 8'h00,
                PA_READ_LOGCAP_REGISTER1    = 8'h01,
                PA_READ_LOGCAP_REGISTER2    = 8'h02,
                PA_READ_LOGCAP_REGISTER3    = 8'h03,
                PA_READ_LOGCAP_REGISTER4    = 8'h04,
                PA_READ_LOGCAP_REGISTER5    = 8'h05,
                PA_READ_LOGCAP_REGISTER6    = 8'h06,
                PA_READ_LOGCAP_REGISTER7    = 8'h07,
                PA_READ_LOGCAP_STATUS       = 8'h08,
                PA_READ_UART_DATA           = 8'h09,
                PA_READ_UART_STATUS         = 8'h0A,
                PA_READ_SWITCHES_7_0        = 8'h0B,
                PA_READ_SWITCHES_15_8       = 8'h0C,
                PA_READ_BUTTONS             = 8'h0D;    


    localparam  PA_WRITE_LOGCAP_REGISTER0   = 8'h00,
                PA_WRITE_LOGCAP_REGISTER1   = 8'h01,
                PA_WRITE_LOGCAP_REGISTER2   = 8'h02,
                PA_WRITE_LOGCAP_REGISTER3   = 8'h03,
                PA_WRITE_LOGCAP_REGISTER4   = 8'h04,
                PA_WRITE_LOGCAP_REGISTER5   = 8'h05,
                PA_WRITE_LOGCAP_REGISTER6   = 8'h06,
                PA_WRITE_LOGCAP_REGISTER7   = 8'h07,
                PA_WRITE_LOGCAP_COMMAND     = 8'h08,
                PA_WRITE_UART_DATA          = 8'h09,
                PA_WRITE_LED_7_0            = 8'h0A,
                PA_WRITE_LED_15_8           = 8'h0B;
    
    //General Writes    
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            led     <= 16'b0;
            regOut0 <= 8'b0;
            regOut1 <= 8'b0;
            regOut2 <= 8'b0;
            regOut3 <= 8'b0;
            regOut4 <= 8'b0;
            regOut5 <= 8'b0;
            regOut6 <= 8'b0;
            regOut7 <= 8'b0;
        end else begin
            if (write_strobe == 1'b1) begin
                case (port_id[3:0])
                    PA_WRITE_LOGCAP_REGISTER0: regOut0 <= port_out;
                    PA_WRITE_LOGCAP_REGISTER1: regOut1 <= port_out;
                    PA_WRITE_LOGCAP_REGISTER2: regOut2 <= port_out;
                    PA_WRITE_LOGCAP_REGISTER3: regOut3 <= port_out;
                    PA_WRITE_LOGCAP_REGISTER4: regOut4 <= port_out;
                    PA_WRITE_LOGCAP_REGISTER5: regOut5 <= port_out;
                    PA_WRITE_LOGCAP_REGISTER6: regOut6 <= port_out;
                    PA_WRITE_LOGCAP_REGISTER7: regOut7 <= port_out;
                    PA_WRITE_LOGCAP_COMMAND: begin
                        command         <= port_out;
                        command_strobe  <= 1'b1;                        
                    end
                    //PA_WRITE_UART_DATA Is handled combinationally.
                    PA_WRITE_LED_7_0:  led[7:0]  <= port_out;
                    PA_WRITE_LED_15_8: led[15:8] <= port_out;
                    default: led <= led;
                endcase
            end else begin
                command_strobe <= 1'b0;
            end
        end
    end
    
    //UART Writes - combinationally
    assign utx_buffer_write =  write_strobe && (port_id == PA_WRITE_UART_DATA);
    assign data_tx = port_out;    
    
    //General Reads
    always @(posedge clk) begin
        case (port_id[3:0])
            PA_READ_LOGCAP_REGISTER0:  port_in <= regIn0;
            PA_READ_LOGCAP_REGISTER1:  port_in <= regIn1;
            PA_READ_LOGCAP_REGISTER2:  port_in <= regIn2;
            PA_READ_LOGCAP_REGISTER3:  port_in <= regIn3;
            PA_READ_LOGCAP_REGISTER4:  port_in <= regIn4;
            PA_READ_LOGCAP_REGISTER5:  port_in <= regIn5;
            PA_READ_LOGCAP_REGISTER6:  port_in <= regIn6;
            PA_READ_LOGCAP_REGISTER7:  port_in <= regIn7;
            PA_READ_LOGCAP_STATUS:     port_in <= status;
            PA_READ_UART_DATA:         port_in <= data_rx;
            PA_READ_UART_STATUS:       port_in <= {2'b00, 
                                                   urx_buffer_full,
                                                   urx_buffer_half_full,
                                                   urx_buffer_data_present, 
                                                   utx_buffer_full, 
                                                   utx_buffer_half_full, 
                                                   utx_buffer_data_present};
            PA_READ_SWITCHES_7_0:      port_in <= switch[7:0];
            PA_READ_SWITCHES_15_8:     port_in <= switch[15:8];        
            PA_READ_BUTTONS:           port_in <= button;    
            default:                   port_in <= 8'bXXXXXXXX;
        endcase
    end
    
    //UART Read strobe is registered.
    always @(posedge clk) begin
        if (reset == 1'b1)
            urx_buffer_read <= 1'b0; 
        else begin
            if ((read_strobe == 1'b1) && (port_id == PA_READ_UART_DATA)) begin
                urx_buffer_read <= 1'b1;
            end else begin
                urx_buffer_read <= 1'b0;
            end       
        end 
    end

    //Generate an Interrupt every second for Command&Control(100MHz clk)
    interrupt_gen ig
    (
        //Input
        .clk(clk),
        .reset(reset),
        //Output
        .interrupt1s(interrupt)
    );
    
    
endmodule