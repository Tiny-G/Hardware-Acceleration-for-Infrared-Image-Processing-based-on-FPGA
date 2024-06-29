`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/24 19:34:23
// Design Name: 
// Module Name: line_sliding_window_3X3
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 这是在发现之前滑窗存在问题之后的改进,现在是单行输入,输出为3X3的窗口
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module line_sliding_window_3X3
#(
    parameter P_DATA_WIDTH      = 8     ,
    parameter P_IMAGE_WIDTH     = 258
)
(
    input                           i_clk       ,
    input                           i_rst_n     ,
    input                           i_h_sync    ,
    input                           i_v_sync    ,
    input   [P_DATA_WIDTH-1:0]      i_data      ,

    output                          o_h_aync    ,
    output                          o_v_sync    ,
    output  [P_DATA_WIDTH*3-1:0]    o_data_row3 ,
    output  [P_DATA_WIDTH*3-1:0]    o_data_row2 ,
    output  [P_DATA_WIDTH*3-1:0]    o_data_row1  
);

//input register
reg                             ri_h_sync           ;
reg                             ri_v_sync           ;
reg                             ri_v_sync_1d        ;
reg                             ri_v_sync_2d        ;
reg     [P_DATA_WIDTH-1:0]      ri_data             ;

//output register
reg                             ro_h_aync           ;
reg                             ro_v_sync           ;
reg     [P_DATA_WIDTH*3-1:0]    ro_data_row3        ;
reg     [P_DATA_WIDTH*3-1:0]    ro_data_row2        ;
reg     [P_DATA_WIDTH*3-1:0]    ro_data_row1        ;

//temporary register
reg     [1:0]                   r_line_cnt          ;
reg                             r_h_valid_sync_1d   ;
reg                             r_h_valid_sync_2d   ;
reg                             r_wr_en1            ;
reg     [P_DATA_WIDTH-1:0]      r_din1              ;

reg                             r_first_flag        ;
reg                             r_second_flag       ;
reg     [P_DATA_WIDTH*3-1:0]    r_data_row3_buffer  ;
reg     [P_DATA_WIDTH*3-1:0]    r_data_row2_buffer  ;
reg     [P_DATA_WIDTH*3-1:0]    r_data_row1_buffer  ;
reg     [1:0]                   r_rows_cnt          ;
reg     [15:0]                  r_output_pixel_cnt  ;

wire                            w_rd_en1            ;
wire                            w_rd_en2            ;
wire                            w_h_valid_sync      ;
wire                            w_h_sync_neg        ;
wire                            w_h_sync_pos        ;
wire    [P_DATA_WIDTH-1:0]      w_dout1             ;
wire    [P_DATA_WIDTH-1:0]      w_din2              ;
wire                            w_wr_en2            ;
wire    [P_DATA_WIDTH-1:0]      w_dout2             ;
wire                            w_empty1            ;
wire                            w_empty2            ;

assign o_h_aync     = ro_h_aync;
assign o_v_sync     = ro_v_sync;
assign o_data_row3  = ro_data_row3;
assign o_data_row2  = ro_data_row2;
assign o_data_row1  = ro_data_row1;

assign w_h_valid_sync = ri_h_sync & ri_v_sync;
assign w_h_sync_pos   = w_h_valid_sync & ~r_h_valid_sync_1d;
assign w_h_sync_neg   = ~w_h_valid_sync & r_h_valid_sync_1d;
assign w_rd_en1 = w_h_valid_sync && !w_empty1 &&r_first_flag;
assign w_rd_en2 = w_h_valid_sync && !w_empty2 && r_second_flag;

assign w_wr_en2 = w_rd_en1;
assign w_din2 = w_dout1;


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_h_sync       <= 1'd0;
        ri_v_sync       <= 1'd0;
        ri_data         <=  'd0;
        ri_v_sync_1d    <= 1'd0;
        ri_v_sync_2d    <= 1'd0;
    end else begin
        ri_h_sync       <= i_h_sync ;
        ri_v_sync       <= i_v_sync ;
        ri_data         <= i_data   ;
        ri_v_sync_1d    <= ri_v_sync;
        ri_v_sync_2d    <= ri_v_sync_1d;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        r_h_valid_sync_1d <= 1'd0;
        r_h_valid_sync_2d <= 1'd0;
    end else begin
        r_h_valid_sync_1d <= w_h_valid_sync;
        r_h_valid_sync_2d <= r_h_valid_sync_1d;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_rows_cnt <= 2'd0;
    else if(!ri_v_sync)
        r_rows_cnt <= 2'd0;
    else if(w_h_sync_pos && r_rows_cnt <= 2'd2)
        r_rows_cnt   <= r_rows_cnt + 1;
    else
        r_rows_cnt <= r_rows_cnt;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_line_cnt <= 2'd0;
    else if(!ri_v_sync)
        r_line_cnt <= 2'd0;
    else if(w_h_sync_pos)
        r_line_cnt <= r_line_cnt + 2'd1;
    else
        r_line_cnt <= r_line_cnt;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_first_flag <= 1'd0;
    else if(r_rows_cnt == 2'd1 && w_h_sync_neg)
        r_first_flag <= 1'd1;
    else if(!ri_v_sync)
        r_first_flag <= 1'd0;
    else
        r_first_flag <= r_first_flag;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_second_flag <= 1'd0;
    else if(!ri_v_sync)
        r_second_flag <= 1'd0;
    else if(r_rows_cnt == 2'd2 && r_output_pixel_cnt == P_IMAGE_WIDTH+3)
        r_second_flag <= 1'd1;
    else
        r_second_flag <= r_second_flag;
end


//operate the input data to input the FIFO
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_wr_en1 <= 1'd0;
    else if(w_h_sync_neg)
        r_wr_en1 <= 1'd0;
    else if(w_h_sync_pos)
        r_wr_en1 <= 1'd1;
    else
        r_wr_en1 <= r_wr_en1;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_din1 <=  'd0;
    else if(w_h_valid_sync)
        r_din1 <= ri_data;
    else 
        r_din1 <=  'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) 
        r_output_pixel_cnt <= 16'd0;
    else if(r_output_pixel_cnt == P_IMAGE_WIDTH+3)
        r_output_pixel_cnt <= 16'd0;
    else if(w_h_valid_sync || r_output_pixel_cnt)
        r_output_pixel_cnt <= r_output_pixel_cnt + 16'd1;
    else
        r_output_pixel_cnt <= r_output_pixel_cnt;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_data_row3_buffer <=  'd0;
    else if(!ri_v_sync)
        r_data_row3_buffer <=  'd0;
    else if(r_second_flag && w_h_valid_sync && r_output_pixel_cnt <= P_IMAGE_WIDTH+1) begin
        r_data_row3_buffer<= {r_data_row3_buffer[P_DATA_WIDTH*2-1:0],ri_data};
    end else
        r_data_row3_buffer <= 'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_data_row2_buffer <=  'd0;
    else if(!ri_v_sync)
        r_data_row2_buffer <=  'd0;
    else if(r_second_flag && w_h_valid_sync && r_output_pixel_cnt <= P_IMAGE_WIDTH+1) begin
        r_data_row2_buffer<= {r_data_row2_buffer[P_DATA_WIDTH*2-1:0],w_dout1};
    end else
        r_data_row2_buffer <= 'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_data_row1_buffer <=  'd0;
    else if(!ri_v_sync)
        r_data_row1_buffer <=  'd0;
    else if(r_second_flag && w_h_valid_sync && r_output_pixel_cnt <= P_IMAGE_WIDTH+1) begin
        r_data_row1_buffer<= {r_data_row1_buffer[P_DATA_WIDTH*2-1:0],w_dout2};
    end else
        r_data_row1_buffer <= 'd0;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ro_data_row3 <=  'd0;
        ro_data_row2 <=  'd0;
        ro_data_row1 <=  'd0;
    end else if(r_output_pixel_cnt >= 16'd3) begin
        ro_data_row3 <=  r_data_row3_buffer;
        ro_data_row2 <=  r_data_row2_buffer;
        ro_data_row1 <=  r_data_row1_buffer;
    end else begin
        ro_data_row3 <=  'd0;
        ro_data_row2 <=  'd0;
        ro_data_row1 <=  'd0;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ro_v_sync <= 1'd0;
    end else begin
        ro_v_sync <= ri_v_sync_2d;
    end
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_aync <= 1'd0;
    else if(r_second_flag && r_output_pixel_cnt == P_IMAGE_WIDTH+1)
        ro_h_aync <= 1'd0;
    else if(r_second_flag && r_output_pixel_cnt == 16'd3)
        ro_h_aync <= 1'd1;
    else
        ro_h_aync <= ro_h_aync;
end

initial_3raws_async_fifo #(
    .P_DATA_WIDTH (P_DATA_WIDTH ),
    .P_FIFO_DEPTH (512          )
)u_initial_3raws_async_fifo(
    .i_clk        ( i_clk       ),
    .i_rst_n      ( i_rst_n     ),
    .wr_en1       (r_wr_en1     ),
    .din1         (r_din1       ),
    .rd_en1       (w_rd_en1     ),
    .dout1        (w_dout1      ),
    .full1        (),
    .empty1       (w_empty1     ),
    .wr_en2       (w_wr_en2     ),
    .din2         (w_dout1      ),
    .rd_en2       ( w_rd_en2    ),
    .dout2        ( w_dout2     ),
    .full2        (),
    .empty2       (w_empty2     )
);
endmodule
