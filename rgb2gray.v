`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/08 16:19:24
// Design Name: 
// Module Name: rgb2gray
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 默认VGA/HDMA时序，RGB2GRAY模块参考的是matlab中rgb2gray函数的实现方式，即：
// Y(gray) = 0.2989 * R + 0.5870 * G + 0.1140 * B
// 为了方便后续通用，会将rgb2gray输出Y、Cb、Cr值
// Cb = -0.1687 * R - 0.3313 * G + 0.5 * B + 128
// Cr = 0.5 * R - 0.4187 * G - 0.0813 * B + 128
// 其中Cb和Cr的范围为0~255，Y的范围为0~255
//
// gray = (306 * R + 601 * G + 117 * B)>>10
// Cb = (173 * R + 339 * G + 512 * B ) >> 10+ 128
// Cr = (512 * R - 429 * G - 83 * B ) >> 10+ 128
// Dependencies: 
// 
// Revision:0.0.1  - File Created
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rgb2gray
#(
    // 输入rgb通道位宽
    parameter                       P_RED_DEPTH      =  4'd8    ,
    parameter                       P_GREEN_DEPTH    =  4'd8    ,
    parameter                       P_BLUE_DEPTH     =  4'd8    ,
    // YCbCr系数
    parameter                       P_Y_R_factor     = 12'd306  ,   
    parameter                       P_Y_G_factor     = 12'd601  ,
    parameter                       P_Y_B_factor     = 12'd117  ,

    parameter                       P_Cb_R_factor    = 12'd173  ,
    parameter                       P_Cb_G_factor    = 12'd339  ,
    parameter                       P_Cb_B_factor    = 12'd512  ,
    parameter                       P_Cb_Const       = 8'd128   ,

    parameter                       P_Cr_R_factor    = 12'd512  ,
    parameter                       P_Cr_G_factor    = 12'd429  ,
    parameter                       P_Cr_B_factor    = 12'd83   ,
    parameter                       P_Cr_Const       = 8'd128   
    
)
(
    input                           i_clk                   ,
    input                           i_rst_n                 ,

    input   [P_RED_DEPTH-1:0]       i_red_channel           ,
    input   [P_GREEN_DEPTH-1:0]     i_green_channel         ,
    input   [P_BLUE_DEPTH-1:0]      i_blue_channel          ,
    input                           i_img_hsync             ,
    input                           i_img_vsync             ,

    output  [P_RED_DEPTH-1:0]       o_Y_channel             ,
    output  [P_GREEN_DEPTH-1:0]     o_Cb_channel            ,
    output  [P_BLUE_DEPTH-1:0]      o_Cr_channel            ,
    output                          o_img_hsync             ,
    output                          o_img_vsync        
);

localparam  P_Y_Cb_Cr_DEFAULT = 0;

// input reg
reg         [P_RED_DEPTH-1:0]       ri_red_channel          ;
reg         [P_GREEN_DEPTH-1:0]     ri_green_channel        ;
reg         [P_BLUE_DEPTH-1:0]      ri_blue_channel         ;
reg                                 ri_img_hsync            ;
reg                                 ri_img_vsync            ;

// output reg
reg         [P_RED_DEPTH-1:0]       ro_Y_channel            ;
reg         [P_GREEN_DEPTH-1:0]     ro_Cb_channel           ;
reg         [P_BLUE_DEPTH-1:0]      ro_Cr_channel           ;

//middle reg
reg                                 r_img_hsync_1d          ;
reg                                 r_img_vsync_1d          ;
reg                                 r_img_hsync_2d          ;
reg                                 r_img_vsync_2d          ;
reg                                 r_img_hsync_3d          ;
reg                                 r_img_vsync_3d          ;

reg         [23:0]                  r_Y_R_Multi_1           ;
reg         [23:0]                  r_Y_G_Multi_1           ;
reg         [23:0]                  r_Y_B_Multi_1           ;
reg         [23:0]                  r_Y_RGB_ADD_MOVE_2      ;

reg         [23:0]                  r_Cb_R_Multi_1          ;
reg         [23:0]                  r_Cb_G_Multi_1          ;
reg         [23:0]                  r_Cb_RGB_ADD_MOVE_2     ;

reg         [23:0]                  r_Cr_R_Multi_1          ;
reg         [23:0]                  r_Cr_G_Multi_1          ;
reg         [23:0]                  r_Cr_B_Multi_1          ;
reg         [23:0]                  r_Cr_RGB_ADD_MOVE_2     ;

wire                                w_valid_async           ;
wire                                w_valid_async_1d        ;
wire                                w_valid_async_2d        ;
wire                                w_valid_async_3d        ;

// assign
assign      o_Y_channel     =       ro_Y_channel     ;
assign      o_Cb_channel    =       ro_Cb_channel    ;
assign      o_Cr_channel    =       ro_Cr_channel    ;
assign      o_img_hsync     =       w_valid_async_3d ;
assign      o_img_vsync     =       r_img_vsync_3d   ;

assign      w_valid_async   =       ri_img_hsync &   i_img_vsync     ;
assign      w_valid_async_1d=       r_img_hsync_1d & r_img_vsync_1d  ;
assign      w_valid_async_2d=       r_img_hsync_2d & r_img_vsync_2d  ;
assign      w_valid_async_3d=       r_img_hsync_3d & r_img_vsync_3d  ;

// always
always @(posedge i_clk , negedge i_rst_n)begin
    if(!i_rst_n)begin
        ri_red_channel   <= 'd0;
        ri_green_channel <= 'd0;
        ri_blue_channel  <= 'd0;
        ri_img_hsync     <= 'd0;
        ri_img_vsync     <= 'd0;
    end else begin
        ri_red_channel   <= i_red_channel  ;
        ri_green_channel <= i_green_channel;
        ri_blue_channel  <= i_blue_channel ;
        ri_img_hsync     <= i_img_hsync    ;
        ri_img_vsync     <= i_img_vsync    ;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        r_img_hsync_1d  <= 1'b0;
        r_img_vsync_1d  <= 1'b0;
        r_img_hsync_2d  <= 1'b0;
        r_img_vsync_2d  <= 1'b0;
        r_img_hsync_3d  <= 1'b0;
        r_img_vsync_3d  <= 1'b0;
    end else begin
        r_img_hsync_1d  <= ri_img_hsync     ;
        r_img_vsync_1d  <= ri_img_vsync     ;
        r_img_hsync_2d  <= r_img_hsync_1d   ;
        r_img_vsync_2d  <= r_img_vsync_1d   ;
        r_img_hsync_3d  <= r_img_hsync_2d   ;
        r_img_vsync_3d  <= r_img_vsync_2d   ;
    end
end

always @(posedge i_clk , negedge i_rst_n)begin
    if(!i_rst_n)begin
        r_Y_R_Multi_1 <= 24'd0;
        r_Y_G_Multi_1 <= 24'd0;
        r_Y_B_Multi_1 <= 24'd0;
    end else if(w_valid_async) begin
        r_Y_R_Multi_1 <= P_Y_R_factor * ri_red_channel  ;
        r_Y_G_Multi_1 <= P_Y_G_factor * ri_green_channel;
        r_Y_B_Multi_1 <= P_Y_B_factor * ri_blue_channel ;
    end else begin
        r_Y_R_Multi_1 <= 24'd0;
        r_Y_G_Multi_1 <= 24'd0;
        r_Y_B_Multi_1 <= 24'd0;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_Y_RGB_ADD_MOVE_2 <= 24'd0;
    else if(w_valid_async_1d)
        r_Y_RGB_ADD_MOVE_2 <= r_Y_R_Multi_1 + r_Y_G_Multi_1 + r_Y_B_Multi_1;
    else
        r_Y_RGB_ADD_MOVE_2 <= r_Y_RGB_ADD_MOVE_2;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_Y_channel <= P_Y_Cb_Cr_DEFAULT;
    else if(w_valid_async_2d)
        ro_Y_channel <= r_Y_RGB_ADD_MOVE_2[23:10];
    else
        ro_Y_channel <= P_Y_Cb_Cr_DEFAULT;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        r_Cb_R_Multi_1<= 24'd0;
        r_Cb_G_Multi_1<= 24'd0;
    end
    else if(w_valid_async) begin
        r_Cb_R_Multi_1 <= P_Cb_R_factor * ri_red_channel  ;
        r_Cb_G_Multi_1 <= P_Cb_G_factor * ri_green_channel;
        r_Cb_G_Multi_1 <= P_Cb_B_factor * ri_blue_channel ;
    end else begin
        r_Cb_R_Multi_1<= 24'd0;
        r_Cb_G_Multi_1<= 24'd0;
    end
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_Cb_RGB_ADD_MOVE_2 <= 24'd0;
    else if(w_valid_async_1d)
        r_Cb_RGB_ADD_MOVE_2 <= r_Cb_R_Multi_1 + r_Cb_G_Multi_1 + r_Cb_G_Multi_1;
    else
        r_Cb_RGB_ADD_MOVE_2 <= r_Cb_RGB_ADD_MOVE_2;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_Cb_channel <= P_Y_Cb_Cr_DEFAULT;
    else if(w_valid_async_2d)
        ro_Cb_channel <= r_Cb_RGB_ADD_MOVE_2[23:10]+P_Cb_Const;
    else
        ro_Cb_channel <= P_Y_Cb_Cr_DEFAULT;
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) begin
        r_Cr_R_Multi_1 <= 24'd0;
        r_Cr_G_Multi_1 <= 24'd0;
        r_Cr_B_Multi_1 <= 24'd0;
    end
    else if(w_valid_async)begin
        r_Cr_R_Multi_1 <= P_Cr_R_factor * ri_red_channel  ;
        r_Cr_G_Multi_1 <= P_Cr_G_factor * ri_green_channel;
        r_Cr_B_Multi_1 <= P_Cr_B_factor * ri_blue_channel ; 
    end else begin
        r_Cr_R_Multi_1 <= 24'd0;
        r_Cr_G_Multi_1 <= 24'd0;
        r_Cr_B_Multi_1 <= 24'd0;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_Cr_RGB_ADD_MOVE_2 <= 24'd0;
    else if(w_valid_async_1d)
        r_Cr_RGB_ADD_MOVE_2 <= r_Cr_R_Multi_1 - r_Cr_G_Multi_1 - r_Cr_B_Multi_1;
    else
        r_Cr_RGB_ADD_MOVE_2 <= r_Cr_RGB_ADD_MOVE_2;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_Cr_channel <= P_Y_Cb_Cr_DEFAULT;
    else if(w_valid_async_2d)
        ro_Cr_channel <= r_Cr_RGB_ADD_MOVE_2[23:10]+P_Cr_Const;
    else
        ro_Cr_channel <= P_Y_Cb_Cr_DEFAULT;
end
endmodule