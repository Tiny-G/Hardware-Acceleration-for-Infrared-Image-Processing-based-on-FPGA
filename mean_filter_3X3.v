`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/17 15:43:30
// Design Name: 
// Module Name: mean_filter_3X3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// this is a mean fiter module about 3X3 window
// Dependencies: 
// localparam        P_INPUT_ROWS_NUM  = 3 ;
// localparam        P_DATA_WIDTH      = 8 ;
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mean_filter_3X3
(
    input               i_clk       ,
    input               i_rst_n     ,
    input               i_h_sync    ,
    input               i_v_sync    ,
    input   [23:0]      i_raws_col1 ,
    input   [23:0]      i_raws_col2 ,
    input   [23:0]      i_raws_col3 ,

    output              o_h_sync    ,
    output              o_v_sync    ,
    output  [7:0]       o_mean_value
);


localparam        P_MEAN_FACTOR     =  12'd3641;
localparam        P_MOVE_FACTOR     =   15  ;
//input regisers
reg                 ri_h_sync       ;
reg                 ri_v_sync       ;
reg     [23:0]      ri_raws_col1    ;
reg     [23:0]      ri_raws_col2    ;
reg     [23:0]      ri_raws_col3    ;

//output registers
reg                 ro_h_sync       ;
reg                 ro_v_sync       ;
reg     [7:0]       ro_mean_value   ;

//temp resgisters
reg     [23:0]      r_cal_res       ;
wire                w_h_valid_sync  ;
reg                 r_h_valid_sync_1d;
reg                 r_h_valid_sync_2d;
reg                 r_v_sync_1d     ;
reg                 r_v_sync_2d     ;

//assign output
assign o_h_sync     = ro_h_sync   ;
assign o_v_sync     = ro_v_sync   ;
assign o_mean_value = ro_mean_value;
assign w_h_valid_sync = ri_h_sync & ri_v_sync;

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_h_sync    <= 1'd0;
        ri_v_sync    <= 1'd0;
        ri_raws_col1 <=  'd0;
        ri_raws_col2 <=  'd0;
        ri_raws_col3 <=  'd0;
        r_h_valid_sync_1d <= 1'd0;
        r_h_valid_sync_2d <= 1'd0;
        r_v_sync_1d <= 1'd0;
        r_v_sync_2d <= 1'd0;
    end else begin
        ri_h_sync    <= i_h_sync   ;
        ri_v_sync    <= i_v_sync   ;
        ri_raws_col1 <= i_raws_col1;
        ri_raws_col2 <= i_raws_col2;
        ri_raws_col3 <= i_raws_col3;
        r_h_valid_sync_1d <= w_h_valid_sync;
        r_h_valid_sync_2d <= r_h_valid_sync_1d;
        r_v_sync_1d  <= ri_v_sync;
        r_v_sync_2d  <= r_v_sync_1d;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) r_cal_res <= 24'd0;
    else if(w_h_valid_sync) r_cal_res <= (ri_raws_col1[23:16] + ri_raws_col1[15:8] + ri_raws_col1[7:0] 
                        +ri_raws_col2[23:16] + ri_raws_col2[15:8] + ri_raws_col2[7:0]
                        +ri_raws_col3[23:16] + ri_raws_col3[15:8] + ri_raws_col3[7:0])*P_MEAN_FACTOR;
    else r_cal_res <= 24'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_mean_value  <= 8'd0;
    else if(r_h_valid_sync_1d)
        ro_mean_value <= r_cal_res>>P_MOVE_FACTOR;
    else
        ro_mean_value  <= 8'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) begin
        ro_h_sync    <= 1'd0;
        ro_v_sync    <= 1'd0;
    end else begin
        ro_h_sync    <= r_h_valid_sync_1d;
        ro_v_sync    <= r_v_sync_1d;
    end
end
endmodule
