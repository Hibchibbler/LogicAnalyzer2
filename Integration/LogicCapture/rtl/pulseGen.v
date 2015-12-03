`timescale 1ps/100fs
/* pulseGen.v - Produces a pulse of a desired length. Can
 *              also wait on a signal to be asserted before
 *              removing the pulse.
 * inputs:
 *   start - begin the pulse
 *   pulseCount - the minumum number of clocks to pulse the signal
 *   waitOnMe   - The pulse will stay high until this is asserted.
 *                Tie to 1 if you only want to pulse pulseCount times
 * outputs:
 *    pulse - the output pulse signal
 *
 */
module pulseGen (
    input clk,
    input reset,
    
    input start,
    
    // Minimum pulses
    input [31:0] pulseCount,
    
    // Wait signal before deaasserting (tie to 1 if no wait)
    input waitOnMe,
    
    output reg pulse
);

localparam IDLE = 1'b0, PULSING = 1'b1;

reg [31:0] count;
reg state, nextState;

reg pulseComplete;

always @(*) begin
    pulseComplete = (count >= (pulseCount-1)) & waitOnMe;
end

always @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
    end else begin
        state <= nextState;
    end
end

always @(*) begin
    case(state)
        IDLE:    begin
                    if (start)
                        nextState = PULSING;
                    else
                        nextState = IDLE;
                 end
        PULSING: begin
                    if (pulseComplete)
                        nextState = IDLE;
                    else
                        nextState = PULSING;
                 end
    endcase
end

always @(*) begin
    case(state)
        IDLE:    pulse = 1'b0;
        PULSING: pulse = 1'b1;
    endcase
end

// Keep track of counter
always @(posedge clk) begin
    if (reset) begin
        count <= 32'd0;
    end else begin
        if (state == PULSING) begin
            count <= count + 32'd1;
        end else begin
            count <= 32'd0;
        end
    end
end

endmodule