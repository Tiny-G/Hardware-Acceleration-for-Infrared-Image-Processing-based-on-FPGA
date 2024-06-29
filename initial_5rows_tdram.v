`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/09 23:12:03
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


module initial_5rows_tdram
#(
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
    input                           enb1    ,  

    input   [P_ADDR_WIDTH-1:0]      addra2  ,
    input                           wea2    ,
    input   [P_DATA_WIDTH-1:0]      dina2   ,
    input   [P_ADDR_WIDTH-1:0]      addrb2  ,
    output  [P_DATA_WIDTH-1:0]      doutb2  ,
    input                           enb2    ,

    input   [P_ADDR_WIDTH-1:0]      addra3  ,
    input                           wea3    ,
    input   [P_DATA_WIDTH-1:0]      dina3   ,
    input   [P_ADDR_WIDTH-1:0]      addrb3  ,
    output  [P_DATA_WIDTH-1:0]      doutb3  ,
    input                           enb3    ,

    input   [P_ADDR_WIDTH-1:0]      addra4  ,
    input                           wea4    ,
    input   [P_DATA_WIDTH-1:0]      dina4   ,
    input   [P_ADDR_WIDTH-1:0]      addrb4  ,
    output  [P_DATA_WIDTH-1:0]      doutb4  ,
    input                           enb4     
);

custom_xpm_tdram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH  )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH )   ,
    .P_WRITE_DATA_WIDTH_B (P_DATA_WIDTH )   ,
    .P_READ_DATA_WIDTH_B  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_B       (P_ADDR_WIDTH )   ,
    .P_CLOCKING_MODE      ("common_clock")
)custom_xpm_tdram_U2(
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

custom_xpm_tdram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH  )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH )   ,
    .P_WRITE_DATA_WIDTH_B (P_DATA_WIDTH )   ,
    .P_READ_DATA_WIDTH_B  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_B       (P_ADDR_WIDTH )   ,
    .P_CLOCKING_MODE      ("common_clock")
)custom_xpm_tdram_U3(
    .clka                 (i_clk        )   ,
    .rsta_n               (i_rst_n      )   ,
    .addra                (addra2       )   ,
    .wea                  (wea2         )   ,
    .dina                 (dina2        )   ,
    .clkb                 (i_clk        )   ,
    .rstb_n               (i_rst_n      )   ,
    .addrb                (addrb2       )   ,
    .doutb                (doutb2       )   ,
    .enb                  (enb2         )  
);

custom_xpm_tdram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH  )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH )   ,
    .P_WRITE_DATA_WIDTH_B (P_DATA_WIDTH )   ,
    .P_READ_DATA_WIDTH_B  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_B       (P_ADDR_WIDTH )   ,
    .P_CLOCKING_MODE      ("common_clock")
)custom_xpm_tdram_U4(
    .clka                 (i_clk        )   ,
    .rsta_n               (i_rst_n      )   ,
    .addra                (addra3       )   ,
    .wea                  (wea3         )   ,
    .dina                 (dina3        )   ,
    .clkb                 (i_clk        )   ,
    .rstb_n               (i_rst_n      )   ,
    .addrb                (addrb3       )   ,
    .doutb                (doutb3       )   ,
    .enb                  (enb3         )  
);

custom_xpm_tdram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH )   ,
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH  )   ,
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH )   ,
    .P_WRITE_DATA_WIDTH_B (P_DATA_WIDTH )   ,
    .P_READ_DATA_WIDTH_B  (P_DATA_WIDTH )   ,
    .P_ADDR_WIDTH_B       (P_ADDR_WIDTH )   ,
    .P_CLOCKING_MODE      ("common_clock")
)custom_xpm_tdram_U5(
    .clka                 (i_clk        )   ,
    .rsta_n               (i_rst_n      )   ,
    .addra                (addra4       )   ,
    .wea                  (wea4         )   ,
    .dina                 (dina4        )   ,
    .clkb                 (i_clk        )   ,
    .rstb_n               (i_rst_n      )   ,
    .addrb                (addrb4       )   ,
    .doutb                (doutb4       )   ,
    .enb                  (enb4         )  
);
endmodule
