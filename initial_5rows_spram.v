`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/09 20:36:13
// Design Name: 
// Module Name: initial_5rows_tdram
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


module initial_5rows_spram
#(
    parameter P_ROW_WIDTH  = 256,
    parameter P_DATA_WIDTH = 8  ,
    parameter P_ADDR_WIDTH = 11
)
(
    input                           clka1   ,
    input                           rsta_n1 ,
    input   [P_ADDR_WIDTH-1:0]      addra1  ,
    input                           wea1    ,
    input   [P_DATA_WIDTH-1:0]      dina1   ,
    output  [P_DATA_WIDTH-1:0]      douta1  ,
    output                          ena1    ,

    input                           clka2   ,
    input                           rsta_n2 ,
    input   [P_ADDR_WIDTH-1:0]      addra2  ,
    input                           wea2    ,
    input   [P_DATA_WIDTH-1:0]      dina2   ,
    output  [P_DATA_WIDTH-1:0]      douta2  ,
    output                          ena2    ,

    input                           clka3   ,
    input                           rsta_n3 ,
    input   [P_ADDR_WIDTH-1:0]      addra3  ,
    input                           wea3    ,
    input   [P_DATA_WIDTH-1:0]      dina3   ,
    output  [P_DATA_WIDTH-1:0]      douta3  ,
    output                          ena3    ,

    input                           clka4   ,
    input                           rsta_n4 ,
    input   [P_ADDR_WIDTH-1:0]      addra4  ,
    input                           wea4    ,
    input   [P_DATA_WIDTH-1:0]      dina4   ,
    output  [P_DATA_WIDTH-1:0]      douta4  ,
    output                          ena4     

);

custom_xpm_spram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH         )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH          )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH         )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH         )   
)custom_xpm_spram_U2(
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
)custom_xpm_spram_U3(
    .clka                 (clka2                )   ,
    .rsta_n               (rsta_n2              )   ,
    .addra                (addra2               )   ,
    .wea                  (wea2                 )   ,
    .dina                 (dina2                )   ,
    .douta                (douta2               )   ,
    .ena                  (ena2                 )   
);

custom_xpm_spram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH         )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH          )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH         )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH         )   
)custom_xpm_spram_U4(
    .clka                 (clka3                )   ,
    .rsta_n               (rsta_n3              )   ,
    .addra                (addra3               )   ,
    .wea                  (wea3                 )   ,
    .dina                 (dina3                )   ,
    .douta                (douta3               )   ,
    .ena                  (ena3                 )   
);

custom_xpm_spram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH         )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH          )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH         )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH         )   
)custom_xpm_spram_U5(
    .clka                 (clka4                )   ,
    .rsta_n               (rsta_n4              )   ,
    .addra                (addra4               )   ,
    .wea                  (wea4                 )   ,
    .dina                 (dina4                )   ,
    .douta                (douta4               )   ,
    .ena                  (ena4                 )   
);

endmodule
