/* fifo_to_app_wr.v - Module dispatches queued up 
 * write commands and transmits them to the ddr controller.
 *
 * Brandon Mousseau bam7@pdx.edu
 */

`timescale 1ps/100fs
module fifo_to_app_wr (
    input clk,
    input resetn,
    
    // From ddr_fifo
    input has_wr_data,
    input has_wr_adx,
    input [127:0] write_data_in,
    input [26:0]  address_in,
    
    // To DDR controller
    output reg [63:0] write_data_out,
    output reg [26:0] address_out,
    output reg app_en,
    output reg app_wdf_end,
    output reg app_wdf_wren,
    output     [2:0] app_cmd,
    
    // From DDR controller
    input app_rdy,
    input app_wdf_rdy,
    
    // To ddr_fifo
    output reg get_wr_data,
    output reg get_wr_adx
);

localparam IDLE = 2'b00, CHUNK1 = 2'b10, CHUNK2 = 2'b11;
localparam WRITE_CMD = 3'b000, READ_CMD = 3'b000;

reg [1:0] dState, dNextState, aState, aNextState;

assign app_cmd = WRITE_CMD;

// Sequential Logic
// Tracking two separate state machines
// for clocking in the write data and the
// address/cmd separately
always @(posedge clk) begin
    if (~resetn) begin
        dState <= IDLE;
        aState <= IDLE;
    end else begin
        dState <= dNextState;
        aState <= aNextState;
    end
end

// DATA managing state machine - next state calculation
always @(*) begin
    dNextState = IDLE;
    case(dState)
        IDLE:     begin
                    if (has_wr_data) begin
                        dNextState = CHUNK1;
                    end else begin
                        dNextState = IDLE;
                    end
                  end
        CHUNK1:   begin
                    if (app_wdf_rdy) begin
                        dNextState = CHUNK2;
                    end else begin
                        dNextState = CHUNK1;
                    end
                  end
        CHUNK2:   begin
                    if (app_wdf_rdy) begin
                        if (has_wr_data) begin 
                            dNextState = CHUNK1;
                        end else begin
                            dNextState = IDLE;
                        end
                    end else begin
                        dNextState = CHUNK2;
                    end
                  end
    endcase
end

// Data managing state machine - output calculation
always @(*) begin
    app_wdf_wren   = 1'b0;
    app_wdf_end    = 1'b0;
    get_wr_data    = 1'b0;
    write_data_out = 64'hFFFFFFFFFFFFFFFF;
    case(dState)
        IDLE:    get_wr_data  = has_wr_data;
        CHUNK1:  begin
                    app_wdf_wren = 1'b1;
                    write_data_out = write_data_in[63:0];
                 end
        CHUNK2:  begin
                    get_wr_data  = has_wr_data & app_wdf_rdy;
                    app_wdf_wren = 1'b1;
                    app_wdf_end  = 1'b1;
                    write_data_out = write_data_in[127:64];
                 end
    endcase
end

// ADDRESS managing state machine
always @(*) begin
    aNextState = IDLE;
    case(aState)
        IDLE:     begin
                    if (has_wr_adx) begin
                        aNextState = CHUNK1;
                    end else begin
                        aNextState = IDLE;
                    end
                  end
        CHUNK1:     begin
                    if (app_rdy) begin
                        if (has_wr_adx) begin
                            aNextState = CHUNK1;
                        end else begin
                            aNextState = IDLE;
                        end
                    end else begin
                        aNextState = CHUNK1;
                    end
                  end
    endcase
end

//Address managing state machine - output calculation
always @(*) begin
    get_wr_adx  = 1'b0;
    app_en      = 1'b0;
    address_out = 27'b111111111111111111111111111;
    case(aState)
        IDLE:       get_wr_adx = has_wr_adx;
        CHUNK1: begin
                  app_en = 1'b1;
                  address_out = {address_in[26:3], 3'b000};
                  get_wr_adx = has_wr_adx & app_rdy;
                end
    endcase
end


endmodule