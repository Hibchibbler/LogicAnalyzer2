`timescale 1ps/100fs
//////////////////////////////////////////////////////////////////////////////////
// PicoBlaze Interrupt Generator
// 
// Logic Analyzer
// Portland State University, 2015
//  Dan Ferguson
//  Brandon Mousseau
//  Chip Wood
//
// This module generates a 3 cycle pulse every 1 second, intended to act as a
// clock for a heartbeat signal via LEDs on the Nexys4DDR development board.
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
