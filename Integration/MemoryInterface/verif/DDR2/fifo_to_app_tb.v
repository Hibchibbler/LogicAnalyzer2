module fifo_to_app_tb ();

    reg clk;
    reg resetn;
    reg  mode;
    reg  has_wr_req;
    wire get_wr_req;
    reg  [127:0] wr_data_in;
    reg  [26:0] wr_adx_in;
    reg  has_rd_req;
    wire get_rd_req;
    reg  [26:0] rd_adx_in'
    
    reg  app_rdy;
    reg  app_wdf_rdy;
    
    wire [63:0] app_wdf_data;
    wire [26:0] app_addr;
    wire app_en;
    wire app_wdf_end;
    wire app_wdf_wren;
    wire [2:0] app_cmd;
    
    parameter MAX_CLOCKS = 2000;
    
    initial begin
        $dumpfile("fifo_to_app.vcd");
        $dumpvars(0,fifo_to_app_tb);
        clk = 1'b0;
        clkCount = 0;
    end
    
    fifo_to_app f2a_mut (
        .clk(clk),
        .resetn(resetn),
        // read = 0, write = 1
        .mode(mode),
    
        // From ddr_fifo
        .has_wr_req(has_wr_req),
        .get_wr_req(get_wr_req),
        .wr_data_in(wr_data_in),
        .wr_adx_in(wr_adx_in),
        .has_rd_req(has_rd_req),
        .get_rd_req(get_rd_req),
        .rd_adx_in(rd_adx_in),
    
        // To DDR controller
        .app_wdf_data(app_wdf_data),
        .app_addr(app_addr),
        .app_en(app_en),
        .app_wdf_end(app_wdf_end),
        .app_wdf_wren(app_wdf_wren),
        .app_cmd(app_cmd),
        // From DDR controller
        .app_rdy(app_rdy),
        .app_wdf_rdy(app_wdf_rdy)
    );
    
    reg [32:0] clkCount;
    
    always @(posedge clk) begin
        clkCount    <= clkCount + 1'd1;
        if (~resetn) begin

        end else begin
        app_rdy     <= $random;
        app_wdf_rdy <= $random;
        if (has_data) begin
            if (~get_data) begin
                has_data <= 1'b1;
            end else begin
                has_data <= $random;
            end
        end else begin
            has_data <= $random;
        end
        if (get_data & resetn) begin
            data_in[127:64] <= $random;
            data_in[63:0]   <= $random;
            adx_in  <= adx_in  + 26'd16;
        end
        end
    end
    
    
    always @(posedge clk) begin
        if (clkCount >= MAX_CLOCKS) begin
            $finish;
        end
        if (clkCount >= 4) begin
            resetn = 1;
        end else begin
            resetn = 0;
        end
    end
    
    always #(1) clk = ~clk;
    
    

endmodule