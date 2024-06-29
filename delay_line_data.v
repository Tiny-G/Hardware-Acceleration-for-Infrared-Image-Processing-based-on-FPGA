`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/25 19:40:44
// Design Name: 
// Module Name: delay_line_data
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


module delay_line_data
#(
    parameter P_DATA_WIDTH  = 8 ,
    parameter P_DELAY_TIMES = 16, //must be greater than 16,minimum value is 16，at same time,the value of P_DELAY_TIMES should be a power of 2
    parameter P_IMAGE_WIDTH = 256
    )
(
    input                       i_clk       ,
    input                       i_rst_n     ,
    input                       i_v_sync    ,
    input                       i_h_sync    ,
    input  [P_DATA_WIDTH-1:0]   i_data      ,

    output                      o_h_sync    ,
    output                      o_v_sync    ,
    output [P_DATA_WIDTH-1:0]   o_data      
);

//input registers
reg                         ri_v_sync       ;
reg                         ri_v_sync_1d    ;
reg                         ri_h_sync       ;
reg     [P_DATA_WIDTH-1:0]  ri_data         ;

//output registers
reg                         ro_h_sync       ;
reg                         ro_v_sync       ;

//temporary registers
reg     [15:0]              r_row_delay_cnt ;
reg     [15:0]              r_frame_delay_cnt ;
reg     [15:0]              r_row_end_cnt   ;
reg     [15:0]              r_frame_end_cnt ;
reg     [15:0]              r_get_interval_cnt  ;
reg                         r_h_sync_1d     ;
reg                         r_wr_en         ;
reg                         r_rd_en         ;
reg                         r_rd_en_1d      ;
reg     [P_DATA_WIDTH-1:0]  r_din           ;
reg     [P_DATA_WIDTH-1:0]  ro_data         ;
reg     [15:0]              r_pixel_cnt     ;
reg                         r_cnt_work_en   ;
reg     [15:0]              r_interval_cnt  ;


wire    [P_DATA_WIDTH-1:0]  w_dout          ;
wire                        w_h_sync        ;
wire                        w_full          ;
wire                        w_empty         ;
wire                        w_h_sync_pos    ;
wire                        w_h_sync_neg    ;
wire                        w_v_sync_pos    ;
wire                        w_v_sync_neg    ;

assign o_h_sync = ro_h_sync;
assign o_v_sync = ro_v_sync;
assign o_data   = ro_data  ;

assign w_h_sync     = ri_v_sync & ri_h_sync;
assign w_h_sync_pos = !r_h_sync_1d && w_h_sync;
assign w_h_sync_neg = r_h_sync_1d && !w_h_sync;
assign w_v_sync_pos = !ri_v_sync_1d && ri_v_sync;
assign w_v_sync_neg = ri_v_sync_1d && !ri_v_sync;

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        ri_v_sync    <= 1'b0;
        ri_v_sync_1d <= 1'b0;
        ri_h_sync    <= 1'b0;
        r_h_sync_1d  <= 1'b0;
        ri_data      <=  'b0;
        r_rd_en_1d   <= 1'b0;
    end else begin
        ri_v_sync    <= i_v_sync;
        ri_v_sync_1d <= ri_v_sync;
        ri_h_sync    <= i_h_sync;
        r_h_sync_1d  <= w_h_sync;
        ri_data      <= i_data  ;
        r_rd_en_1d   <= r_rd_en;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_frame_delay_cnt  <= 16'd0;
    else if(r_frame_delay_cnt == P_DELAY_TIMES)
        r_frame_delay_cnt  <= 16'd0;
    else if(w_v_sync_pos || r_frame_delay_cnt)
        r_frame_delay_cnt  <= r_frame_delay_cnt + 16'd1;
    else
        r_frame_delay_cnt  <= r_frame_delay_cnt;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_row_delay_cnt  <= 16'd0;
    else if(!ri_v_sync)
        r_row_delay_cnt  <= 16'd0;
    else if((w_h_sync_pos || r_row_delay_cnt)&&r_row_delay_cnt < P_DELAY_TIMES)
        r_row_delay_cnt  <= r_row_delay_cnt + 16'd1;
    else
        r_row_delay_cnt  <= r_row_delay_cnt;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_row_end_cnt  <= 16'd0;
    else if(r_row_end_cnt == P_DELAY_TIMES)
        r_row_end_cnt  <= 16'd0;
    else if(w_h_sync_neg || r_row_end_cnt)
        r_row_end_cnt  <= r_row_end_cnt + 16'd1;
    else
        r_row_end_cnt  <= 16'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_frame_end_cnt  <= 16'd0;
    else if(r_frame_end_cnt == P_DELAY_TIMES-1)
        r_frame_end_cnt  <= 16'd0;
    else if(w_v_sync_neg || r_frame_end_cnt)
        r_frame_end_cnt  <= r_frame_end_cnt + 16'd1;
    else
        r_frame_end_cnt  <= 16'd0;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_wr_en <= 1'b0;
    else if(w_h_sync)
        r_wr_en <= 1'b1;
    else
        r_wr_en <= 1'b0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_din <= 'b0;
    else if(w_h_sync)
        r_din <= ri_data;
    else
        r_din <= 'b0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_rd_en <= 1'b0;
    else if(r_row_delay_cnt == P_DELAY_TIMES && w_h_sync)
        r_rd_en <= 1'b1;
    else if(r_interval_cnt == r_get_interval_cnt && r_get_interval_cnt!=0 && !w_empty)
        r_rd_en <= 1'b1;
    else if(r_pixel_cnt == P_IMAGE_WIDTH-1)
        r_rd_en <= 1'b0;
    else
        r_rd_en <= r_rd_en;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_interval_cnt <= 16'd0;
    else if(r_interval_cnt == r_get_interval_cnt && r_get_interval_cnt!=0)
        r_interval_cnt <= 16'd0;
    else if(((!r_rd_en && r_rd_en_1d)||r_interval_cnt)&&r_cnt_work_en)
        r_interval_cnt <= r_interval_cnt + 16'd1;
    else
        r_interval_cnt <= 16'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_pixel_cnt <= 16'd0;
    else if(r_pixel_cnt == P_IMAGE_WIDTH-1)
        r_pixel_cnt <= 16'd0;
    else if(r_rd_en)
        r_pixel_cnt <= r_pixel_cnt + 16'd1;
    else
        r_pixel_cnt <= 16'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_cnt_work_en <= 1'b0;
    else if(!ri_v_sync)
        r_cnt_work_en <= 1'b0;
    else if(w_h_sync_pos && r_get_interval_cnt !=0)
        r_cnt_work_en <= 1'b1;
    else
        r_cnt_work_en <= r_cnt_work_en;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_get_interval_cnt <= 16'd0;
    else if(!ri_v_sync)
        r_get_interval_cnt <= 16'd0;
    else if((w_h_sync_neg || r_get_interval_cnt) && !r_cnt_work_en)
        r_get_interval_cnt <= r_get_interval_cnt + 16'd1;
    else
        r_get_interval_cnt <= r_get_interval_cnt;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_sync <= 1'b0;
    else if(r_rd_en)
        ro_h_sync <= 1'b1;
    else
        ro_h_sync <= 1'b0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_v_sync <= 1'b0;
    else if(r_frame_delay_cnt == P_DELAY_TIMES)
        ro_v_sync <= 1'b1;
    else if(r_frame_end_cnt == P_DELAY_TIMES)
        ro_v_sync <= 1'b0;
    else
        ro_v_sync <= ro_v_sync;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_data <= 'd0;
    else if(r_rd_en)
        ro_data <= w_dout;
    else
        ro_data <= 'd0;
end

custom_xpm_fifo_async #(
    .P_ASYNC_FIFO_WRITE_WIDTH (P_DATA_WIDTH )   ,
    .P_ASYNC_FIFO_WRITE_DEPTH (4096         )   ,
    .P_ASYNC_FIFO_READ_WIDTH  (P_DATA_WIDTH )   
)custom_xpm_fifo_async_inst (
    .rst_n                    (i_rst_n      ),
    .wr_clk                   (i_clk        ),
    .full                     (w_full       ),
    .wr_en                    (r_wr_en      ),
    .din                      (r_din        ),
    .wr_rst_busy              (),
    .rd_clk                   (i_clk        ),
    .rd_en                    (r_rd_en),
    .dout                     (w_dout       ),
    .empty                    (w_empty      ),
    .rd_rst_busy              ()
);

endmodule
