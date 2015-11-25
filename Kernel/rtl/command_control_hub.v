module  command_control_hub
(
    input  wire       clk,
    input  wire       reset,
    
    //Nexys4 IO Peripherals
    output reg [15:0] led,
    input wire  [7:0] button,
    input wire [15:0] switch,
    
    //Command & Control
    output wire       interrupt,
    input  wire       interrupt_ack,
    input  wire [7:0] port_id,
    input  wire [7:0] port_out,
    output reg  [7:0] port_in,
    input  wire       write_strobe,
    input  wire       kwrite_strobe,
    input  wire       read_strobe,
    
    //UART Receive
    input  wire [7:0] data_out,
    input  wire       urx_buffer_full,
    input  wire       urx_buffer_half_full,
    input  wire       urx_buffer_data_present,
    output reg        urx_buffer_read,
    
    //UART Transmit
    output wire [7:0] data_in,
    input  wire       utx_buffer_full,
    input  wire       utx_buffer_half_full,
    input  wire       utx_buffer_data_present,
    output wire       utx_buffer_write
    
);

    
//    always @(posedge clk)
//        interrupt <= 1'b0;
    localparam  PA_READ_HUB_REGISTER0   = 8'h00,
                PA_READ_HUB_REGISTER1   = 8'h01,
                PA_READ_HUB_REGISTER2   = 8'h02,
                PA_READ_HUB_REGISTER3   = 8'h03,
                PA_READ_HUB_REGISTER4   = 8'h04,
                PA_READ_HUB_REGISTER5   = 8'h05,
                PA_READ_HUB_REGISTER6   = 8'h06,
                PA_READ_HUB_REGISTER7   = 8'h07,
                
                PA_READ_UART_DATA       = 8'h09,
                PA_READ_UART_STATUS     = 8'h0A,
                PA_READ_SWITCHES_7_0    = 8'h0B,
                PA_READ_SWITCHES_15_8   = 8'h0C,
                PA_READ_BUTTONS         = 8'h0D;    


    localparam  PA_WRITE_HUB_REGISTER0  = 8'h00,
                PA_WRITE_HUB_REGISTER1  = 8'h01,
                PA_WRITE_HUB_REGISTER2  = 8'h02,
                PA_WRITE_HUB_REGISTER3  = 8'h03,
                PA_WRITE_HUB_REGISTER4  = 8'h04,
                PA_WRITE_HUB_REGISTER5  = 8'h05,
                PA_WRITE_HUB_REGISTER6  = 8'h06,
                PA_WRITE_HUB_REGISTER7  = 8'h07,
                PA_WRITE_LOGCAP         = 8'h08,
                PA_WRITE_UART_DATA      = 8'h09,
                PA_WRITE_LED_7_0        = 8'h0A,
                PA_WRITE_LED_15_8       = 8'h0B;
    
    //The Hub Registers
    reg [7:0] hub_registers[7:0];

    //General Writes    
    always @(posedge clk) begin
        if (reset == 1'b1) begin
            led <= 16'b0;
            hub_registers[0] <= 8'b0;
            hub_registers[1] <= 8'b0;
            hub_registers[2] <= 8'b0;
            hub_registers[3] <= 8'b0;
            hub_registers[4] <= 8'b0;
            hub_registers[5] <= 8'b0;
            hub_registers[6] <= 8'b0;
            hub_registers[7] <= 8'b0;
        end else begin
            if (write_strobe == 1'b1) begin
                case (port_id[3:0])
                    PA_WRITE_HUB_REGISTER0: hub_registers[0] <= port_out;
                    PA_WRITE_HUB_REGISTER1: hub_registers[1] <= port_out;
                    PA_WRITE_HUB_REGISTER2: hub_registers[2] <= port_out;
                    PA_WRITE_HUB_REGISTER3: hub_registers[3] <= port_out;
                    PA_WRITE_HUB_REGISTER4: hub_registers[4] <= port_out;
                    PA_WRITE_HUB_REGISTER5: hub_registers[5] <= port_out;
                    PA_WRITE_HUB_REGISTER6: hub_registers[6] <= port_out;
                    PA_WRITE_HUB_REGISTER7: hub_registers[7] <= port_out;
                    //PA_WRITE_LOGCAP: - not yet...
                    //PA_WRITE_UART_DATA Is handled combinationally.
                    PA_WRITE_LED_7_0:  led[7:0]  <= port_out;
                    PA_WRITE_LED_15_8: led[15:8] <= port_out;
                    default: led <= led;
                endcase
            end
        end
    end
    
    //UART Writes - combinationally
    assign utx_buffer_write =  write_strobe && (port_id == PA_WRITE_UART_DATA);
    assign data_in = port_out;    
    

    //General Reads
    always @(posedge clk) begin
        case (port_id[3:0])
            PA_READ_HUB_REGISTER0:  port_in <= hub_registers[0];
            PA_READ_HUB_REGISTER1:  port_in <= hub_registers[1];
            PA_READ_HUB_REGISTER2:  port_in <= hub_registers[2];
            PA_READ_HUB_REGISTER3:  port_in <= hub_registers[3];
            PA_READ_HUB_REGISTER4:  port_in <= hub_registers[4];
            PA_READ_HUB_REGISTER5:  port_in <= hub_registers[5];
            PA_READ_HUB_REGISTER6:  port_in <= hub_registers[6];
            PA_READ_HUB_REGISTER7:  port_in <= hub_registers[7];
            PA_READ_UART_DATA:      port_in <= data_out;
            PA_READ_UART_STATUS:    port_in <= {2'b00, 
                                                urx_buffer_full, 
                                                urx_buffer_half_full, 
                                                urx_buffer_data_present, 
                                                utx_buffer_full, 
                                                utx_buffer_half_full, 
                                                utx_buffer_data_present};
            PA_READ_SWITCHES_7_0:   port_in <= switch[7:0];
            PA_READ_SWITCHES_15_8:  port_in <= switch[15:8];        
            PA_READ_BUTTONS:        port_in <= button;    
            default:                port_in <= 8'bXXXXXXXX;
        endcase
    end
    
    
    //UART Read strobe is registered.
    always @(posedge clk) begin
        if (reset == 1'b1)
            urx_buffer_read <= 1'b0; 
        else begin
            if ((read_strobe == 1'b1) && (port_id == PA_READ_UART_DATA)) begin
                urx_buffer_read <= 1'b1;
            end else begin
                urx_buffer_read <= 1'b0;
            end       
        end 
    end

    //Generate an Interrupt every second for Command&Control(100MHz clk)

    interrupt_gen ig
    (
        //Input
        .clk(clk),
        .reset(reset),
        //Output
        .interrupt1s(interrupt)
    );
    
    
endmodule