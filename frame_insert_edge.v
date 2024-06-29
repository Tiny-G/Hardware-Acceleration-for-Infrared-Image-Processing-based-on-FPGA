`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/12 19:51:29
// Design Name: 
// Module Name: frame_insert_edge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 针对单行输入的插入边界信号
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module frame_insert_edge
#(
    parameter          P_DATA_WIDTH     = 20    ,
    parameter          P_IMAGE_HEIGHT   = 256  
)
(
    input                       i_clk       ,
    input                       i_rst_n     ,
    input                       i_h_sync    ,
    input                       i_v_sync    ,
    input   [P_DATA_WIDTH-1:0]  i_data      ,

    output                      o_h_sync    ,
    output                      o_v_sync    ,
    output  [P_DATA_WIDTH-1:0]  o_data      ,
    output                      o_left_en   ,
    output                      o_right_en  ,
    output                      o_top_en    ,
    output                      o_bottom_en 
);

//input registers
reg                         ri_h_sync           ;
reg                         ri_v_sync           ;
reg     [P_DATA_WIDTH-1:0]  ri_data             ;
reg                         ri_h_sync_1d        ;
reg                         ri_v_sync_1d        ;
reg     [P_DATA_WIDTH-1:0]  ri_data_1d          ;

//output registers
reg                         ro_h_sync           ;
reg                         ro_v_sync           ;
reg     [P_DATA_WIDTH-1:0]  ro_data             ;
reg                         ro_left_en          ;
reg                         ro_left_en_1d       ;
reg                         ro_right_en         ;
reg                         ro_top_en           ;
reg                         ro_top_en_1d        ;
reg                         ro_bottom_en        ;
reg                         ro_bottom_en_1d     ;

//temporary registers
reg     [15:0]              r_rows_cnt          ;
reg                         r_valid_h_sync_1d   ;
// reg     [15:0]              r_count_rows_cnt    ;

wire                        w_valid_h_sync      ;
wire                        w_valid_h_sync_pos  ;
wire                        w_valid_h_sync_neg  ;

assign o_h_sync   = ro_h_sync       ;
assign o_v_sync   = ro_v_sync       ;
assign o_data     = ro_data         ;
assign o_left_en  = ro_left_en_1d   ;
assign o_right_en = ro_right_en     ;
assign o_top_en   = ro_top_en_1d    ;
assign o_bottom_en= ro_bottom_en_1d ;

assign w_valid_h_sync = ri_v_sync && ri_h_sync;
assign w_valid_h_sync_pos = w_valid_h_sync && !r_valid_h_sync_1d;
assign w_valid_h_sync_neg = !w_valid_h_sync && r_valid_h_sync_1d;

// always @(posedge i_clk or negedge i_rst_n) begin
//     if(~i_rst_n) 
//         r_count_rows_cnt <= 16'd0;
//     else if(!ro_v_sync)
//         r_count_rows_cnt <= 16'd0;
//     else if(ro_left_en_1d)
//         r_count_rows_cnt <= r_count_rows_cnt + 16'd1;
//     else
//         r_count_rows_cnt <= r_count_rows_cnt;
// end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        ri_h_sync   <= 1'b0;
        ri_v_sync   <= 1'b0;
        ri_data     <=  'b0;
        r_valid_h_sync_1d <= 1'b0;
        ri_h_sync_1d <= 1'b0;
        ri_v_sync_1d <= 1'b0;
        ri_data_1d   <=  'd0;
        ro_left_en_1d <= 1'b0;
        ro_top_en_1d  <= 1'b0;
        ro_bottom_en_1d  <= 1'b0;
    end else begin
        ri_h_sync   <= i_h_sync;
        ri_v_sync   <= i_v_sync;
        ri_data     <= i_data  ;
        r_valid_h_sync_1d <= w_valid_h_sync;
        ri_h_sync_1d <= ri_h_sync;
        ri_v_sync_1d <= ri_v_sync;
        ri_data_1d   <= ri_data  ;
        ro_left_en_1d <= ro_left_en;
        ro_top_en_1d  <= ro_top_en;
        ro_bottom_en_1d  <= ro_bottom_en;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_rows_cnt  <=  16'b0;
    else if(r_rows_cnt == P_IMAGE_HEIGHT && w_valid_h_sync_neg)
        r_rows_cnt  <=  16'b0;
    else if(w_valid_h_sync_pos)
        r_rows_cnt  <=  r_rows_cnt + 16'd1;
    else
        r_rows_cnt  <=  r_rows_cnt;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        ro_left_en   <=  1'b0;
    else if(w_valid_h_sync_pos)
        ro_left_en   <=  1'b1;
    else
        ro_left_en   <=  1'b0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        ro_right_en   <=  1'b0;
    else if(w_valid_h_sync_neg)
        ro_right_en   <=  1'b1;
    else
        ro_right_en   <=  1'b0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        ro_top_en   <=  1'b0;
    else if(w_valid_h_sync_neg)
        ro_top_en   <=  1'b0;
    else if(r_rows_cnt == 16'd0 && w_valid_h_sync_pos)
        ro_top_en   <=  1'b1;
    else
        ro_top_en   <=  ro_top_en;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        ro_bottom_en   <=  1'b0;
    else if(w_valid_h_sync_neg)
        ro_bottom_en   <=  1'b0;
    else if(w_valid_h_sync_pos && r_rows_cnt == P_IMAGE_HEIGHT-1)
        ro_bottom_en   <=  1'b1;
    else
        ro_bottom_en   <=  ro_bottom_en;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        ro_h_sync <= 1'b0;
        ro_v_sync <= 1'b0;
        ro_data   <=  'b0;
    end else begin
        ro_h_sync <= ri_h_sync_1d;
        ro_v_sync <= ri_v_sync_1d;
        ro_data   <= ri_data_1d  ;
    end
end
endmodule
