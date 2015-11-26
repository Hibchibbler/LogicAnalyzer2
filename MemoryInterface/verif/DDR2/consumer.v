`timescale 1ps/100fs

module consumer (
    input clk,
    input resetn,
    
    input has_return_data,
    output reg get_return_data,
    
    input [127:0] return_data,
    input [26:0] return_adx
);

reg [127:0] captured_data;
reg [26:0]  captured_adx;

parameter DELAY_COUNT = 4'hf;

reg [3:0] delayCntr;
reg dataAvailable;

always @(posedge clk) begin
    if (~resetn) begin
        captured_data   <= 64'd0;
        captured_adx    <= 27'd0;
        get_return_data <= 1'b0;
        delayCntr       <= 4'hf;
    end else begin
        delayCntr       <= delayCntr + 4'd1;
        get_return_data <= has_return_data & (delayCntr == 4'hf);
        dataAvailable   <=  get_return_data;
        if (dataAvailable) begin
            captured_data   <= return_data;
            captured_adx    <= return_adx;
        end else begin
            captured_data <= captured_data;
            captured_adx  <= captured_adx;
        end
    end
end


endmodule