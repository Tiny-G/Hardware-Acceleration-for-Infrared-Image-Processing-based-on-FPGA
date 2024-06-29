`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/24 21:56:41
// Design Name: 
// Module Name: parallel_3rows2serial_frame
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 串转并行模块，将3行的输入数据转换为1行的输出数据
// 之所以有i_source_h_sync，是因为不知道行之间的间隔
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module parallel_3rows2serial_frame
#(
    parameter   P_DATA_WIDTH    =   8           ,
    parameter   P_ROW_WIDTH     =   256         ,
    parameter   P_ADDR_WIDTH    =   12
)
(
    input                       i_clk               ,
    input                       i_rst_n             ,
    input                       i_h_sync            ,
    input                       i_v_sync            ,
    input                       i_source_h_sync     ,
    input [P_DATA_WIDTH*3-1:0]  i_data              ,
    input                       i_remainder_signal  ,

    output                      o_h_sync            ,
    output                      o_v_sync            ,
    output [P_DATA_WIDTH-1:0]   o_data  
);

localparam         P_MULTI_ROWS_NUM = P_ROW_WIDTH/3 ;

//input registers
reg                         ri_h_sync           ;
reg                         ri_v_sync           ;
reg                         ri_source_h_sync    ;
reg                         ri_source_h_sync_1d ;
reg [P_DATA_WIDTH*3-1:0]    ri_data             ;
reg [P_DATA_WIDTH*3-1:0]    ri_data_1d          ;
reg                         ri_remainder_signal ;

//output registers
reg                         ro_h_sync           ;
reg                         ro_h_sync_1d        ;
reg                         ro_v_sync           ;
reg [P_DATA_WIDTH-1:0]      ro_data             ;

//temp registers
reg                         r_fisrt_work_en     ;
reg                         r_cnt_work_en       ;
reg [15:0]                  r_get_distance_cnt  ;
reg                         r_wea1              ;
reg [P_DATA_WIDTH-1:0]      r_dina1             ;
reg [P_ADDR_WIDTH-1:0]      r_addra1            ;
reg                         r_wea2              ;
reg [P_DATA_WIDTH-1:0]      r_dina2             ;
reg [P_ADDR_WIDTH-1:0]      r_addra2            ;
reg [P_ADDR_WIDTH-1:0]      r_addrb1            ;
reg                         r_enb1              ;
reg                         r_enb1_1d           ;
reg                         r_enb1_2d           ;
reg [P_ADDR_WIDTH-1:0]      r_addrb2            ;
reg                         r_enb2              ;
reg                         r_enb2_1d           ;
reg                         r_enb2_2d           ;
reg [1:0]                   r_output_rows_num   ;
reg [15:0]                  r_actual_distan_cnt ;
reg [15:0]                  r_output_pixel_cnt  ;
reg [3:0]                   r_check_read_clean  ; // if write data into tdram,the value of this register will be  added 1,if read data from tdram,the value of this register will be  minus 1
reg                         r_h_sync_valid_1d   ;
reg [15:0]                  r_rows_cnt          ;
reg                         r_wra12_work_en     ;
reg                         r_enb12_work_en     ;
reg                         r_ram_enb_work_en   ;

reg [P_ADDR_WIDTH-1:0]      r_ram_addra         ;
reg [P_ADDR_WIDTH-1:0]      r_ram_addrb         ;
reg                         r_ram_enb           ;
reg                         r_ram_enb_1d        ;
reg                         r_ram_enb_2d        ;
reg                         r_ram_wr_en_1d      ;

wire[P_DATA_WIDTH*3-1:0]    w_ram_doutb         ;
wire                        w_ram_wr_en         ;
wire[P_DATA_WIDTH*3-1:0]    w_ram_din           ;


wire                        w_source_h_sync_neg ;
wire                        w_source_h_sync_pos ;
wire                        w_h_sync_valid      ;
wire                        w_output_hsync_pos  ;
wire                        w_output_hsync_neg  ;
wire [P_DATA_WIDTH-1:0]     w_doutb1            ;
wire [P_DATA_WIDTH-1:0]     w_doutb2            ;
wire [P_DATA_WIDTH-1:0]     w_get_remainder     ;
wire                        w_h_sync_valid_pos  ;
wire                        w_h_sync_valid_neg  ;
wire                        w_r_enb1_pos        ;
wire                        w_r_enb2_pos        ;
wire                        w_r_ram_wr_pos      ;
wire                        w_ram_enb_pos       ;




assign  o_h_sync = ro_h_sync ;
assign  o_v_sync = ro_v_sync ;
assign  o_data   = ro_data   ;
assign  w_r_enb1_pos = r_enb1 && !r_enb1_1d;
assign  w_r_enb2_pos = r_enb2 && !r_enb2_1d;
assign  w_h_sync_valid_pos = w_h_sync_valid && !r_h_sync_valid_1d;
assign  w_h_sync_valid_neg = !w_h_sync_valid && r_h_sync_valid_1d;
assign  w_source_h_sync_pos = ri_source_h_sync && !ri_source_h_sync_1d;
assign  w_source_h_sync_neg = !ri_source_h_sync && ri_source_h_sync_1d;
assign  w_output_hsync_pos = ro_h_sync && !ro_h_sync_1d;
assign  w_output_hsync_neg = !ro_h_sync && ro_h_sync_1d;
assign  w_h_sync_valid = ri_h_sync && ri_v_sync;
assign  w_get_remainder = ri_remainder_signal?ri_data[P_DATA_WIDTH-1:0]:'d0;
assign  w_ram_wr_en = r_rows_cnt == P_MULTI_ROWS_NUM ?  r_h_sync_valid_1d:1'd0;
assign  w_ram_din  = w_ram_wr_en ?ri_data_1d : 'd0;
assign  w_r_ram_wr_pos = !r_ram_wr_en_1d && w_ram_wr_en;
assign  w_ram_enb_pos = r_ram_enb && !r_ram_enb_1d;
assign  w_ram_enb_neg = !r_ram_enb && r_ram_enb_1d;

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_h_sync           <= 1'b0;
        ri_v_sync           <= 1'b0;
        ri_source_h_sync    <= 1'b0;
        ri_source_h_sync_1d <= 1'b0;
        ri_data             <= 'd0 ;
        ri_data_1d          <= 'd0 ;
        ro_h_sync_1d        <= 1'b0;
        ri_remainder_signal <= 1'b0;
        r_h_sync_valid_1d   <= 1'b0;
        r_enb1_1d           <= 1'b0;
        r_enb1_2d           <= 1'b0;
        r_enb2_1d           <= 1'b0;
        r_enb2_2d           <= 1'b0;
        r_ram_wr_en_1d      <= 1'b0;
        r_ram_enb_1d        <= 1'd0;
        r_ram_enb_2d        <= 1'd0;
    end else begin
        ri_h_sync           <= i_h_sync         ;
        ri_v_sync           <= i_v_sync         ;
        ri_source_h_sync    <= i_source_h_sync  ;
        ri_source_h_sync_1d <= ri_source_h_sync ;
        ri_data             <= i_data           ;
        ri_data_1d          <= ri_data          ;
        ro_h_sync_1d        <= ro_h_sync        ;
        ri_remainder_signal <= i_remainder_signal;
        r_h_sync_valid_1d   <= w_h_sync_valid   ;
        r_enb1_1d           <= r_enb1           ;
        r_enb1_2d           <= r_enb1_1d        ;
        r_enb2_1d           <= r_enb2           ;
        r_enb2_2d           <= r_enb2_1d        ;
        r_ram_wr_en_1d      <= w_ram_wr_en      ;
        r_ram_enb_1d        <= r_ram_enb        ;
        r_ram_enb_2d        <= r_ram_enb_1d     ;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_fisrt_work_en <= 1'd0;
    else if(!ri_v_sync)
        r_fisrt_work_en <= 1'd0;
    else if(w_source_h_sync_neg)
        r_fisrt_work_en <= 1'd1;
    else
        r_fisrt_work_en <= r_fisrt_work_en;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_cnt_work_en <= 1'd0;
    else if(w_source_h_sync_pos)
        r_cnt_work_en <= 1'd0;
    else if(w_source_h_sync_neg && !r_fisrt_work_en)
        r_cnt_work_en <= 1'd1;
    else
        r_cnt_work_en <= r_cnt_work_en;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_get_distance_cnt <= 16'd0;
    else if(!ri_v_sync)
        r_get_distance_cnt <= 16'd0;
    else if(r_cnt_work_en)
        r_get_distance_cnt <= r_get_distance_cnt + 16'd1;
    else
        r_get_distance_cnt <= r_get_distance_cnt;
end

reg [1:0]   r_ram_rows_cnt;
always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_ram_rows_cnt <= 2'd0;
    else if(w_ram_enb_pos)
        r_ram_rows_cnt <= r_ram_rows_cnt + 2'd1;
    else if(r_ram_rows_cnt == 2'd3 && !ro_v_sync)
        r_ram_rows_cnt <= 2'd0;
    else
        r_ram_rows_cnt <= r_ram_rows_cnt;
end

//control data output when two rows of bottom inputted tdram
always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_data <= 'd0;
    else if(w_h_sync_valid)
        ro_data <= ri_data[P_DATA_WIDTH*3-1:P_DATA_WIDTH*2];
    else if(r_enb1_2d)
        ro_data <= w_doutb1;
    else if(r_enb2_2d)
        ro_data <= w_doutb2;
    else if(r_ram_enb_2d)
        case (r_ram_rows_cnt)
                1:ro_data <= w_ram_doutb[P_DATA_WIDTH*3-1:P_DATA_WIDTH*2];
                2:ro_data <= w_ram_doutb[P_DATA_WIDTH*2-1:P_DATA_WIDTH];
                3:ro_data <= w_ram_doutb[P_DATA_WIDTH-1:0];
            default : ro_data <= 'd0;
        endcase
    else
        ro_data <= 'd0;
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_sync <= 1'd0;
    else if(w_h_sync_valid)
        ro_h_sync <= 1'd1;
    else if( r_enb1_2d|| r_enb2_2d ||r_ram_enb_2d)
        ro_h_sync <= 1'd1;
    else
        ro_h_sync <= 1'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ro_v_sync <= 1'd0;
    else
        ro_v_sync <= ri_v_sync;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_wra12_work_en <= 1'd0;
    else if(r_rows_cnt == P_MULTI_ROWS_NUM-1 && w_h_sync_valid_neg)
        r_wra12_work_en <= 1'd0;
    else if(r_rows_cnt >= 0 && r_rows_cnt < P_MULTI_ROWS_NUM-1) 
        r_wra12_work_en <= 1'd1;
    else
        r_wra12_work_en <= r_wra12_work_en;
end
//control ipnut two rows data of bottom
always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_wea1 <= 1'd0;
    else if(w_h_sync_valid && !ri_remainder_signal && r_wra12_work_en)
        r_wea1 <= 1'd1;
    else if(w_get_remainder == 8'd2)
        r_wea1 <= 1'd1;
    else
        r_wea1 <= 1'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_dina1 <= 'd0;
    else if(w_h_sync_valid  && !ri_remainder_signal )
        r_dina1 <= ri_data[P_DATA_WIDTH*2-1:P_DATA_WIDTH];
    else if(w_get_remainder == 8'd2)
        r_dina1 <= ri_data[P_DATA_WIDTH*2-1:P_DATA_WIDTH];
    else
        r_dina1 <= 'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_addra1 <= 'd0;
    else if(r_wea1)
        r_addra1 <= r_addra1+1;
    else
        r_addra1 <= 'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_wea2 <= 1'd0;
    else if(w_h_sync_valid  && !ri_remainder_signal && r_wra12_work_en)
        r_wea2 <= 1'd1;
    else
        r_wea2 <= 1'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_dina2 <= 'd0;
    else if(w_h_sync_valid  && !ri_remainder_signal)
        r_dina2 <= ri_data[P_DATA_WIDTH-1:0];
    else
        r_dina2 <= 'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_addra2 <= 'd0;
    else if(r_wea2)
        r_addra2 <= r_addra2+1;
    else
        r_addra2 <= 'd0;
end

//read two rows data of bottom from tdram
always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_output_rows_num <= 2'd0;
    else if(!ro_v_sync)
        r_output_rows_num <= 2'd0;
    else if(r_output_rows_num == 2'd3 && w_output_hsync_pos)
        r_output_rows_num <= 2'd0;
    else if(w_output_hsync_neg)
        r_output_rows_num <= r_output_rows_num+1;
    else
        r_output_rows_num <= r_output_rows_num;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_actual_distan_cnt <= 16'd0;
    else if(r_actual_distan_cnt == r_get_distance_cnt)
        r_actual_distan_cnt <= 16'd0;
    else if(w_output_hsync_neg ||r_actual_distan_cnt)
        r_actual_distan_cnt <= r_actual_distan_cnt+16'd1;
    else
        r_actual_distan_cnt <= 16'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_output_pixel_cnt <= 16'd0;
    else if(r_enb1 || r_enb2 || r_ram_enb)
        r_output_pixel_cnt <= r_output_pixel_cnt+16'd1;
    else
        r_output_pixel_cnt <= 16'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_enb12_work_en <= 1'd0;
    else if(r_rows_cnt == P_MULTI_ROWS_NUM && r_output_rows_num == 2'd3)
        r_enb12_work_en <= 1'd0;
    else if(r_rows_cnt >= 0 && r_rows_cnt < P_MULTI_ROWS_NUM)
        r_enb12_work_en <= 1'd1;
    else
        r_enb12_work_en <= r_enb12_work_en;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_enb1 <= 1'd0;
    else if(r_output_pixel_cnt == P_ROW_WIDTH-1)
        r_enb1 <= 1'd0;
    else if(r_output_rows_num == 2'd1 && r_actual_distan_cnt == r_get_distance_cnt-6 && r_enb12_work_en) //提前4周期读,以此避免最后输入的多行因为间隔为正常间隔的1/3导致数据被覆盖的问题
        r_enb1 <= 1'd1;
    else
        r_enb1 <= r_enb1;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_addrb1 <= 'd0;
    else if(r_enb1)
        r_addrb1 <= r_addrb1+1;
    else
        r_addrb1 <= 'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_enb2 <= 1'd0;
    else if(r_output_pixel_cnt == P_ROW_WIDTH-1)
        r_enb2 <= 1'd0;
    else if(r_output_rows_num == 2'd2 && r_actual_distan_cnt == r_get_distance_cnt-6 && r_enb12_work_en)
        r_enb2 <= 1'd1;
    else
        r_enb2 <= r_enb2;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_addrb2 <= 'd0;
    else if(r_enb2)
        r_addrb2 <= r_addrb2+1;
    else
        r_addrb2 <= 'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_check_read_clean <= 3'd0;
    else if(!ro_v_sync)
        r_check_read_clean <= 3'd0;
    else if(w_h_sync_valid_pos && !ri_remainder_signal)
        r_check_read_clean <= r_check_read_clean + 3'd2; //一次存入两行
    else if(w_r_ram_wr_pos)
        r_check_read_clean <= r_check_read_clean + 3'd3; //一次存入三行
    else if(w_r_enb1_pos || w_r_enb2_pos || w_ram_enb_pos)
        r_check_read_clean <= r_check_read_clean - 3'd1;
    else
        r_check_read_clean <= r_check_read_clean;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_rows_cnt <= 16'd0;
    else if(!ri_v_sync)
        r_rows_cnt <= 16'd0;
    else if(w_h_sync_valid_pos)
        r_rows_cnt <= r_rows_cnt + 16'd1;
    else
        r_rows_cnt <= r_rows_cnt;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_ram_addra <= 'd0;
    else if(w_ram_wr_en)
        r_ram_addra <= r_ram_addra + 1;
    else
        r_ram_addra <= 'd0;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_ram_addrb <= 'd0;
    else if(r_ram_enb)
        r_ram_addrb <= r_ram_addrb + 1;
    else
        r_ram_addrb <= 'd0;
end


always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_ram_enb_work_en <= 1'd0;
    else if(r_rows_cnt == P_MULTI_ROWS_NUM && r_output_rows_num == 2'd3 && r_actual_distan_cnt == 1)
        r_ram_enb_work_en <= ~r_ram_enb_work_en;
    else
        r_ram_enb_work_en <= r_ram_enb_work_en;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_ram_enb <= 1'd0;
    else if(r_output_pixel_cnt == P_ROW_WIDTH-1)
        r_ram_enb <= 1'd0;
    else if(r_rows_cnt == P_MULTI_ROWS_NUM && r_ram_enb_work_en && r_actual_distan_cnt == r_get_distance_cnt-6)
        r_ram_enb <= 1'd1;
    else
        r_ram_enb <= r_ram_enb;
end

initial_3rows_tdram #(
    .P_ROW_WIDTH  (P_ROW_WIDTH   ),
    .P_DATA_WIDTH (P_DATA_WIDTH  ),
    .P_ADDR_WIDTH (P_ADDR_WIDTH  )
)
initial_3rows_tdram_U1(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .addra1       (r_addra1      ),
    .wea1         (r_wea1        ),
    .dina1        (r_dina1       ),
    .addrb1       (r_addrb1      ),
    .doutb1       (w_doutb1      ),
    .enb1         (r_enb1        ),
    .addra2       (r_addra2      ),
    .wea2         (r_wea2        ),
    .dina2        (r_dina2       ),
    .addrb2       (r_addrb2      ),
    .doutb2       (w_doutb2      ),
    .enb2         (r_enb2        )
);


custom_xpm_tdram #(
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH*3),
    .P_WRITE_DATA_DEPTH_A (P_ROW_WIDTH ),
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH*3),
    .P_ADDR_WIDTH_A       (P_ADDR_WIDTH),
    .P_WRITE_DATA_WIDTH_B (P_DATA_WIDTH*3),
    .P_READ_DATA_WIDTH_B  (P_DATA_WIDTH*3),
    .P_ADDR_WIDTH_B       (P_ADDR_WIDTH),
    .P_CLOCKING_MODE      ( "common_clock" )
)custom_xpm_tdram_inst(
    .clka                 (i_clk),
    .rsta_n               (i_rst_n),
    .addra                (r_ram_addra),
    .wea                  (w_ram_wr_en),
    .dina                 ( w_ram_din),
    .clkb                 (i_clk),
    .rstb_n               (i_rst_n),
    .addrb                ( r_ram_addrb                ),
    .doutb                ( w_ram_doutb                ),
    .enb                  ( r_ram_enb                  )
);


endmodule
