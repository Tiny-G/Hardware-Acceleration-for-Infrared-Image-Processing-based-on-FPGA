`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/06/18 22:36:15
// Design Name: 
// Module Name: find_multi_block_mean
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 求通过滑窗输入的多个模块的均值
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module find_multi_block_mean
#(
    parameter                                                                       P_DATA_WIDTH             = 20    ,
    parameter                                                                       P_SCALE_SIZE             = 3     ,
    parameter                                                                       P_OUTPUT_DATA_WIDTH      = 32    ,
    parameter                                                                       P_MASK_SIZE              = 3     //P_SLIDE_WINDOW = P_SCALE_SIZE*P_MASK_SIZE
)
(
    input                                                                           i_clk   ,
    input                                                                           i_rst_n ,
    input                                                                           i_valid ,
    input   [P_DATA_WIDTH*P_SCALE_SIZE*P_SCALE_SIZE*P_MASK_SIZE*P_MASK_SIZE-1:0]    i_data  ,

    output                                                                          o_valid ,
    output  [P_OUTPUT_DATA_WIDTH*P_MASK_SIZE*P_MASK_SIZE -1:0]                      o_data            
);

//滑窗大小
localparam  P_SLIDE_WINDOW = P_SCALE_SIZE*P_MASK_SIZE ;
//input registers
reg                                                     ri_valid    ;
reg [P_DATA_WIDTH*P_SLIDE_WINDOW*P_SLIDE_WINDOW-1:0]    ri_data     ;

//output registers
reg                                                     ro_valid    ;
reg [P_OUTPUT_DATA_WIDTH-1:0]                           ro_data     ;

//temporary registers
reg [P_OUTPUT_DATA_WIDTH-1:0]       r_masks_means       [P_MASK_SIZE*P_MASK_SIZE-1:0];
reg [P_OUTPUT_DATA_WIDTH*P_MASK_SIZE*P_MASK_SIZE-1:0]   w_r_masks_means_flatten     ;

assign o_valid  = ro_valid ;
assign o_data   = ro_data  ;

always @(posedge i_clk or negedge i_rst_n)begin
    if(~i_rst_n)begin
        ri_valid <= 1'd0;
        ri_data   <=  'd0;
    end else begin
        ri_valid <= i_valid;
        ri_data   <= i_data  ;
    end
end

//求九个分块的平均值
genvar i,j;
generate
    for(i=0;i<P_MASK_SIZE;i=i+1) begin : loop_masks_means
        for(j=0;j<P_MASK_SIZE;j=j+1) begin : loop_masks_means_inner
            always @(posedge i_clk or negedge i_rst_n)
                if(~i_rst_n)
                    r_masks_means [i*P_MASK_SIZE+j] <=  'd0;
                else
                    r_masks_means [i*P_MASK_SIZE+j] <=  ((ri_data[(i*P_SLIDE_WINDOW+j*P_MASK_SIZE+i)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[(i*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+1)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[(i*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+2)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+1)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+1)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+1)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+1)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+2)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+2)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+2)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+1)*P_DATA_WIDTH +:P_DATA_WIDTH] + 
                                                          ri_data[((i+2)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+2)*P_DATA_WIDTH +:P_DATA_WIDTH]
                                                          )*227)>>12;
        end
    end
endgenerate

//将二维展平成1维
integer n;
always @(*) begin
    for (n=0;n<P_MASK_SIZE*P_MASK_SIZE;n=n+1)
        w_r_masks_means_flatten[n*P_OUTPUT_DATA_WIDTH +:P_OUTPUT_DATA_WIDTH] = r_masks_means[n];
end

//输出
always @(posedge i_clk or negedge i_rst_n)begin
    if(~i_rst_n)
        ro_valid <= 1'd0;
    else if(ri_valid)
        ro_valid <= 1'd1;
    else
        ro_valid <= 1'd0;
end
always @(posedge i_clk or negedge i_rst_n)begin
    if(~i_rst_n)
        ro_data  <=  'd0;
    else if(ri_valid)
        ro_data  <= w_r_masks_means_flatten;
    else
        ro_data  <=  'd0;
end

endmodule
