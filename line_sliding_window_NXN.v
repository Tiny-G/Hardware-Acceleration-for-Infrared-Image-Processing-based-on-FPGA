`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/09 16:00:04
// Design Name: 
// Module Name: line_sliding_window_NXN
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


module line_sliding_window_NXN
#(
    parameter P_DATA_WIDTH      =   20     ,
    parameter P_IMAGE_WIDTH     =   256    ,
    parameter P_IMAGE_HEIGHT    =   256    ,
    parameter P_SLIDE_WINDOW_N  =   9      ,
    parameter P_PADDING_CYCLES  =   4       
)
(
    input                           i_clk       ,
    input                           i_rst_n     ,
    input                           i_h_sync    ,
    input                           i_v_sync    ,
    input   [P_DATA_WIDTH-1:0]      i_data      ,

    output                          o_h_aync    ,
    output                          o_v_sync    ,
    output  [P_DATA_WIDTH*P_SLIDE_WINDOW_N*P_SLIDE_WINDOW_N-1:0]    o_data_matrix //row1:high middle low/roow2:high middle low...
);
localparam  P_FIFO_LTANCY = 1 ;
localparam  P_ACTUAL_IMG_WIDTH   = P_IMAGE_WIDTH + P_PADDING_CYCLES*2   ;
localparam  P_ACTUAL_IMG_HEIGHT  = P_IMAGE_HEIGHT + P_PADDING_CYCLES*2  ;

//input register
reg                             ri_h_sync           ;
reg                             ri_v_sync           ;
reg     [P_DATA_WIDTH-1:0]      ri_data             ;

reg                             ri_h_sync_1d        ;
reg                             ri_h_sync_2d        ;
reg                             ri_v_sync_1d        ;
reg                             ri_v_sync_2d        ;
//output register
reg                             ro_h_sync           ;
reg                             ro_v_sync           ;
reg     [P_DATA_WIDTH*P_SLIDE_WINDOW_N*P_SLIDE_WINDOW_N-1:0]    ro_data_matrix;

//temporary registers
reg                             r_h_valid_sync_1d   ;
wire                            w_h_valid_sync      ;    //valid h sync
wire                            w_h_sync_pos        ;
wire                            w_h_sync_neg        ;
reg                             r_get_en            ;
reg     [15:0]                  r_get_internal_cnt  ;
reg     [15:0]                  r_start_internal_cnt;
reg     [15:0]                  r_rows_cnt          ;

assign w_h_valid_sync = ri_h_sync && ri_v_sync;
assign w_h_sync_pos   = w_h_valid_sync && !r_h_valid_sync_1d;
assign w_h_sync_neg   = !w_h_valid_sync && r_h_valid_sync_1d;

assign o_h_aync         = ro_h_sync     ;
assign o_v_sync         = ro_v_sync     ;
assign o_data_matrix    = ro_data_matrix;

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_h_sync       <= 1'd0;
        ri_v_sync       <= 1'd0;
        ri_data         <=  'd0;
    end else begin
        ri_h_sync       <= i_h_sync ;
        ri_v_sync       <= i_v_sync ;
        ri_data         <= i_data   ;
    end
end

//delay
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        r_h_valid_sync_1d <= 1'd0;
        ri_h_sync_1d <= 1'd0;
        ri_h_sync_2d <= 1'd0;
        ri_v_sync_1d <= 1'd0;
        ri_v_sync_2d <= 1'd0;
    end else begin
        r_h_valid_sync_1d <= w_h_valid_sync ;
        ri_h_sync_1d <= ri_h_sync       ;
        ri_h_sync_2d <= ri_h_sync_1d    ;
        ri_v_sync_1d <= ri_v_sync       ;
        ri_v_sync_2d <= ri_v_sync_1d    ;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_get_en  <= 1'd0;
    else if(w_h_sync_pos && r_get_internal_cnt != 0)
        r_get_en  <= 1'd1;
    else if(!ro_v_sync)
        r_get_en  <= 1'd0;
    else
        r_get_en  <= r_get_en;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_get_internal_cnt  <= 16'd0;
    else if(!r_get_en && (w_h_sync_neg || r_get_internal_cnt))
        r_get_internal_cnt  <= r_get_internal_cnt + 16'd1;
    else if(!ro_v_sync)
        r_get_internal_cnt  <= 16'd0;
    else
        r_get_internal_cnt  <= r_get_internal_cnt;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_start_internal_cnt <= 16'd0;
    else if(r_start_internal_cnt == r_get_internal_cnt && r_get_en)
        r_start_internal_cnt <= 16'd0;
    else if(w_h_sync_neg || r_start_internal_cnt)
        r_start_internal_cnt <= r_start_internal_cnt + 16'd1;
    else
        r_start_internal_cnt <= 16'd0;
end

//generate the corressponding fifo in accordance with the sliding window size
wire    [P_SLIDE_WINDOW_N-1:0]  w_fifo_full     ;
reg     [P_SLIDE_WINDOW_N-1:0]  r_fifo_wr_en    ;
reg     [P_DATA_WIDTH-1:0]      r_fifo_din          [P_SLIDE_WINDOW_N-1:0];
reg     [P_SLIDE_WINDOW_N-1:0]  r_fifo_rd_en    ;
wire    [P_DATA_WIDTH-1:0]      w_fifo_dout         [P_SLIDE_WINDOW_N-1:0];
wire    [P_SLIDE_WINDOW_N-1:0]  w_fifo_empty    ;
reg     [15:0]                  r_rd_en_cnt         [P_SLIDE_WINDOW_N-1:0]; //用来计数输出的个数


//add by the input posedge
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_rows_cnt      <= 16'd0;
    else if(!ro_v_sync)
        r_rows_cnt      <= 16'd0;
    else if(w_h_sync_neg)
        r_rows_cnt      <= r_rows_cnt + 16'd1;
    else
        r_rows_cnt      <= r_rows_cnt;
end

genvar i,j;

//
generate
    for(i=0; i<P_SLIDE_WINDOW_N; i=i+1) begin : sliding_window_gen
        always @(posedge i_clk or negedge i_rst_n) begin
            if(!i_rst_n)
                r_rd_en_cnt[i] <= 16'd0;
            else if(r_fifo_rd_en[i] == P_ACTUAL_IMG_WIDTH-1)
                r_rd_en_cnt[i] <= 16'd0;
            else if(r_fifo_rd_en[i])
                r_rd_en_cnt[i] <= r_rd_en_cnt[i] + 1;
            else
                r_rd_en_cnt[i] <= 16'd0;
        end
        if(i == 0)begin
            //wr_en
            always @(posedge i_clk or negedge i_rst_n) begin
                if(!i_rst_n)
                    r_fifo_wr_en[i] <= 1'b0;
                else if(w_h_valid_sync)
                    r_fifo_wr_en[i] <= 1'b1;
                else
                    r_fifo_wr_en[i] <= 1'b0;
            end
            //din
            always @(posedge i_clk or negedge i_rst_n) begin
                if(!i_rst_n)
                    r_fifo_din[i] <=  'd0;
                else if(w_h_valid_sync && !w_fifo_full[i])
                    r_fifo_din[i] <= ri_data;
                else
                    r_fifo_din[i] <=  'd0;
            end
            //rd_en
            always @(posedge i_clk or negedge i_rst_n) begin
                if(!i_rst_n)
                    r_fifo_rd_en[i] <= 1'b0;
                else if(r_rows_cnt >= i+1 &&  r_rd_en_cnt[i] == P_ACTUAL_IMG_WIDTH-1)
                    r_fifo_rd_en[i] <= 1'b0;
                else if(r_rows_cnt >= i+1 && r_start_internal_cnt == r_get_internal_cnt && r_get_en && !w_fifo_empty[i])
                    r_fifo_rd_en[i] <= 1'b1;
                else
                    r_fifo_rd_en[i] <= r_fifo_rd_en[i];
            end
        end else begin
            //wr_en
            always @(posedge i_clk or negedge i_rst_n) begin
                if(!i_rst_n)
                    r_fifo_wr_en[i] <= 1'b0;
                else if(r_fifo_rd_en[i-1])
                    r_fifo_wr_en[i] <= 1'b1;
                else
                    r_fifo_wr_en[i] <= 1'b0;
            end
            //din
            always @(posedge i_clk or negedge i_rst_n) begin
                if(!i_rst_n)
                    r_fifo_din[i] <=  'd0;
                else if(r_fifo_rd_en[i-1])
                    r_fifo_din[i] <= w_fifo_dout[i-1];
                else
                    r_fifo_din[i] <=  'd0;
            end
            //rd_en
            always @(posedge i_clk or negedge i_rst_n) begin
                if(!i_rst_n)
                    r_fifo_rd_en[i] <= 1'b0;
                else if(r_rows_cnt >= i && r_rd_en_cnt[i] == P_ACTUAL_IMG_WIDTH-1)
                    r_fifo_rd_en[i] <= 1'b0;
                else if(r_rows_cnt >= i && r_start_internal_cnt == r_get_internal_cnt && r_get_en && !w_fifo_empty[i])
                    r_fifo_rd_en[i] <= 1'b1;
                else
                    r_fifo_rd_en[i] <= r_fifo_rd_en[i];
            end

        end

        custom_xpm_fifo_async #(
            .P_ASYNC_FIFO_WRITE_WIDTH (P_DATA_WIDTH     ),
            .P_ASYNC_FIFO_WRITE_DEPTH ( 512             ),
            .P_ASYNC_FIFO_READ_WIDTH  (P_DATA_WIDTH     ),
            .P_FIFO_READ_LATENCY      (1                ),
            .P_READ_MODE              ("std"            )
        )custom_xpm_fifo_async_U0(
            .rst_n                    (i_rst_n          ),
            .wr_clk                   (i_clk            ),
            .full                     (w_fifo_full[i]   ),
            .wr_en                    (r_fifo_wr_en[i]  ),
            .din                      (r_fifo_din[i]    ),
            .wr_rst_busy              (),
            .rd_clk                   ( i_clk           ),
            .rd_en                    (r_fifo_rd_en[i]  ),
            .dout                     (w_fifo_dout[i]   ),
            .empty                    (w_fifo_empty[i]  ),
            .rd_rst_busy              ()
        );

    end
endgenerate

// delay data,due to the delay of fifo is 1 cycle,so just only delay 1 cycle
reg     [P_SLIDE_WINDOW_N-1:0]  r_fifo_rd_en_1d ;
generate
    for(i=0; i<P_SLIDE_WINDOW_N; i=i+1) begin : sliding_window_delay_gen
        always @(posedge i_clk or negedge i_rst_n) begin
            if(!i_rst_n)
                r_fifo_rd_en_1d[i] <= 1'b0;
            else
                r_fifo_rd_en_1d[i] <= r_fifo_rd_en[i];
        end
    end
endgenerate


reg     [P_DATA_WIDTH-1:0]      w_sliding_window_buffer [P_SLIDE_WINDOW_N-1:0][P_SLIDE_WINDOW_N-1:0];

generate
    for(i=0; i<P_SLIDE_WINDOW_N; i=i+1) begin : sliding_window_buffer_rows
        for(j=0; j<P_SLIDE_WINDOW_N; j=j+1) begin : sliding_window_buffer_cols
            if(j == 0) begin
                always @(posedge i_clk or negedge i_rst_n) begin
                    if(!i_rst_n)
                        w_sliding_window_buffer[i][j] <=  'd0;
                    else if(r_fifo_rd_en_1d[i])
                        w_sliding_window_buffer[i][j] <= w_fifo_dout[i];
                    else
                        w_sliding_window_buffer[i][j] <=  'd0;
                end
            end else begin  //j>0
                always @(posedge i_clk or negedge i_rst_n) begin
                    if(!i_rst_n)
                        w_sliding_window_buffer[i][j] <=  'd0;
                    else
                        w_sliding_window_buffer[i][j] <= w_sliding_window_buffer[i][j-1];
                end
            end
            
        end
    end
endgenerate

//
reg     [15:0]  r_pixel_cnt;

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_pixel_cnt <= 16'd0;
    else if(r_pixel_cnt == P_ACTUAL_IMG_WIDTH+P_SLIDE_WINDOW_N)
        r_pixel_cnt <= 16'd0;
    else if(r_rows_cnt >= P_SLIDE_WINDOW_N-1 && (w_h_sync_pos || r_pixel_cnt))
        r_pixel_cnt <= r_pixel_cnt + 16'd1;
    else
        r_pixel_cnt <= 16'd0;
end


//output register,the output data is that {row1,row2,row3,row4,row5,row6,row7,row8,row9}
generate
    for(i=0; i<P_SLIDE_WINDOW_N; i=i+1) begin : sliding_window_output_gen
        for(j=0; j<P_SLIDE_WINDOW_N; j=j+1) begin : sliding_window_output_inner_gen
            always @(posedge i_clk or negedge i_rst_n) begin
                if(!i_rst_n)
                    ro_data_matrix[j*P_SLIDE_WINDOW_N*P_DATA_WIDTH+i*P_DATA_WIDTH +: P_DATA_WIDTH] <=  'd0;
                else if(r_pixel_cnt >= P_SLIDE_WINDOW_N+4 &&r_pixel_cnt <= P_SLIDE_WINDOW_N+P_IMAGE_WIDTH+3 && r_rows_cnt >= P_SLIDE_WINDOW_N-1)
                    ro_data_matrix[j*P_SLIDE_WINDOW_N*P_DATA_WIDTH+i*P_DATA_WIDTH +: P_DATA_WIDTH] <= w_sliding_window_buffer[i][j];
                else
                    ro_data_matrix[j*P_SLIDE_WINDOW_N*P_DATA_WIDTH+i*P_DATA_WIDTH +: P_DATA_WIDTH] <=  'd0;
            end
        end
    end
endgenerate

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_sync <= 1'd0;
    else if(r_pixel_cnt >= P_SLIDE_WINDOW_N+4 &&r_pixel_cnt <= P_SLIDE_WINDOW_N+P_IMAGE_WIDTH+3 &&r_rows_cnt >= P_SLIDE_WINDOW_N-1)
        ro_h_sync <= 1'd1;
    else
        ro_h_sync <= 1'd0;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        ro_v_sync <= 1'd0;
    end else begin
        ro_v_sync <= ri_v_sync_2d;
    end
end
endmodule
