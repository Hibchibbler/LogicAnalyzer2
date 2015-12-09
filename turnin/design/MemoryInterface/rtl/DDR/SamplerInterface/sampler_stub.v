/* sampler_stub.v - Module provides dummy sample data for use with testing.
 *
 * Brandon Mousseau bam7@pdx.edu
 */

module sampler_stub (
    input clk,
    input resetn,
    
    input enable,
    
    output reg [31:0] sample_num,
    output     [15:0] sample,
    output reg we,
    
    output reg read_req,
    output reg [26:0] adx,
    
    output reg mode,
    input reads_pending,
    input read_allowed,
    input writes_pending
);



parameter SAMPLE_SIZE = 2560;
localparam WRITE_MODE = 1'b0, READ_MODE = 1'b1;

localparam IDLE = 2'b00, WRITING = 2'b01, RST_CNTR = 2'b10, READING = 2'b11;

reg [1:0] state, nextState;
always @(posedge clk) begin
    if (~resetn) begin
        state <= IDLE;
    end else begin
        state <= nextState;
    end
end

assign sample = sample_num[15:0];

reg trace_complete;

always @(*) begin
    adx    = 27'd0;
    read_req   = 1'b0;
    we         = 1'b0;
    case(state)
        IDLE:     begin
                    mode       = WRITE_MODE;
                  end
        WRITING:  begin
                    we         = ~trace_complete;
                    mode       = WRITE_MODE;
                  end
        RST_CNTR: begin
                    mode       = READ_MODE;
                  end
        READING:  begin
                    read_req   = read_allowed & ~trace_complete;
                    mode       = READ_MODE;
                    adx        = sample_num*8;
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
                        if (sample_num == SAMPLE_SIZE-1) begin
                            trace_complete <= 1'b1;
                        end else begin
                            trace_complete <= trace_complete;
                        end
                        if (~trace_complete) begin
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
                        if (sample_num == SAMPLE_SIZE/8-1) begin
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