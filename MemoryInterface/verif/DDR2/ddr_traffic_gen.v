`timescale 1ps/100fs

module ddr_traffic_gen (
    input clk,
    input resetn,
    input enable,
    
    // Input from FIFO
    input write_allowed,
    input read_allowed,
    input reads_pending,
    input writes_pending,

    // Output to FIFO
    //writes 
    output reg write_req,
    output reg read_req,
    output reg [127:0] write_data,
    output reg [26:0]  address,
    output reg mode
    
);

parameter SAMPLE_SIZE = 101;
localparam WRITE_MODE = 1'b0, READ_MODE = 1'b1;

reg [31:0] sample_num;

localparam IDLE = 2'b00, WRITING = 2'b01, RST_CNTR = 2'b10, READING = 2'b11;

reg [1:0] state, nextState;
always @(posedge clk) begin
    if (~resetn) begin
        state <= IDLE;
    end else begin
        state <= nextState;
    end
end

reg trace_complete;

reg [15:0] w0,w1,w2,w3,w4,w5,w6,w7;

always @(*) begin
    w0 = sample_num*8;
    w1 = sample_num*8 + 16'd1;
    w2 = sample_num*8 + 16'd2;
    w3 = sample_num*8 + 16'd3;
    w4 = sample_num*8 + 16'd4;
    w5 = sample_num*8 + 16'd5;
    w6 = sample_num*8 + 16'd6;
    w7 = sample_num*8 + 16'd7;
    case(state)
        IDLE:     begin
                    write_req  = 1'b0;
                    read_req   = 1'b0;
                    write_data = 128'd0;
                    address    = 27'd0;
                    mode       = WRITE_MODE;
                  end
        WRITING:  begin
                    write_req  = write_allowed & ~trace_complete;
                    read_req   = 1'b0;
                    write_data = {w7,w6,w5,w4,w3,w2,w1,w0};
                    address    = sample_num*8;
                    mode       = WRITE_MODE;
                  end
        RST_CNTR: begin
                    write_req  = 1'b0;
                    read_req   = 1'b0;
                    write_data = 128'd0;
                    address    = 27'd0;
                    mode       = READ_MODE;
                  end
        READING:  begin
                    write_req  = 1'b0;
                    read_req   = read_allowed & ~trace_complete;
                    write_data = 128'd0;
                    address    = sample_num*8;
                    mode       = READ_MODE;
                  end    
    endcase
end

always @(posedge clk) begin
    if (~resetn) begin
        sample_num     <= 32'd0;
        trace_complete <= 1'b0;
    end else begin
        case(state)
            IDLE:     begin
                        sample_num     <= 32'd0;
                        trace_complete <= 32'd0;
                      end
            WRITING:  begin
                        if (sample_num == SAMPLE_SIZE*2-1) begin
                            trace_complete <= 1'b1;
                        end else begin
                            trace_complete <= trace_complete;
                        end
                        if (write_allowed & ~trace_complete) begin
                            sample_num <= sample_num + 32'd1;
                        end else begin
                            sample_num <= sample_num;
                        end
                      end
            RST_CNTR: begin
                        sample_num     <= 32'd0;
                        trace_complete <= 32'd0;
                      end
            READING:  begin
                        if (sample_num == SAMPLE_SIZE*2-1) begin
                            trace_complete <= 1'b1;
                        end else begin
                            trace_complete <= trace_complete;
                        end
                        if (read_allowed & ~trace_complete) begin
                            sample_num <= sample_num + 32'd1;                        
                        end else begin 
                            sample_num <= sample_num;                        
                        end
                      end
        endcase
    end
end

always @(*) begin
    case(state)
        IDLE:     begin
                    if (enable) begin
                        nextState = WRITING;
                    end else begin
                        nextState = IDLE;
                    end
                  end
        WRITING:  begin
                    if (trace_complete & ~writes_pending) begin
                        nextState = RST_CNTR;
                    end else begin
                        nextState = WRITING;
                    end
                  end
        RST_CNTR: nextState = READING;
        READING:  begin
                    if (trace_complete & ~reads_pending) begin
                        nextState = IDLE;
                    end else begin
                        nextState = READING;
                    end
                  end
    endcase
end

endmodule