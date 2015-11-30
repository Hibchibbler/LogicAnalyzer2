module pulseGen_TB();

reg clk, reset, start, waitOnMe;
reg [31:0] pulseCount;

initial clk = 0;
always #1 clk = ~clk;

initial begin
    $dumpfile("pulseGen_TB.vcd");
    $dumpvars(0,pulseGen_TB);
end

initial begin
    reset = 1;
    #3 reset = 0;
end

initial begin
    pulseCount = 5;
    start = 0;
    waitOnMe = 0;
    #9 start = 1;
    #2  start = 0;
    #10 waitOnMe = 1;
    #50;
    $finish;
end

pulseGen dut (
    .clk(clk),
    .reset(reset),
    .start(start),
    // Minimum pulses
    .pulseCount(pulseCount),
    // Wait signal before de-asserting (tie to 1 if no wait)
    .waitOnMe(waitOnMe),
    .pulse()
);

endmodule