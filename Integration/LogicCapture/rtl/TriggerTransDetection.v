`timescale 1ps/100fs
/* TriggerTransDetection.v - This module provides
 * combinational logic on the sample input to
 * detect different conditions that we care about.
 *
 * Triggers -
 *   Edge Triggers - Uses current sample, previous sample,
 *   and the edge trigger configuration to output a signal
 *   indicating if an edge trigger is "triggered". If edge
 *   trigger is disabled, the edgeTrigger is considered always
 *   triggered.
 *
 *   Pattern Trigger - Compares the current sample
 *   with a desired pattern and configuration to output
 *   if a pattern has been detected. If the pattern trigger is
 *   disabled, then this trigger is considered always triggered.
 *
 *   The final "triggered" output is true if both the edge and
 *   pattern trigger conditions are satisfied. Note, that since
 *   this module provides only combinational logic, the surrounding
 *   sequential logic must capture the triggered signal and react
 *   accordingly.
 *
 * Transition -
 *   The transition signal is asserted whenever the active channels
 *   of the current sample and the previous sample are not equal.
 *
 * Parameters:
 *   SAMPLE_WIDTH - The total number of channels supported
 *
 * Inputs:
 *   latestSample          - The current sample
 *   previousSample        - The last sample
 *   activeChannels        - Each bit indicates whether a channel is active or not
 *   edgeChannel           - Indicates the channel that the edge trigger applies to.
 *   edgeType              - 1 = positive edge trigger, 0 = negative edge trigger
 *   edgeTriggerEnabled    - Enable/disable for the edge trigger
 *   desiredPattern        - The desired value to be observed on active channels
 *   dontCareChannels      - If a channel is active, but the pattern is not considered for the trigger
 *   patternTriggerEnabled - Enable/disable for the pattern trigger
 * Ouputs:
 *   triggered  - Indicates a configured trigger is active
 *   transition - Indicates a transition occurred on at least 1 active channel
 *
 * Author: Brandon Mousseau bam7@pdx.edu
 */
module TriggerTransDetection #(
    parameter SAMPLE_WIDTH = 16
) (
    input [SAMPLE_WIDTH-1:0] latestSample,
    input [SAMPLE_WIDTH-1:0] previousSample,
    output reg triggered,
    output reg transition,
    
    // Which channels are being measured?
    input [SAMPLE_WIDTH-1:0] activeChannels,
    
    // Configurations For triggers
    // Edge Trigger Configurations
    // Which channel is the edge being monitored on?
    input [7:0] edgeChannel,
    // 1 = positive edge, 0 = negative edge
    input edgeType,
    // Is the edge trigger actually active?
    input edgeTriggerEnabled,
    
    // Pattern Matching Trigger
    input patternTriggerEnabled,
    input [SAMPLE_WIDTH-1:0] desiredPattern,
    input [SAMPLE_WIDTH-1:0] dontCareChannels
); 
    
    // Edge detection trigger
    reg edgeTrigger;
    reg edgeValCurrent;
    reg edgeValPrev;
    always @* begin
        edgeValCurrent = latestSample[edgeChannel];
        edgeValPrev     = previousSample[edgeChannel];
        if (edgeTriggerEnabled) begin
            if (edgeType) begin
                // Positive Edge Detection
                if (~edgeValPrev & edgeValCurrent)
                    edgeTrigger = 1;
                else
                    edgeTrigger = 0;
            end else begin
                // Negative Edge Detection
                if (edgeValPrev & ~edgeValCurrent)
                    edgeTrigger = 1;
                else
                    edgeTrigger = 0;
            
            end
        end else begin
            // If trigger is disabled, it is true by default
            edgeTrigger = 1;
        end
    end
    
    // Pattern Trigger Detection
    reg patternTrigger;
    reg [SAMPLE_WIDTH-1:0] channelMatches;
    always @* begin
        // If the channel is not actively monitored or is treated as dont care, then it will always be a channelMatch hit.
        // If the channel is active and is not a "dont care" for the trigger, then it matches if the sample matches the desired value
        channelMatches = (~activeChannels) | dontCareChannels | (latestSample ~^ desiredPattern);
        if (patternTriggerEnabled) begin
            // Trigger is only true if every bit is true
            patternTrigger = & channelMatches;
        end else begin
            // If trigger is disabled, it is true by default
            patternTrigger = 1;
        end
    end
    
     // Combinational logic for output signals
    always @* begin
        if (edgeTrigger & patternTrigger) begin
           triggered = 1;
        end else begin
            triggered = 0;
        end
        if (activeChannels & (latestSample ^ previousSample)) begin
            transition = 1;
        end else begin
            transition = 0;
        end
    end

endmodule