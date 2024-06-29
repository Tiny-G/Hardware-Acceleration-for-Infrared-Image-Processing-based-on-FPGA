`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/13 16:02:17
// Design Name: 
// Module Name: initial_1row_tdram
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


module initial_1row_tdram#(
    parameter P_ROW_WIDTH  = 256,
    parameter P_DATA_WIDTH = 8  ,
    parameter P_ADDR_WIDTH = 12
)
(
    input                           i_clk   ,
    input                           i_rst_n ,

    input   [P_ADDR_WIDTH-1:0]      addra1  ,
    input                           wea1    ,
    input   [P_DATA_WIDTH-1:0]      dina1   ,
    input   [P_ADDR_WIDTH-1:0]      addrb1  ,
    output  [P_DATA_WIDTH-1:0]      doutb1  ,
    input                           enb1   
);

localparam         P_CLOCKING_MODE = "common_clock" ;


custom_xpm_tdram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH  )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH )   ,
    .P_WRITE_DATA_WIDTH_B (P_DATA_WIDTH )   ,
    .P_READ_DATA_WIDTH_B  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_B       (P_ADDR_WIDTH )   ,
    .P_CLOCKING_MODE      (P_CLOCKING_MODE)
)custom_xpm_tdram_U6(
    .clka                 (i_clk        )   ,
    .rsta_n               (i_rst_n      )   ,
    .addra                (addra1       )   ,
    .wea                  (wea1         )   ,
    .dina                 (dina1        )   ,
    .clkb                 (i_clk        )   ,
    .rstb_n               (i_rst_n      )   ,
    .addrb                (addrb1       )   ,
    .doutb                (doutb1       )   ,
    .enb                  (enb1         )   
);

endmodule
