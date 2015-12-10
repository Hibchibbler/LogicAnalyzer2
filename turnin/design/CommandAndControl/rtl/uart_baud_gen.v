`timescale 1ps/100fs

//////////////////////////////////////////////////////////////////////////////////
// UART Baud Generator
// Creates a baud rate signal for UARTs
// 
// Logic Analyzer
// Portland State University, 2015
//  Dan Ferguson
//  Brandon Mousseau
//  Chip Wood
//////////////////////////////////////////////////////////////////////////////////

module uart_baud_gen(
    input clk,
    input reset,
    
    output reg en_16_x_baud
    );
    
       //
     /////////////////////////////////////////////////////////////////////////////////////////
     // RS232 (UART) baud rate 
     /////////////////////////////////////////////////////////////////////////////////////////
     //
     // To set serial communication baud rate to 115,200 then en_16_x_baud must pulse 
     // High at 1,843,200Hz which is every 27.13 cycles at 50MHz. In this implementation 
     // a pulse is generated every 27 cycles resulting is a baud rate of 115,741 baud which
     // is only 0.5% high and well within limits.
     //
     // 200,000,000 / 115200   = 1736.111111111111
     // baud_count = 1736.111111111111 / 16 = 108.5069444444444 
     //
     // 100,000,000 / 115200   = 868.0555555555556
     // baud_count = 868.0555555555556 / 16 = 54.25347222222222
     // 54 54 54 55 => 54.25
   
     //reg en_16_x_baud;
     reg [6:0] baud_count;
     reg [5:0] max_count[3:0];
     reg [2:0] skip_count;
     
     
     localparam FIFTYFOUR = 6'b110110,
                FIFTYFIVE = 6'b110111;

     always @(posedge clk) begin
         if (reset == 1'b1) begin
             baud_count <= 0;
             max_count[0] <= FIFTYFOUR;
             max_count[1] <= FIFTYFOUR;
             max_count[2] <= FIFTYFOUR;
             max_count[3] <= FIFTYFIVE;
             skip_count <= 3'b000;             
         end else begin
             if (baud_count == max_count[skip_count]) begin       // counts 27 states including zero
                 baud_count <= 7'b0000000;
                 en_16_x_baud <= 1'b1;                 // single cycle enable pulse                
                 skip_count <= (skip_count + 1'b1) % 4;                
             end            
             else begin
                 baud_count <= baud_count + 7'b0000001;
                 en_16_x_baud <= 1'b0;
             end
         end
     end

endmodule
