`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/16 13:56:04
// Design Name: 
// Module Name: sliding_window_3X3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// this module is used to convert rows data to sliding window data with 3X3 size.
//由于最后进入的一行，可能不是完整的3行，所以最好要保存最后的上两行的数据，残缺行进入的时候，前面两行已经无法捕捉。
// 这里我经过计算，发现我进入的数据刚好是整数倍，同时为了追求快速写完并未做这个处理
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rows_sliding_window_3X3
#(
    // input image's rows number,defalut is 5
    parameter          P_IMAGE_WIDTH           = 256 ,  // input image's cols number,defalut is 5
    parameter          P_IMAGE_HEIGHT          = 256 ,  // input image's rows number,defalut is 5
    parameter          P_EXPEND_NUM            = 1   ,  
    parameter          P_DATA_WIDTH            = 8      // width of each row's data,default is 8-bit
)
(
    input              i_clk        ,
    input              i_rst_n      ,  
    input              i_h_async    ,
    input              i_v_async    ,
    input              i_padd_remainder ,
    input   [3*P_DATA_WIDTH-1:0] i_rows_data,
    
    output             o_h_sync  ,
    output             o_v_sync  ,
    output  [3*P_DATA_WIDTH-1:0]  o_rows_col1,
    output  [3*P_DATA_WIDTH-1:0]  o_rows_col2,
    output  [3*P_DATA_WIDTH-1:0]  o_rows_col3
);

localparam        P_INPUT_ROWS_NUM  = 3   ;
localparam        P_ADDR_WIDTH      = 5   ;
localparam        P_ROWS_DATA_WIDTH = P_DATA_WIDTH*3;
localparam        P_EXPAND_WIDTH    = P_IMAGE_WIDTH+2*P_EXPEND_NUM;
//input registers
reg                         ri_h_async          ;
reg                         ri_v_async          ;
reg                         ri_padd_remainder   ;
reg [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] ri_rows_data;

//output registers
reg                         ro_h_sync   ;
reg                         ro_v_sync   ;

//temp registers
reg                         r_wr_en1    ;
reg [P_ROWS_DATA_WIDTH-1:0] r_din1      ;
wire[P_ROWS_DATA_WIDTH-1:0] w_dout1     ;
reg                         r_rd_en1    ;
reg                         r_wr_en2    ;
wire[P_ROWS_DATA_WIDTH-1:0] w_din2      ;
wire[P_ROWS_DATA_WIDTH-1:0] w_dout2     ;
reg                         r_rd_en2    ;
reg [15:0]                  r_pixel_cnt         ;
wire                        w_vlid_h_async      ;
reg                         r_vlid_h_async_1d   ;
reg                         r_vlid_h_async_2d   ;
reg                         r_vlid_h_async_3d   ;
reg                         r_v_async_1d        ;
reg                         r_v_async_2d        ;
reg                         r_v_async_3d        ;
reg                         r_sustained_en      ;   //when the value is 1,and it's indicated that it is time of sustained output 3X3 data

reg [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] ri_rows_data_1d;
reg [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] ri_rows_data_2d;
reg [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] ri_rows_data_3d;

reg [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] ro_rows_col1;
reg [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] ro_rows_col2;
reg [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] ro_rows_col3;

assign o_h_sync     =   ro_h_sync ;
assign o_v_sync     =   r_v_async_1d    ;
assign o_rows_col1  =   ro_rows_col1    ;
assign o_rows_col2  =   ro_rows_col2    ;
assign o_rows_col3  =   ro_rows_col3    ;

assign w_vlid_h_async = ri_h_async & ri_v_async;
assign w_h_async_posedge = ri_h_async & !r_vlid_h_async_1d;
assign w_h_async_negedge = !ri_h_async & r_vlid_h_async_1d;
assign w_din2 = w_dout1;

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_h_async        <= 1'b0;
        ri_v_async        <= 1'b0;
        ri_padd_remainder <= 1'b0;
        ri_rows_data      <= 'd0 ;
        ri_rows_data_1d   <= 'd0 ;
        ri_rows_data_2d   <= 'd0 ;
        ri_rows_data_3d   <= 'd0 ;
        r_vlid_h_async_1d <= 1'b0;
        r_vlid_h_async_2d <= 1'b0;
        r_vlid_h_async_3d <= 1'b0;
        r_v_async_1d      <= 1'b0;
        r_v_async_2d      <= 1'b0;
        r_v_async_3d      <= 1'b0;
    end else begin
        ri_h_async        <= i_h_async       ;
        ri_v_async        <= i_v_async       ;
        ri_padd_remainder <= i_padd_remainder;
        ri_rows_data      <= i_rows_data     ;
        ri_rows_data_1d   <= ri_rows_data    ;
        ri_rows_data_2d   <= ri_rows_data_1d ;
        ri_rows_data_3d   <= ri_rows_data_2d ;
        r_vlid_h_async_1d <= w_vlid_h_async  ;
        r_vlid_h_async_2d <= r_vlid_h_async_1d;
        r_vlid_h_async_3d <= r_vlid_h_async_2d;
        r_v_async_1d      <= ri_v_async       ;
        r_v_async_2d      <= r_v_async_1d     ;
        r_v_async_3d      <= r_v_async_2d     ;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) r_sustained_en <= 1'b0;
    else if(!ri_h_async) r_sustained_en <= 1'b0;
    else if(r_rd_en1 && w_vlid_h_async) r_sustained_en <= 1'b1;
    else r_sustained_en <= r_sustained_en;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_pixel_cnt <= 16'd0;
    else if(w_h_async_negedge)
        r_pixel_cnt <=16'd0;
    else if(w_h_async_posedge || r_pixel_cnt)
        r_pixel_cnt <= r_pixel_cnt + 16'd1;
    else
        r_pixel_cnt <= 16'd0;
end

//fifo1
always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_wr_en1 <= 1'b0;
    else if(w_vlid_h_async && r_pixel_cnt < P_EXPAND_WIDTH-1) 
        r_wr_en1 <= 1'b1;
    else
        r_wr_en1 <= 1'b0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) r_din1 <= 'd0;
    else if(w_vlid_h_async) r_din1 <= ri_rows_data;
    else r_din1 <= 'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) begin
        r_rd_en1 <= 1'b0;
    end else if(r_wr_en1) begin
        r_rd_en1 <= 1'b1;
    end else begin
        r_rd_en1 <= 1'b0;
    end
end
//fifo2
always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) r_wr_en2 <= 1'b0;
    else if(r_wr_en1) r_wr_en2 <= 1'b1;
    else r_wr_en2 <= 1'b0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)  r_rd_en2 <= 1'b0;
    else if(r_wr_en2) r_rd_en2 <= 1'b1;
    else r_rd_en2 <= 1'b0;
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) begin
        ro_rows_col1 <= 'd0;
        ro_rows_col2 <= 'd0;
        ro_rows_col3 <= 'd0;
    end else if(r_sustained_en) begin
        ro_rows_col1 <= w_dout2;
        ro_rows_col2 <= w_dout1;
        ro_rows_col3 <= ri_rows_data_1d;
    end else begin
        ro_rows_col1 <= 'd0;
        ro_rows_col2 <= 'd0;
        ro_rows_col3 <= 'd0;
    end
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) 
        ro_v_sync <= 1'b0;
    else
        ro_v_sync <= r_v_async_3d;
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_sync <= 1'b0;
    else if(!r_wr_en2)
        ro_h_sync <= 1'b0;
    else if(r_rd_en2)
        ro_h_sync <= 1'b1;
    else
        ro_h_sync <= ro_h_sync;
end

initial_3raws_async_fifo #(
    .P_DATA_WIDTH (P_ROWS_DATA_WIDTH),
    .P_FIFO_DEPTH (16)
)u_initial_3raws_async_fifo(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .wr_en1       ( r_wr_en1     ),
    .din1         ( r_din1       ),
    .rd_en1       ( r_rd_en1     ),
    .dout1        ( w_dout1      ),
    .full1        (),
    .empty1       (),
    .wr_en2       ( r_wr_en2     ),
    .din2         ( w_din2       ),
    .rd_en2       ( r_rd_en2     ),
    .dout2        ( w_dout2      ),
    .full2        (),
    .empty2       ()
);
endmodule
