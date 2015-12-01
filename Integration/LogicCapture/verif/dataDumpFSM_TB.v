module dataDumpFSM_TB();

reg clk, reset, dumpCmd;
reg idle, has_return_data;
reg logcapAck;

wire get_return_data, load_l, load_u;

initial begin
    $dumpfile("dataDumpFSM.vcd");
    $dumpvars(0,dataDumpFSM_TB);
end

initial clk = 0;
always #1 clk = ~clk;

initial begin
    dumpCmd = 0;
    idle = 0;
    has_return_data = 0;
    logcapAck = 0;
    reset = 1;
    #4 reset = 0;
end

parameter IDLE_CLKS = 10;
parameter DUMP_CMD  = 20;        

dataDumpFSM dut (
    .clk(clk),
    .reset(reset),
    .dumpCmd(dumpCmd),
    .logcapAck(logcapAck),
    .idle(idle),
    .has_return_data(has_return_data),
    .get_return_data(get_return_data),
    .load_l(load_l),
    .load_u(load_u)
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
    if (get_return_data) begin
        has_return_data <= $random;
    end else begin
        if (has_return_data) begin
            has_return_data <= 1'b1;
        end else begin
            if (clkCount > DUMP_CMD) begin
                has_return_data <= $random;
            end else begin
                has_return_data <= 1'b0;
            end
        end
    end
end

reg getD;

always @(posedge clk) begin
    if (load_l | load_u) begin
        logcapAck <= 1'b1;
    end
    if (logcapAck) begin
        getD      <= 1'b1;
        logcapAck <= 1'b0;
    end else begin
        getD <= 1'b0;
    end
    if (getD | (clkCount == DUMP_CMD)) begin
        dumpCmd <= 1'b1;
    end else begin
        dumpCmd <= 1'b0;
    end
end

endmodule