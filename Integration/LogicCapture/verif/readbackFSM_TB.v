module readbackFSM_TB();


reg clk, reset, idle, read_trace_data, read_allowed;

wire [31:0] readSampleNumber;
wire read_req;
reg [31:0] begin_num;
reg [31:0] end_num;

initial begin
    $dumpfile("readbackFSM_TB.vcd");
    $dumpvars(0,readbackFSM_TB);
end

initial clk = 0;
always #1 clk = ~clk;

initial begin
    reset = 1;
    #4 reset = 0;
end

initial begin
    idle            = 0;
    read_trace_data = 0;
    read_allowed    = 1;
//    begin_num       = 33554416;
//    end_num         = 19;
    begin_num       = 7;
    end_num         = 106;
end

parameter IDLE_CLKS       = 10;
parameter READ_TRACE_DATA = 15;

analyzerReadbackFSM dut(
    .clk(clk),
    .reset(reset),
    .idle(idle), // sampler is in idle state
    .read_trace_data(read_trace_data),  
    .readSampleNumber(readSampleNumber),
    .read_req(read_req),
    
    .read_allowed(read_allowed),
    .sampleNumber_Begin(begin_num),
    .sampleNumber_End(end_num)
);

parameter MAX_CLOCKS = 100;
reg [31:0] clkCount;
initial clkCount = 0;
always @(posedge clk) begin
    if (clkCount == MAX_CLOCKS) begin
        $finish;
    end else begin
        clkCount <= clkCount + 1;
    end
end

always @(posedge clk) begin
    if (clkCount >= IDLE_CLKS) begin
        idle <= 1'b1;
    end else begin
        idle <= 1'b0;
    end
    if (clkCount == READ_TRACE_DATA) begin
        read_trace_data <= 1'b1;
    end else begin
        read_trace_data <= 1'b0;
    end
    if (read_req) begin
        if (clkCount == 24)
            read_allowed <= 1'b0;
        else
            read_allowed <= $random;
    end else begin
        if (read_allowed) begin
            read_allowed <= 1'b1;
        end else begin
            read_allowed <= $random;
        end
    end
       
end

endmodule