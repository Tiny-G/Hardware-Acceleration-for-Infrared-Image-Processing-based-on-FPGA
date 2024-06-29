`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/20 21:28:08
// Design Name: 
// Module Name: dual_image_subtraction
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


module dual_image_subtraction
#(
    parameter                           P_INPUT_DATA_WIDTH   = 8  ,
    parameter                           P_IMG_WIDTH          = 256,
    parameter                           P_IMG_HEIFGHT        = 256,
    parameter                           P_OUTPUT_DATA_WIDTH  = 8  
)
(
    input                               i_clk       ,
    input                               i_rst_n     ,
    input                               i_h_sync_m  ,
    input                               i_v_sync_m  ,
    input   [P_INPUT_DATA_WIDTH-1:0]    i_data_m    ,
    input                               i_h_sync_s  ,
    input                               i_v_sync_s  ,
    input   [P_INPUT_DATA_WIDTH-1:0]    i_data_s    ,

    output                              o_v_sync    ,
    output                              o_h_sync    ,
    output  [P_OUTPUT_DATA_WIDTH-1:0]   o_res_data  
);

//input register
reg                             ri_h_sync_m ;
reg                             ri_v_sync_m ;
reg [P_INPUT_DATA_WIDTH-1:0]    ri_data_m   ;
reg                             ri_h_sync_s ;
reg                             ri_v_sync_s ;
reg [P_INPUT_DATA_WIDTH-1:0]    ri_data_s   ;

//temp register
wire                            w_valid_v_sync;
wire                            w_valid_h_sync;
wire                            w_valid_h   ;

//output register
reg                             ro_v_sync   ;
reg                             ro_h_sync   ;
reg [P_OUTPUT_DATA_WIDTH-1:0]   ro_res_data ;


assign w_valid_v_sync = ri_v_sync_m && ri_v_sync_s;
assign w_valid_h_sync = ri_h_sync_m && ri_h_sync_s;
assign w_valid_h      = w_valid_h_sync && w_valid_v_sync;

assign o_v_sync   = ro_v_sync;
assign o_h_sync   = ro_h_sync;
assign o_res_data = ro_res_data;


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_h_sync_m <= 1'd0 ;
        ri_v_sync_m <= 1'd0 ;
        ri_data_m   <= 'd0  ;
        ri_h_sync_s <= 1'd0 ;
        ri_v_sync_s <= 1'd0 ;
        ri_data_s   <= 'd0  ;
    end else begin
        ri_h_sync_m <= i_h_sync_m;
        ri_v_sync_m <= i_v_sync_m;
        ri_data_m   <= i_data_m  ;
        ri_h_sync_s <= i_h_sync_s;
        ri_v_sync_s <= i_v_sync_s;
        ri_data_s   <= i_data_s  ;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_v_sync <= 1'd0;
    else

        ro_v_sync <= w_valid_v_sync;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_sync <= 1'd0;
    else if(w_valid_h)
        ro_h_sync <= 1'd1;
    else
        ro_h_sync <= 1'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_res_data <= 'd0;
    else if(w_valid_h)
        ro_res_data <= (ri_data_m - ri_data_s)>0?(ri_data_m - ri_data_s):0 ;////可以用LUT实现
    else
        ro_res_data <= 'd0;
end

endmodule
