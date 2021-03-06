`timescale 1ps/100fs
/* AnalyzerControlFSM.v - Module provides state transition
 * logic for the logic capture peripheral. It uses input
 * control signals start and abort as well as local status
 * signals sawTrigger and complete to update the state
 * of the peripheral accordingly. 
 * Possible states are idle, pre_trigger, and post_trigger.
 *
 * Author: Brandon Mousseau bam7@pdx.edu
 */
module AnalyzerControlFSM (
    input clk,
    input reset,
    // FSM Inputs
    input start,
    input abort,
    input sawTrigger,
    input complete,
    input pageFull,
    // FSM Outputs
    output reg post_trigger,  // Sampling, pre trigger
    output reg pre_trigger,    // Sampling, post trigger
    output reg idle
);

localparam IDLE            = 2'b00;
localparam START_DELAY     = 2'b01;
localparam RUN_PRETRIGGER  = 2'b10;
localparam RUN_POSTTRIGGER = 2'b11;

reg [1:0] state, nextState;

// We want to hold delay real abort while sampling
// if in the middle of a page of samples
reg abortSignal;
always @(*) begin
    abortSignal = abort & pageFull;
end

// Sequential Logic
always @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
    end else begin
        state <= nextState;
    end
end

// Next State Combinational Logic
always @*
begin
    nextState = IDLE;
    case(state)
        IDLE:            begin
                            if (start & ~abort)
                                nextState  = RUN_PRETRIGGER;
                            else
                                nextState  = IDLE;
                         end
        START_DELAY:     begin
                            if(abort)
                                nextState = IDLE;
                            else if (~start)
                                nextState = RUN_PRETRIGGER;
                            else
                                nextState = START_DELAY;
                         end
        RUN_PRETRIGGER:  begin
                            if(abortSignal)
                                nextState = IDLE;
                            else if(sawTrigger)
                                nextState = RUN_POSTTRIGGER;
                            else
                                nextState = RUN_PRETRIGGER;
                         end
        RUN_POSTTRIGGER: begin
                            if (abortSignal | complete)
                                nextState = IDLE;
                            else
                                nextState = RUN_POSTTRIGGER;
                         end
    endcase
end

// Output Combinational Logic
always @(*) begin
    // Set defaults
    post_trigger = 0;
    pre_trigger  = 0;
    idle         = 0;
    case(state)
        IDLE:            idle         = 1;
        RUN_PRETRIGGER:  pre_trigger  = 1;
        RUN_POSTTRIGGER: post_trigger = 1;
     endcase
end
    
endmodule