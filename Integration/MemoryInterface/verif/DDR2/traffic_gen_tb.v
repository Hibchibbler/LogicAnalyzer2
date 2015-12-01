module traffig_gen_tb ();

    reg clk;
    reg resetn;
    reg [31:0] clkCount;
    reg write_allowed;
    reg read_allowed;
    reg writes_pending;
    reg reads_pending;
    reg enable;
    wire write_req;
    wire read_req;
    wire mode;
    
    initial begin
        $dumpfile("ddr_tester.vcd");
        $dumpvars(0,ddr_tester_tb);
        clk      = 0;
        resetn   = 0;
        clkCount = 0;
    end
    
    ddr_traffic_gen mud(
        .clk(clk),
        .enable(enable),
        .resetn(resetn),
        .write_allowed(write_allowed),
        .read_allowed(read_allowed),
        .write_req(write_req),
        .read_req(read_req),
        .writes_pending(writes_pending),
        .reads_pending(reads_pending),
        .mode(mode)
    );
    
    always @(posedge clk) begin
        clkCount <= clkCount + 1'd1;
        if (~resetn) begin
            write_allowed  <= 1'b0;
            writes_pending <= 1'b0;
            reads_pending  <= 1'b0;
            read_allowed   <= 1'b0;
        end else begin
            if (write_allowed) begin
                if (write_req) begin
                    write_allowed <= $random;
                    writes_pending <= 1'b1;
                end else begin
                    write_allowed <= 1'b1;
                    if (writes_pending) begin
                        writes_pending <= $random;
                    end else begin
                        writes_pending <= 1'b0;
                    end
                end
            end else begin
                write_allowed <= $random;
                writes_pending <= 1'b1;
            end
            if (read_allowed) begin
                if (read_req) begin
                    read_allowed <= $random;
                    reads_pending <= 1'b1;
                end else begin
                    read_allowed <= 1'b1;
                    if (reads_pending) begin
                        reads_pending <= $random;
                    end else begin
                        reads_pending <= 1'b0;
                    end
                end
            end else begin
                read_allowed <= $random;
                reads_pending <= 1'b1;
            end
        end
    end

    parameter MAX_CLOCKS = 2000;
    
    always @(posedge clk) begin
        if (clkCount >= MAX_CLOCKS) begin
            $finish;
        end
        if (clkCount >= 4) begin
            resetn = 1;
        end else begin
            resetn = 0;
        end
        if (clkCount >= 6) begin
            enable = 1;
        end else begin
            enable = 0;
        end
    end
    
    always #(1) clk = ~clk;
endmodule