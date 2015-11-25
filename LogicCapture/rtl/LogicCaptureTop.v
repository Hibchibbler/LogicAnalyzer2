module LogicCaptureTop #(
    parameter CPU_DW           = 8,
    parameter SRAM_DW         = 16,
    parameter SRAM_AW         = 16,
    // Parameter describes physical sample width (ie, max).
    // User may select SAMPLE_WIDTH or less active channels
    parameter SAMPLE_WIDTH = 8
) (
    input   clock,
    input   reset,
    
    input [SAMPLE_WIDTH-1:0] sampleData,
    
    // CPU Interface
    input   [CPU_DW-1:0] cpu_data_in,
    output [CPU_DW-1:0] cpu_data_out,
    
    //SRAM Interface Signals
    inout   [SRAM_DW-1:0] sram_data,
    output [SRAM_AW-1:0] sram_address,
    output sram_oe,
    output sram_ce,
    output sram_we
);

    // Save current and previous samples
    reg [SAMPLE_WIDTH-1:0] latestSample;
    reg [SAMPLE_WIDTH-1:0] previousSample;
    
    always @(posedge clock) begin
        if (reset) begin
            latestSample     <= 0;
            previousSample <= 0;            
        end else begin
            latestSample     <= sampleData;
            previousSample <= latestSample;
        end
    end
    
    // Trigger and Transistion Detection
    wire triggered,transition;
    TriggerTransDetection #(
        .SAMPLE_WIDTH(SAMPLE_WIDTH)
    ) triggerModule (
        .latestSample(latestSample),
        .previousSample(previousSample),
        .triggered(triggered),
        .transition(transition)
     );
     
     LogicCaptureControl #(
        .CPU_DW(CPU_DW),
        .SRAM_DW(SRAM_DW),
        .SRAM_AW(SRAM_AW),
        .SAMPLE_WIDTH(SAMPLE_WIDTH)
     ) controlUnit (
        .clock(clock),
        .reset(reset),
        .triggerDetected(triggered),
        .sampleTransistion(trasistion),
        .sampleData(latestSample), // Based on clock transistions, maybe it actually makes sense to pass previous sample in.
        .cpu_data_in(cpu_data_in),
        .cpu_data_out(cpu_data_out),
        .sram_data(sram_data),
        .sram_address(sram_address),
        .sram_oe(sram_oe),
        .sram_ce(sram_ce),
        .sram_we(sram_we)
     );

endmodule