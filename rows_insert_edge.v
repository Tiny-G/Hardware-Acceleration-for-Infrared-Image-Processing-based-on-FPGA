`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/11 15:51:24
// Design Name: 
// Module Name: rows_insert_edge
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


module rows_insert_edge
#(
    parameter          P_INPUT_ROWS_NUM        = 5   ,
    parameter          P_IMAGE_WIDTH           = 256 ,
    parameter          P_IMAGE_HEIGHT          = 256 ,
    parameter          P_ROW_DATA_WIDTH        = 8      // width of each row data,the actualdata input width is P_INPUT_ROWS_NUM*P_ROW_DATA_WIDTH
)
(
    input              i_clk            ,
    input              i_rst_n          ,
    input              i_v_async        ,
    input              i_h_async        ,
    input              i_remainder_signal,
    input [P_INPUT_ROWS_NUM*P_ROW_DATA_WIDTH-1:0] i_rows_data,

    output             o_v_async        ,
    output             o_h_async        ,
    output [P_INPUT_ROWS_NUM*P_ROW_DATA_WIDTH-1:0] o_rows_data,
    output             o_remainder_signal,
    output             o_lefe_edge_en   ,
    output             o_top_edge_en    ,
    output             o_right_edge_en  ,
    output             o_bottom_edge_en
);

localparam  P_COUNT_MULTI_ROWS_MAX_NUM =  P_IMAGE_HEIGHT/P_INPUT_ROWS_NUM;
localparam  P_REMAINDER =  P_IMAGE_HEIGHT%P_INPUT_ROWS_NUM == 0?1'b0:1'b1;
localparam  P_COUNT_ACTUAL_ROWS_NUM= P_COUNT_MULTI_ROWS_MAX_NUM + P_REMAINDER ;


//input registers
reg         ri_v_async          ;
reg         ri_h_async          ;
reg [P_INPUT_ROWS_NUM*P_ROW_DATA_WIDTH-1:0] ri_rows_data;
reg         ri_remainder_signal ;
//output registers
reg         ro_v_async          ;
reg         ro_h_async          ;
reg [P_INPUT_ROWS_NUM*P_ROW_DATA_WIDTH-1:0] ro_rows_data;
reg         ro_remainder_signal ;
reg         ro_lefe_edge_en     ;
reg         ro_top_edge_en      ;
reg         ro_right_edge_en    ;
reg         ro_bootom_edge_en   ;

//temporary registers
reg         r_is_first_row      ;
reg         r_is_last_row       ;
reg         r_h_async_1d        ;    //to get posedge of ri_h_async,so we can use it to detect the head of fisrt row
reg [15:0]  r_multirowscnt      ;   //to count the number of "MultiRows" that have passed
reg [15:0]  r_row_pixelscnt     ;   //to count the number of "Pixels" in each row



wire    w_h_async_posedge ;
wire    w_h_async_negedeg ;

assign  w_h_async_posedge = ri_h_async & !r_h_async_1d;
assign  w_h_async_negedeg = !ri_h_async & r_h_async_1d;

assign  o_v_async          = ro_v_async          ;
assign  o_h_async          = ro_h_async          ;
assign  o_rows_data        = ro_rows_data        ;
assign  o_remainder_signal = ro_remainder_signal ;
assign  o_lefe_edge_en     = ro_lefe_edge_en     ;
assign  o_top_edge_en      = ro_top_edge_en      ;
assign  o_right_edge_en    = ro_right_edge_en    ;
assign  o_bottom_edge_en   = ro_bootom_edge_en   ;

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_v_async   <= 1'b0;
        ri_h_async   <= 1'b0;
        ri_rows_data <= 'd0 ;
        r_h_async_1d <= 1'b0;
        ri_remainder_signal <= 1'b0;
    end else begin
        ri_v_async   <= i_v_async  ;
        ri_h_async   <= i_h_async  ;
        ri_rows_data <= i_rows_data;
        r_h_async_1d <= ri_h_async ;
        ri_remainder_signal <= i_remainder_signal;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin //specify value 1 is have 【no appeared】 the "FirstRows"
    if(!i_rst_n)
        r_is_first_row <= 1'b0;
    else if(w_h_async_posedge)
        r_is_first_row <= 1'b1;
    else if(!ri_v_async)
        r_is_first_row <= 1'b0;
    else
        r_is_first_row <= r_is_first_row;
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_multirowscnt <= 16'd0;
    else if(!ri_v_async)
        r_multirowscnt <= 16'd0;
    else if(w_h_async_posedge)
        r_multirowscnt <= r_multirowscnt + 16'd1;
    else
        r_multirowscnt <= r_multirowscnt;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_row_pixelscnt <= 16'd0;
    else if(ri_h_async)
        r_row_pixelscnt <= r_row_pixelscnt + 16'd1;
    else
        r_row_pixelscnt <= 16'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_is_last_row <= 1'b0;
    else if(!ri_v_async)
        r_is_last_row <= 1'b0;
    else if(r_multirowscnt == P_COUNT_ACTUAL_ROWS_NUM -1 && w_h_async_posedge)
        r_is_last_row <= 1'b1;
    else
        r_is_last_row <= r_is_last_row;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_lefe_edge_en <= 1'b0;
    else if(w_h_async_posedge && ri_v_async)
        ro_lefe_edge_en <= 1'b1;
    else
        ro_lefe_edge_en <= 1'b0;
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_top_edge_en <= 1'b0;
    else if((r_is_first_row && w_h_async_negedeg)||!ri_v_async)
        ro_top_edge_en <= 1'b0;
    else if(!r_is_first_row && w_h_async_posedge)
        ro_top_edge_en <= 1'b1;
    else
        ro_top_edge_en <= ro_top_edge_en;
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_right_edge_en <= 1'b0;
    else if(r_row_pixelscnt == P_IMAGE_WIDTH-1 && ri_v_async)
        ro_right_edge_en <= 1'b1;
    else
        ro_right_edge_en <= 1'b0;
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_bootom_edge_en <= 1'b1;
    else if((r_is_last_row && w_h_async_negedeg)||!ri_v_async)
        ro_bootom_edge_en <= 1'b0;
    else if(!r_is_last_row && r_multirowscnt == P_COUNT_ACTUAL_ROWS_NUM-1 && w_h_async_posedge)
        ro_bootom_edge_en <= 1'b1;
    else
        ro_bootom_edge_en <= ro_bootom_edge_en;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        ro_v_async        <= 1'd0;
        ro_h_async        <= 1'd0;
        ro_rows_data      <= 'd0 ;
        ro_remainder_signal <= 1'd0;
    end else begin
        ro_v_async        <= ri_v_async       ;
        ro_h_async        <= ri_h_async       ;
        ro_rows_data      <= ri_rows_data     ;
        ro_remainder_signal <= ri_remainder_signal;
    end
end
endmodule
