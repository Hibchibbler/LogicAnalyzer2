module SignalGenerator
#(
    parameter NUM_CHANNELS = 16,       //Change this to modify how many signals are generated
    parameter UPDATE_COUNT_BITS   = 15 //Change this to modify signal update rate
)
(
    input wire clk,
    input wire reset,
    
    output reg[NUM_CHANNELS-1:0] chanSignals
);    

    reg[UPDATE_COUNT_BITS-1:0] updateSignals;

    always @ (posedge clk)  begin
        if (reset == 1'b1)
            updateSignals   <= {UPDATE_COUNT_BITS{1'b0}};
        else begin
            updateSignals   <= updateSignals + 1'b1;
        end
    end

    always @ (posedge clk)  begin
        if (reset == 1'b1)
            chanSignals     <= {NUM_CHANNELS{1'b0}};
        else begin
            if (&updateSignals)
            chanSignals     <= chanSignals + 1'b1;
        end
    end
endmodule