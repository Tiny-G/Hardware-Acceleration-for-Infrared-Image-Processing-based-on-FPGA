`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/20 15:27:35
// Design Name: 
// Module Name: multi_hight_feature
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 这个模块要固定只能是8位宽？因为我没发现输入最大值的位宽跟，输出的最大位宽的关系
// 因为8位最大值乘8位最大值，得到的最大值，20位 = 3*8-2  2*8+4 
// 因为9位最大值乘9位最大值，得到的最大值，24位 = 3*9-3  2*9+6 = 2*9+4+2
// 因为10位最大值乘10位最大值，得到的最大值，28位 = 3*10-2  2*10+8 = 2*10+4+2+2（好像这里也有规律，但我赶时间）
// 如果直接定义输出32位，也是能满足部分输入值可变位宽的，但是会占用更多的资源，所以这里还是固定为8位宽
// 256X256 = 65,536 = 20'b0001_0000_0000_0000_0000
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module multi_hight_feature
(
    input                       i_clk       ,
    input                       i_rst_n     ,
    input                       i_h_aync_m  ,
    input                       i_v_aync_m  ,
    input   [7:0]               i_data_m    ,
    input                       i_v_aync_s  ,
    input                       i_h_aync_s  ,
    input   [7:0]               i_data_s    ,

    output                      o_h_aync    ,
    output                      o_v_aync    ,
    output  [19:0]              o_res_data  
);

//input regisiters
reg                 ri_h_aync_m ;
reg                 ri_v_aync_m ;
reg     [7:0]       ri_data_m   ;
reg                 ri_v_aync_s ;
reg                 ri_h_aync_s ;
reg     [7:0]       ri_data_s   ;

//output registers
reg                 ro_h_aync   ;
reg                 ro_v_aync   ;
reg     [7:0]       ro_res_data ;

//temp register
wire                w_h_valid_aync;
wire                w_v_valid_aync;

assign  o_h_aync   = ro_h_aync   ;
assign  o_v_aync   = ro_v_aync   ;
assign  o_res_data = ro_res_data ;

assign  w_h_valid_aync = ri_h_aync_m && ri_h_aync_s;
assign  w_v_valid_aync = ri_v_aync_m && ri_v_aync_s;

always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ri_h_aync_m <= 1'd0;
        ri_v_aync_m <= 1'd0;
        ri_data_m   <= 8'd0;
        ri_v_aync_s <= 1'd0;
        ri_h_aync_s <= 1'd0;
        ri_data_s   <= 8'd0;
    end else begin
        ri_h_aync_m <= i_h_aync_m;
        ri_v_aync_m <= i_v_aync_m;
        ri_data_m   <= i_data_m  ;
        ri_v_aync_s <= i_v_aync_s;
        ri_h_aync_s <= i_h_aync_s;
        ri_data_s   <= i_data_s  ;
    end
end

always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_res_data   <= 20'd0;
    else if(w_h_valid_aync)
        ro_res_data   <= ri_data_m * ri_data_s;
    else
        ro_res_data   <= 20'd0;
end

always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ro_h_aync   <= 1'd0;
        ro_v_aync   <= 1'd0;
    end else begin
        ro_h_aync   <= w_h_valid_aync;
        ro_v_aync   <= w_v_valid_aync;
    end
end


endmodule
