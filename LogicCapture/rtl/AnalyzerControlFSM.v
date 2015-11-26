/* AnalyzerControlFSM.v - Module provides state transition
 * logic for the logic capture peripheral. It uses input
 * control signals start and abort as well as local status
 * signals sawTrigger and complete to update the state
 * of the peripheral accordingly. 
 * Possible states are idle, pre_trigger, and post_trigger. 
 */
module AnalyzerControlFSM (
    input clock,
    input reset,
    // FSM Inputs
    input start,
    input abort,
    input sawTrigger,
    input complete,
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

// Sequential Logic
always @(posedge clock) begin
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
                            if(abort)
                                nextState = IDLE;
                            else if(sawTrigger)
                                nextState = RUN_POSTTRIGGER;
                            else
                                nextState = RUN_PRETRIGGER;
                         end
        RUN_POSTTRIGGER: begin
                            if (abort | complete)
                                nextState = IDLE;
                            else
                                nextState = RUN_POSTTRIGGER;
                         end
    endcase
end

// Output Combinational Logic
always @*
begin
    // Set defaults
    triggered = 0;
    running   = 0;
    idle      = 0;
    case(state)
        IDLE:            idle         = 1;
        RUN_PRETRIGGER:  pre_trigger  = 1;
        RUN_POSTTRIGGER: post_trigger = 1;
     endcase
end
    
endmodule