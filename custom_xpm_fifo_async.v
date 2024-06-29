`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/09 17:31:41
// Design Name: 
// Module Name: custom_xpm_fifo_async
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// keep most of parameters same as xpm_fifo_async, but reduce useless parameters
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module custom_xpm_fifo_async#(
    parameter           P_ASYNC_FIFO_WRITE_WIDTH    =  32       ,
    parameter           P_ASYNC_FIFO_WRITE_DEPTH    =  2048     ,
    parameter           P_ASYNC_FIFO_READ_WIDTH     =  32       ,
    parameter           P_FIFO_READ_LATENCY         =  0        ,
    parameter           P_READ_MODE                 =  "fwft"    //fwft, std

)
(   
    input                                           rst_n       ,
    // Write interface
    input                                           wr_clk      ,
    input                                           full        ,
    input                                           wr_en       ,  
    input   [P_ASYNC_FIFO_WRITE_WIDTH-1:0]          din         ,
    output                                          wr_rst_busy ,
    //Read interface
    input                                           rd_clk      ,
    input                                           rd_en       ,
    output  [P_ASYNC_FIFO_READ_WIDTH-1:0]           dout        ,
    output                                          empty       ,
    output                                          rd_rst_busy 
    
);

xpm_fifo_async #(
    .CDC_SYNC_STAGES        (2          )   ,// DECIMAL
    .DOUT_RESET_VALUE       ("0"        )   ,// String
    .ECC_MODE               ("no_ecc"   )   ,// String
    .FIFO_MEMORY_TYPE       ("auto"     )   ,// String
    .FIFO_READ_LATENCY      (P_FIFO_READ_LATENCY)   ,// DECIMAL
    .FIFO_WRITE_DEPTH       (P_ASYNC_FIFO_WRITE_DEPTH)   ,// DECIMAL
    .FULL_RESET_VALUE       (0          )   ,// DECIMAL
    .PROG_EMPTY_THRESH      (10         )   ,// DECIMAL
    .PROG_FULL_THRESH       (10         )   ,// DECIMAL
    .RD_DATA_COUNT_WIDTH    (1          )   ,// DECIMAL
    .READ_DATA_WIDTH        (P_ASYNC_FIFO_READ_WIDTH)   ,// DECIMAL
    // .READ_MODE              ("fwft"     )   ,// String
    .READ_MODE              (P_READ_MODE)   ,// String
    .RELATED_CLOCKS         (0          )   ,// DECIMAL
    .USE_ADV_FEATURES       ("0707"     )   ,// String
    .WAKEUP_TIME            (0          )   ,// DECIMAL
    .WRITE_DATA_WIDTH       (P_ASYNC_FIFO_WRITE_WIDTH)   ,// DECIMAL
    .WR_DATA_COUNT_WIDTH    (1          )    // DECIMAL
)
xpm_fifo_async_inst 
(
    .almost_empty           (           )   ,   
    .almost_full            (           )   ,
    .data_valid             (           )   ,
    .dbiterr                (           )   ,
    .dout                   (dout       )   ,
    .empty                  (empty      )   ,
    .full                   (full       )   ,
    .overflow               (           )   , 
    .prog_empty             (           )   ,
    .prog_full              (           )   , 
    .rd_data_count          (           )   , 
    .rd_rst_busy            (rd_rst_busy)   ,
    .sbiterr                (           )   ,
    .underflow              (           )   ,
    .wr_ack                 (           )   ,
    .wr_data_count          (           )   , 
    .wr_rst_busy            (wr_rst_busy)   ,
    .din                    (din        )   ,
    .injectdbiterr          (1'b0       )   ,
    .injectsbiterr          (1'b0       )   ,
    .rd_clk                 (rd_clk     )   ,
    .rd_en                  (rd_en      )   ,
    .rst                    (!rst_n     )   ,
    .sleep                  (1'b0      )   ,
    .wr_clk                 (wr_clk     )   ,
    .wr_en                  (wr_en      )
);
endmodule
