module TriggerTransDetection #(
    parameter SAMPLE_WIDTH = 8
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
    input [31:0] edgeChannel,
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