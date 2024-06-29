`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/19 18:30:33
// Design Name: 
// Module Name: subtraction_remove_less_than_zero
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 主减去从数据，如果小于0，则置0
//由于输入的数据间隔不对齐，所以需要使用FIFO进行缓存
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module subtraction_remove_less_than_zero
#(
    parameter          P_DATA_WIDTH = 8
)
(
    input                       i_clk    ,
    input                       i_rst_n  ,
    input                       i_h_aync_m  ,
    input                       i_v_aync_m  ,
    input   [P_DATA_WIDTH-1:0]  i_data_m    ,
    input                       i_v_aync_s  ,
    input                       i_h_aync_s  ,
    input   [P_DATA_WIDTH-1:0]  i_data_s    ,

    output                      o_h_aync    ,
    output                      o_v_aync    ,
    output  [P_DATA_WIDTH-1:0]  o_res_data  
);

//input regisiters
reg                             ri_h_aync_m ;
reg                             ri_v_aync_m ;
reg     [P_DATA_WIDTH-1:0]      ri_data_m   ;
reg                             ri_v_aync_s ;
reg                             ri_h_aync_s ;
reg     [P_DATA_WIDTH-1:0]      ri_data_s   ;

//output registers
reg                             ro_h_aync   ;
reg                             ro_v_aync   ;
reg     [P_DATA_WIDTH-1:0]      ro_res_data ;

//temp register
wire                            w_h_valid_aync;
wire                            w_v_valid_aync;

assign  o_h_aync   = ro_h_aync   ;
assign  o_v_aync   = ro_v_aync   ;
assign  o_res_data = ro_res_data ;

assign  w_h_valid_aync = ri_h_aync_m && ri_h_aync_s;
assign  w_v_valid_aync = ri_v_aync_m && ri_v_aync_s;

always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ri_h_aync_m <= 1'd0;
        ri_v_aync_m <= 1'd0;
        ri_data_m   <=  'd0;
        ri_v_aync_s <= 1'd0;
        ri_h_aync_s <= 1'd0;
        ri_data_s   <=  'd0;
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
        ro_res_data   <= 'd0;
    else if(w_h_valid_aync)
        ro_res_data   <= ri_data_m - ri_data_s > 0 ? ri_data_m - ri_data_s :  'd0;
    else
        ro_res_data   <= 'd0;
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
