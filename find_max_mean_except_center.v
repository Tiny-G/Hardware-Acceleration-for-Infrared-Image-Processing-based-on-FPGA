`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/06/18 22:51:07
// Design Name: 
// Module Name: find_max_mean_except_center
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 求输入的多个模块的均值中除开中心块的最大值
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module find_max_mean_except_center
#(
    parameter                                                                       P_DATA_WIDTH             = 20    ,
    parameter                                                                       P_SCALE_SIZE             = 3     ,
    parameter                                                                       P_OUTPUT_DATA_WIDTH      = 32    ,
    parameter                                                                       P_MASK_SIZE              = 3      //P_SLIDE_WINDOW = P_SCALE_SIZE*P_MASK_SIZE
)
(
    input                                                                           i_clk           ,
    input                                                                           i_rst_n         ,
    input                                                                           i_v_sync        ,
    input                                                                           i_h_sync        ,
    input   [P_DATA_WIDTH*P_MASK_SIZE*P_SCALE_SIZE*P_MASK_SIZE*P_SCALE_SIZE-1:0]    i_data          ,

    output                                                                          o_v_sync        ,
    output                                                                          o_h_sync        ,
    output  [P_OUTPUT_DATA_WIDTH-1:0]                                               o_max_mean      
);


localparam         P_CENTER_index = P_MASK_SIZE*P_MASK_SIZE/2;

// input register
reg                                                                         ri_v_sync       ;
reg                                                                         ri_v_sync_1d    ;
reg                                                                         ri_v_sync_2d    ;
reg                                                                         ri_h_sync       ;
reg [P_DATA_WIDTH*P_MASK_SIZE*P_SCALE_SIZE*P_MASK_SIZE*P_SCALE_SIZE-1:0]    ri_data         ;

//output register
reg                                                                         ro_v_sync       ;
reg                                                                         ro_h_sync       ;
reg     [P_OUTPUT_DATA_WIDTH-1:0]                                           ro_max_mean     ;
//temp register

wire                                                                        w_mean_valid    ;
wire    [P_OUTPUT_DATA_WIDTH*P_MASK_SIZE*P_MASK_SIZE -1:0]                  w_mean_data     ;

wire                                                                        w_h_sync_valid  ;
wire    [P_OUTPUT_DATA_WIDTH-1:0]                                           w_max_value     ; //周围八个数的最大值
// wire    [$clog2(P_MASK_SIZE*P_MASK_SIZE-1)-1:0]                             w_max_index     ; //最大值所在的索引]w_max_index
wire                                                                        w_valid         ; //是否有有效数据;

assign o_max_mean   = ro_max_mean;
assign o_v_sync     = ro_v_sync;
assign o_h_sync     = ro_h_sync;

assign w_h_sync_valid = ri_v_sync && ri_h_sync;


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ri_v_sync    <= 1'b0;
        ri_h_sync    <= 1'b0;
        ri_data      <=  'd0;
        ri_v_sync_1d <= 1'b0;
        ri_v_sync_2d <= 1'b0;
    end else begin
        ri_v_sync <= i_v_sync;
        ri_h_sync <= i_h_sync;
        ri_data   <= i_data  ;
        ri_v_sync_1d <= ri_v_sync;
        ri_v_sync_2d <= ri_v_sync_1d;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_v_sync <= 1'b0;
    else
        ro_v_sync <= ri_v_sync_2d;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_sync <= 1'b0;
    else if(w_valid)
        ro_h_sync <= 1'b1;
    else
        ro_h_sync <= 1'b0;
end
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_max_mean <= 'b0;
    else if(w_valid)
        ro_max_mean <= w_max_value;
    else
        ro_max_mean <= 'b0;
end

find_multi_block_mean #(
    .P_DATA_WIDTH        (P_DATA_WIDTH          ),
    .P_SCALE_SIZE        (P_SCALE_SIZE          ),
    .P_OUTPUT_DATA_WIDTH (P_OUTPUT_DATA_WIDTH   ),
    .P_MASK_SIZE         (P_MASK_SIZE           )
)
find_multi_block_mean_U0(
    .i_clk               ( i_clk                ),
    .i_rst_n             ( i_rst_n              ),
    .i_valid             ( w_h_sync_valid       ),
    .i_data              ( ri_data              ),
    .o_valid             ( w_mean_valid         ),
    .o_data              ( w_mean_data          )
);


find_max_value #(
    .P_DATA_WIDTH       ( P_OUTPUT_DATA_WIDTH       ),
    .P_DATA_NUM         ( P_MASK_SIZE*P_MASK_SIZE)
)
find_max_value_U1(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_data             ( w_mean_data       ),
    .i_valid            ( w_mean_valid      ),
    .o_valid            ( w_valid           ),
    .o_max_value        ( w_max_value       ),
    .o_max_index        (                   )
);
endmodule
