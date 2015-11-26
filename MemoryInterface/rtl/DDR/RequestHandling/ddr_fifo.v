/* ddr_fifo.v -
 * This module accepts write/read commands along
 * with address and/or data. It provides control
 * signals indicating if read or writes are legal
 * and also captures return data and makes it
 * available to a consumer.
 * 
 * Read commands will be accepted up to a maximum
 * value to ensure no more read commands are being
 * handled at a given time than there is enough local
 * buffer space to handle all the data. As return data
 * is made available and read back by a consumer, this
 * will free up space and enable additional read commands.
 * 
 * This module encapsulates FIFOs for the read/write commands
 * and the returned read data.
 *
 * Brandon Mousseau bam7@pdx.edu
 */
`timescale 1ps/100fs
module ddr_fifo (
    input clk,
    input resetn,

    //  to/from traffic generator
    input  [26:0]  wr_adx_in,
    input  [127:0] wr_data_in,
    input          write_req,
    output         write_allowed,
    output         writes_pending,
    input  [26:0]  rd_adx_in,
    input          read_req,
    output         read_allowed,
    output         reads_pending,

    // To/from command dispatch
    output [127:0] wr_data_out,
    output [26:0]  wr_adx_out,
    input          get_wr_adx,
    input          get_wr_data,
    output         has_wr_adx,
    output         has_wr_data,
    output [26:0]  rd_adx_out,
    output         has_rd_req,
    input          get_rd_req,
    
    // direct from ddr_app
    input  [63:0]  app_rd_data,
    input          app_rd_data_valid,
    
    // read data for a consumer
    output [127:0] return_data,
    output [26:0]  return_adx,
    output         has_return_data,
    input          get_return_data
);

// Queues up write addresses and data
// to make available to dispatch independently
ddr_wr_fifo iwrfifo(
    .clk(clk),
    .resetn(resetn),
    // to/from traffic generator
    .wr_data_in(wr_data_in),
    .wr_adx_in(wr_adx_in),
    .write_req(write_req),
    .write_allowed(write_allowed),
    .writes_pending(writes_pending),
    // to/from command dispatch
    .get_wr_adx(get_wr_adx),
    .get_wr_data(get_wr_data),
    .wr_data_out(wr_data_out),
    .wr_adx_out(wr_adx_out),
    .has_wr_adx(has_wr_adx),
    .has_wr_data(has_wr_data)
);


// Queues up read comands and makes
// them available to comannd dispatch.
// Retrieves incoming read data and and
// returns results along with associated
// address.
ddr_rd_fifo irdfifo (
    .clk(clk),
    .resetn(resetn),
    
    // requests from traffic generation
    .read_address(rd_adx_in),
    .read_req(read_req),
    // control to traffic generation
    .read_allowed(read_allowed),
    .reads_pending(reads_pending),
    
    // Outputs to fifo_to_app module
    .f2a_app_adx(rd_adx_out),
    .f2a_has_rd_req(has_rd_req),
    .f2a_get_rd_adr(get_rd_req),
    
    // data valid signal from app
    .app_rd_data_valid(app_rd_data_valid),
    .app_rd_data(app_rd_data),
    
    // returned read data - connections
    // go to consumer of read data
    .return_data(return_data),
    .return_adx(return_adx),
    .return_data_available(has_return_data),
    .get_return_data(get_return_data)
);

endmodule