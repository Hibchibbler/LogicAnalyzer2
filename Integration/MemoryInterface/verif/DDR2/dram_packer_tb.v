module dram_packer_tb ();

parameter DATA_WIDTH = 16;
parameter DRAM_WIDTH = 128;

parameter CLK_PERIOD   = 2;
parameter RESET_PERIOD = 10;
parameter MAX_CLOCKS   = 500;

// For iverilog outputs
initial begin
    $dumpfile("dram_packer.vcd");
    $dumpvars(0,dram_packer_tb);
end

reg clk, resetn, we, write_allowed;
integer clkCount;
wire [DATA_WIDTH-1:0] sample_data;
reg [31:0] sample_num;

initial begin
    clk = 1'b0;
end

always begin
    #(1) clk = ~clk;
end


initial begin
    resetn = 1'b0;
    #RESET_PERIOD resetn = 1'b1;
end

assign sample_data = sample_num[DATA_WIDTH-1:0];

always @(posedge clk) begin
    if (~resetn) begin
        sample_num    <= 32'hFFFFFFFF;
        we            <= 1'b0;
        write_allowed <= 1'b0;
    end else begin
        write_allowed <= 1'b1;
        we            <= 1'b1;
        sample_num    <= sample_num + 1;
    end
end

dram_packer #(
    .DATA_WIDTH(DATA_WIDTH),
    .DRAM_WIDTH(DRAM_WIDTH)
) packer (
    .clk(clk),
    .resetn(resetn),
    .we(we),
    .write_data(sample_data),
    .sample_num(sample_num),
    .dram_data(),
    .dram_adx(),
    .write_req(),
    .write_allowed(write_allowed)

);

wire maxReached;
assign maxReached = clkCount >= MAX_CLOCKS;

initial clkCount <= 0;
always @(posedge clk) begin
    clkCount <= clkCount + 1;
    if (maxReached) begin
        $display("DONE: %d clocks of %d\n", clkCount, MAX_CLOCKS);
        $finish;
    end
end

endmodule