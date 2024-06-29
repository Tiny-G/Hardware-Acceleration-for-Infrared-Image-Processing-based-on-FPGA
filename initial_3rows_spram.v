`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/09 20:36:13
// Design Name: 
// Module Name: initial_3rows_tdram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 初始化2个1行*数据位宽大小的TDRAM,用来放置图像数据
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module initial_3rows_spram
#(
    parameter P_ROW_WIDTH  = 256,
    parameter P_DATA_WIDTH = 8  ,
    parameter P_ADDR_WIDTH = 12
)
(
    input                           clka1   ,
    input                           rsta_n1 ,
    input   [P_ADDR_WIDTH-1:0]      addra1  ,
    input                           wea1    ,
    input   [P_DATA_WIDTH-1:0]      dina1   ,
    output  [P_DATA_WIDTH-1:0]      douta1  ,
    input                           ena1    ,

    input                           clka2   ,
    input                           rsta_n2 ,
    input   [P_ADDR_WIDTH-1:0]      addra2  ,
    input                           wea2    ,
    input   [P_DATA_WIDTH-1:0]      dina2   ,
    output  [P_DATA_WIDTH-1:0]      douta2  ,
    input                           ena2     
);

custom_xpm_spram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH         )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH          )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH         )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH         )   
)custom_xpm_spram_U0(
    .clka                 (clka1                )   ,
    .rsta_n               (rsta_n1              )   ,
    .addra                (addra1               )   ,
    .wea                  (wea1                 )   ,
    .dina                 (dina1                )   ,
    .douta                (douta1               )   ,
    .ena                  (ena1                 )   
);

custom_xpm_spram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH         )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH          )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH         )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH         )   
)custom_xpm_spram_U1(
    .clka                 (clka2                )   ,
    .rsta_n               (rsta_n2              )   ,
    .addra                (addra2               )   ,
    .wea                  (wea2                 )   ,
    .dina                 (dina2                )   ,
    .douta                (douta2               )   ,
    .ena                  (ena2                 )   
);

endmodule
