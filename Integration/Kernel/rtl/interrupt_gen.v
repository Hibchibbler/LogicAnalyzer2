`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/22/2015 08:48:00 PM
// Design Name: 
// Module Name: interrupt_gen
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


module interrupt_gen
(
    input wire clk,
    input wire reset,
    
    output reg interrupt1s

);

    reg [26:0] interrupt1s_counter;
    

    

    always @(posedge clk) begin
        if (reset == 1'b1) begin
            interrupt1s_counter <= 27'd0;
            interrupt1s <= 1'b0;
        end else begin
            interrupt1s_counter <= (interrupt1s_counter + 1'b1) % 27'd100000000;
            if (interrupt1s_counter > 27'd99999997)             
                interrupt1s <= 1'b1;
            else
                interrupt1s <= 1'b0;
        end
    end
endmodule
