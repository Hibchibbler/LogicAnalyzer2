module SampleGen_TB ();

initial begin
    $dumpfile("SampleGen.vcd");
    $dumpvars(0, SampleGen_TB);
end

parameter MAX_CLOCKS = 1000000;

wire [31:0] samplePacket;
wire [31:0] sample_number;
wire write_enable;

reg [13:0] delayCntr;

reg clk, reset, running, transition;
reg [15:0] sampleData;

initial clk = 1'b0;
always begin
    #2 clk = ~clk;
end

initial begin
    reset = 1'b1;
    #(10) reset = 1'b0;
end

SampleGen gen(
    .clk(clk),
    .reset(reset),
    .running(running),
    .transition(transition),
    .sampleData(sampleData),
    .samplePacket(samplePacket),
    .sample_number(sample_number),
    .write_enable(write_enable)
);

always @(posedge clk) begin
    if (reset) begin
        transition <= 0;
    end else begin
        if (delayCntr == MAX_DELAY_CNTR) begin
            transition <= $random;
        end else begin
            transition <= 1'b0;
        end
    end
end

always @(*) begin
    if (transition) begin
        sampleData = $random;
    end else begin
        sampleData = sampleData;
    end
end

parameter MAX_DELAY_CNTR = 0;

integer clkCount;
initial clkCount = 0;
initial delayCntr = 0;
always @(posedge clk) begin
    if (delayCntr == MAX_DELAY_CNTR) begin
        delayCntr <= 0;
    end else begin
        delayCntr <= delayCntr + 1;
    end
    clkCount  <= clkCount + 1;
    if (clkCount == MAX_CLOCKS) begin
        $finish;
    end
    if (clkCount > 20) begin
        running <= 1'b1;
    end else begin
        running <= 1'b0;
    end
end

endmodule