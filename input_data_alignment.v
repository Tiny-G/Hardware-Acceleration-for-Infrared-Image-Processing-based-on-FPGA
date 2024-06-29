`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/05 13:53:26
// Design Name: 
// Module Name: input_data_alignment
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 以最后输入的数据对齐
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module input_data_alignment
#(
    parameter          P_DATA_WIDTH  = 8     ,
    parameter          P_IMAGE_WIDTH = 256 
)
(
    input                       i_clk       ,
    input                       i_rst_n     ,
    input                       i_h_aync_m  ,
    input                       i_v_aync_m  ,
    input   [P_DATA_WIDTH-1:0]  i_data_m    ,
    input                       i_v_aync_s  ,
    input                       i_h_aync_s  ,
    input   [P_DATA_WIDTH-1:0]  i_data_s    ,

    output                      o_h_aync_m  ,
    output                      o_v_aync_m  ,
    output  [P_DATA_WIDTH-1:0]  o_data_m    ,
    output                      o_v_aync_s  ,
    output                      o_h_aync_s  ,
    output  [P_DATA_WIDTH-1:0]  o_data_s     
);

//input regisiters
reg                             ri_h_aync_m ;
reg                             ri_v_aync_m ;
reg     [P_DATA_WIDTH-1:0]      ri_data_m   ;
reg                             ri_v_aync_s ;
reg                             ri_h_aync_s ;
reg     [P_DATA_WIDTH-1:0]      ri_data_s   ;
//output registers
reg                             ro_h_aync_m ;
reg                             ro_v_aync_m ;
reg     [P_DATA_WIDTH-1:0]      ro_data_m   ;
reg     [P_DATA_WIDTH-1:0]      ro_data_s   ;

//temporary registers
reg                             r_rd_en     ;   //fifoM、fifoS读使能信号
reg     [15:0]                  r_pixel_cnt ;   //当前行像素计数器

wire                            w_empty_M   ;
wire                            w_empty_S   ;
wire    [P_DATA_WIDTH-1:0]      w_dout_M    ;
wire    [P_DATA_WIDTH-1:0]      w_dout_S    ;


assign o_h_aync_m  = ro_h_aync_m ;
assign o_v_aync_m  = ro_v_aync_m ;
assign o_data_m    = ro_data_m   ;
assign o_v_aync_s  = ro_v_aync_m ;
assign o_h_aync_s  = ro_h_aync_m ;
assign o_data_s    = ro_data_s   ;

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
        r_rd_en <= 1'd0;
    else if(!w_empty_M && !w_empty_S)
        r_rd_en <= 1'd1;
    else
        r_rd_en <= 1'd0;
end

always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_data_m <=  'd0;
    else if(r_rd_en)
        ro_data_m <= w_dout_M;
    else
        ro_data_m <=  'd0;
end
always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_data_s <=  'd0;
    else if(r_rd_en)
        ro_data_s <= w_dout_S;
    else
        ro_data_s <=  'd0;
end

always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_aync_m <= 1'd0;
    else if(r_pixel_cnt == P_IMAGE_WIDTH-1)
        ro_h_aync_m <= 1'd0;
    else if(r_rd_en)
        ro_h_aync_m <= 1'd1;
    else
        ro_h_aync_m <= ro_h_aync_m;
end

always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_pixel_cnt <= 16'd0;
    else if(r_pixel_cnt == P_IMAGE_WIDTH-1)
        r_pixel_cnt <= 16'd0;
    else if(ro_h_aync_m)
        r_pixel_cnt <= r_pixel_cnt + 1;
    else 
        r_pixel_cnt <= 1'd0;
end

always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ro_data_m <=  'd0;
        ro_data_s <=  'd0;
    end else if(r_rd_en && !w_empty_M && !w_empty_S) begin
        ro_data_m <= w_dout_M;
        ro_data_s <= w_dout_S;
    end else begin
        ro_data_m <=  'd0;
        ro_data_s <=  'd0;
    end
end

always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_v_aync_m <= 1'd0;
    else
        ro_v_aync_m <= ri_v_aync_s;
end

custom_xpm_fifo_async #(
    .P_ASYNC_FIFO_WRITE_WIDTH ( P_DATA_WIDTH ),
    .P_ASYNC_FIFO_WRITE_DEPTH ( 512          ),
    .P_ASYNC_FIFO_READ_WIDTH  ( P_DATA_WIDTH )
)
custom_xpm_fifo_async_M(
    .rst_n                    (i_rst_n      ),
    .wr_clk                   (i_clk        ),
    .full                     (),
    .wr_en                    (ri_h_aync_m  ),
    .din                      (ri_data_m    ),
    .wr_rst_busy              (),
    .rd_clk                   (i_clk        ),
    .rd_en                    (r_rd_en      ),
    .dout                     (w_dout_M     ),
    .empty                    (w_empty_M    ),
    .rd_rst_busy              ()
);

custom_xpm_fifo_async #(
    .P_ASYNC_FIFO_WRITE_WIDTH ( P_DATA_WIDTH ),
    .P_ASYNC_FIFO_WRITE_DEPTH ( 512          ),
    .P_ASYNC_FIFO_READ_WIDTH  ( P_DATA_WIDTH )
)
custom_xpm_fifo_async_S(
    .rst_n                    (i_rst_n      ),
    .wr_clk                   (i_clk        ),
    .full                     (),
    .wr_en                    (ri_h_aync_s  ),
    .din                      (ri_data_s    ),
    .wr_rst_busy              (),
    .rd_clk                   (i_clk        ),
    .rd_en                    (r_rd_en      ),
    .dout                     (w_dout_S     ),
    .empty                    (w_empty_S    ),
    .rd_rst_busy              ()
);
endmodule
