module dataDumpFSM (
    input clk,
    input reset,
    
    input dumpCmd,
    input logcapAck,
    input idle,
    input has_return_data,
    
    output reg get_return_data,
    output reg load_l,
    output reg load_u
);

// States for data consumer machine
localparam IDLE = 3'b000,        WAIT_DATA   = 3'b001, LOAD_DATA_L = 3'b010,   WAIT_DEACK_L = 3'b011;
localparam WAIT_DUMP_U = 3'b100, LOAD_DATA_U = 3'b101, WAIT_DEACK_U = 3'b110,  WAIT_DUMP_L = 3'b111;

reg [2:0] state, nextState;


always @(posedge clk) begin
    if (reset) begin
        state <= IDLE;
    end else begin
        state <= nextState;
    end
end

always @(*) begin
    case(state)
        IDLE:        begin
                        if (dumpCmd & idle)
                            nextState = WAIT_DATA;
                        else
                            nextState = IDLE;
                     end
        WAIT_DATA:   begin
                        if (has_return_data)
                            nextState = LOAD_DATA_L;
                        else
                            nextState = WAIT_DATA;
                     end
        LOAD_DATA_L: begin
                        nextState = WAIT_DEACK_L;
                     end
        WAIT_DEACK_L:begin
                        if (logcapAck)
                            nextState = WAIT_DEACK_L;
                        else
                            nextState = WAIT_DUMP_U;
                     end
        WAIT_DUMP_U: begin
                        if (dumpCmd)
                            nextState = LOAD_DATA_U;
                        else
                            nextState = WAIT_DUMP_U;
                     end
        LOAD_DATA_U: begin
                        nextState = WAIT_DEACK_U;
                     end
        WAIT_DEACK_U:begin
                        if (logcapAck)
                            nextState = WAIT_DEACK_U;
                        else
                            nextState = WAIT_DUMP_L;
                     end
        WAIT_DUMP_L: begin
                        if (dumpCmd)
                            nextState = WAIT_DATA;
                        else
                            nextState = WAIT_DUMP_L;
                     end
    endcase
end

always @(*) begin
    load_l          = 1'b0;
    load_u          = 1'b0;
    get_return_data = 1'b0;
    case(state)
        IDLE:        begin
                     end
        WAIT_DATA:   begin
                        get_return_data = 1'b1;
                     end
        LOAD_DATA_L: begin
                        load_l = 1'b1;
                     end
        WAIT_DEACK_L:begin
                     end
        WAIT_DUMP_U: begin
                     end
        LOAD_DATA_U: begin
                        load_u = 1'b1;
                     end
        WAIT_DEACK_U:begin
                     end
        WAIT_DUMP_L: begin
                     end
    endcase
end

endmodule