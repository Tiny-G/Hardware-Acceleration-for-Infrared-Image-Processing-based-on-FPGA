`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/17 13:13:40
// Design Name: 
// Module Name: initial_3raws_async_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module initial_3raws_async_fifo
#(
    parameter P_DATA_WIDTH = 8 ,
    parameter P_FIFO_DEPTH = 1  
)
(
    input                       i_clk   ,
    input                       i_rst_n ,

    input                       wr_en1  ,
    input   [P_DATA_WIDTH-1:0]  din1    ,
    input                       rd_en1  ,
    output  [P_DATA_WIDTH-1:0]  dout1   ,
    output                      full1   ,
    output                      empty1  ,

    input                       wr_en2  ,
    input   [P_DATA_WIDTH-1:0]  din2    ,
    input                       rd_en2  ,
    output  [P_DATA_WIDTH-1:0]  dout2   ,
    output                      full2   ,
    output                      empty2
);

custom_xpm_fifo_async #(
    .P_ASYNC_FIFO_WRITE_WIDTH ( P_DATA_WIDTH ),
    .P_ASYNC_FIFO_WRITE_DEPTH ( P_FIFO_DEPTH ),
    .P_ASYNC_FIFO_READ_WIDTH  ( P_DATA_WIDTH ),
    .P_FIFO_READ_LATENCY      (0             ),
    .P_READ_MODE              ("std"         )
)
custom_xpm_fifo_async_U0(
    .wr_clk                   ( i_clk         ),
    .rst_n                    ( i_rst_n       ),
    .full                     ( full1         ),
    .wr_en                    ( wr_en1        ),
    .din                      ( din1          ),
    .wr_rst_busy              (               ),
    .rd_clk                   ( i_clk         ),
    .rd_en                    ( rd_en1        ),
    .dout                     ( dout1         ),
    .empty                    ( empty1        ),
    .rd_rst_busy              (               )
);

custom_xpm_fifo_async #(
    .P_ASYNC_FIFO_WRITE_WIDTH ( P_DATA_WIDTH ),
    .P_ASYNC_FIFO_WRITE_DEPTH ( P_FIFO_DEPTH ),
    .P_ASYNC_FIFO_READ_WIDTH  ( P_DATA_WIDTH ),
    .P_FIFO_READ_LATENCY      (0             ),
    .P_READ_MODE              ("std"         )
)
custom_xpm_fifo_async_U1(
    .wr_clk                   ( i_clk         ),
    .rst_n                    ( i_rst_n       ),
    .full                     ( full2         ),
    .wr_en                    ( wr_en2        ),
    .din                      ( din2          ),
    .wr_rst_busy              (               ),
    .rd_clk                   ( i_clk         ),
    .rd_en                    ( rd_en2        ),
    .dout                     ( dout2         ),
    .empty                    ( empty2        ),
    .rd_rst_busy              (               )
);
endmodule
