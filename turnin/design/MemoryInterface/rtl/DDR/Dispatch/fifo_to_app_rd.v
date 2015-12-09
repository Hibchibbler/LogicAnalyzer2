/* fifo_to_app_rd.v - The module pulls read commands
 * from the read fifo and dispatches them to the memory
 * controller.
 *
 * Brandon Mousseau bam7@pdx.edu
 */
`timescale 1ps/100fs
module fifo_to_app_rd (
    input clk,
    input resetn,
    
    input mode,
    
    input [26:0] read_adx_in,
    input        has_rd_req,
    output reg   get_rd_adr,
    
    // to application
    output reg [26:0] address_out,
    output reg app_en,
    output reg app_wdf_end,
    output reg app_wdf_wren,
    output reg [2:0] app_cmd,
    
    // From DDR controller
    input app_rdy
);

localparam IDLE = 1'b0, SEND = 1'b1;
localparam WRITE_CMD = 3'b000, READ_CMD = 3'b001;

reg state, nextState;

always @(posedge clk) begin
    if (~resetn) begin
        state <= IDLE;
    end else begin
        state <= nextState;
    end
end

always @(*) begin
    case(state)
        IDLE: if (has_rd_req & mode) begin
                nextState = SEND;
              end else begin
                nextState = IDLE;
              end
        SEND: if (app_rdy) begin
                if (has_rd_req) begin
                    nextState = SEND;
                end else begin
                    nextState = IDLE;
                end
              end else begin
                nextState = SEND;
              end
    endcase
end

always @(*) begin
    app_en       = 1'b0;
    app_wdf_end  = 1'b0;
    app_wdf_wren = 1'b0;
    app_cmd      = READ_CMD;
    address_out  = 27'd0;
    get_rd_adr   = 1'b0;
    case(state)
        IDLE: begin
                get_rd_adr = has_rd_req & mode;
              end
        SEND: begin
                address_out = read_adx_in;
                app_en      = 1'b1;
                get_rd_adr  = app_rdy & has_rd_req;
              end
    endcase
end

endmodule