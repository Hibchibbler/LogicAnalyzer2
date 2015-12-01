`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// 
//////////////////////////////////////////////////////////////////////////////////


module command_control
(
    input  wire       clk,
    input  wire       reset,
    
    input  wire       interrupt,
    output wire [7:0] port_id,
    output wire [7:0] port_out,
    input  wire [7:0] port_in,
    output wire       write_strobe,
    output wire       kwrite_strobe,
    output wire       read_strobe,
    output wire       interrupt_ack
    
);
    
    
    wire    [11:0]  address;
    wire    [17:0]  instruction;
    wire            bram_enable;        
    wire            kcpsm6_reset;
    wire            rdl;

    
    assign kcpsm6_reset = reset | rdl;
       
    kcpsm6 #(
        .interrupt_vector    (12'h3FF),
        .scratch_pad_memory_size(64),
        .hwbuild        (8'h00))
    processor (
        .address        (address),          //o
        .instruction    (instruction),      //i
        .bram_enable    (bram_enable),      //o
        
        .in_port        (port_in),          //i
        .out_port       (port_out),         //o
        .port_id        (port_id),          //o
        .write_strobe   (write_strobe),     //o
        .k_write_strobe (k_write_strobe),   //o
        
        .read_strobe    (read_strobe),      //o
        
        .interrupt      (interrupt),        //i
        .interrupt_ack  (interrupt_ack),    //o
        .sleep          (1'b0),             //i
        .reset          (kcpsm6_reset),     //i
        .clk            (clk)               //i
    
    ); 
      
    CCprog_Notes3    
     #(
        .C_FAMILY            ("7S"),        //Family (Virtex-7 == 7S)
        .C_RAM_SIZE_KWORDS   (2),           //Program size '1', '2' or '4'
        .C_JTAG_LOADER_ENABLE(0))           //Include JTAG Loader when set to 1'b1 
    program_rom (                          //Name to match your PSM file
         .rdl                (rdl),
        .enable              (bram_enable),
        .address             (address),
        .instruction         (instruction),
        .clk                 (clk)
    );

endmodule
