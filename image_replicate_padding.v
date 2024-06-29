// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company: 
// // Engineer: Tinny_G
// // 
// // Create Date: 2024/05/29 17:24:13
// // Design Name: 
// // Module Name: image_replicate_padding
// // Project Name: 
// // Target Devices: 
// // Tool Versions: 
// // Description: 
// // 串行输入，边界填充
// // Dependencies: 
// // 
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// // 
// //////////////////////////////////////////////////////////////////////////////////


module image_replicate_padding
#(
    parameter                   P_DATA_WIDTH = 20    ,
    parameter                   P_PAD_CYCLES = 4     , //range {4,7,10,13}
    parameter                   P_IMG_WIDTH  = 256   ,
    parameter                   P_IMG_HEIGHT = 256   
)
(
    input                       i_clk       ,
    input                       i_rst_n     ,
    input                       i_v_sync    ,
    input                       i_h_sync    ,
    input   [P_DATA_WIDTH-1:0]  i_data      ,
    input                       i_left_en   ,
    input                       i_right_en  ,
    input                       i_top_en    ,
    input                       i_bottom_en ,
    output  [P_DATA_WIDTH-1:0]  o_data      ,
    output                      o_v_sync    ,
    output                      o_h_sync    
);

localparam                  P_IDLE          = 4'd0   ,
                            P_PADDING_LTR   = 4'd1   ,
                            P_PADDING_TR    = 4'd2   ,
                            P_PDDING_TBR    = 4'd3   ;
// localparam                  P_IDLE          = 4'b0001   ,
//                             P_PADDING_LTR   = 4'b0010   ,
//                             P_PADDING_TR    = 4'b0100   ,
//                             P_PDDING_TBR    = 4'b1000   ;
localparam                  P_FIFO_LATANCY          =  0 ;
localparam                  P_RAM_LATANCY           =  2 ;
localparam                  P_FIFO_RAM_MAX_LATANCY  =  P_RAM_LATANCY > P_FIFO_LATANCY? P_RAM_LATANCY : P_FIFO_LATANCY ;
localparam                  P_V_DELAY = (P_IMG_HEIGHT+2*P_PAD_CYCLES)*P_PAD_CYCLES*2+P_IMG_WIDTH*P_PAD_CYCLES*2;


//input registers
reg                         ri_v_sync           ;
reg                         ri_v_sync_1d        ;
reg                         ri_v_sync_2d        ;
reg                         ri_h_sync           ;
reg     [P_DATA_WIDTH-1:0]  ri_data             ;
reg     [P_DATA_WIDTH-1:0]  ri_data_1d          ;
reg                         ri_left_en          ;
reg                         ri_right_en         ;
reg                         ri_top_en           ;
reg                         ri_bottom_en        ;

//output registers
reg                         ro_v_sync           ;
reg                         ro_h_sync           ;
reg     [P_DATA_WIDTH-1:0]  ro_data             ;

//temp registers

reg     [3:0]               r_ct                ;
reg     [3:0]               r_nt                ;

reg     [11:0]              r_ram_addra         ;
reg                         r_ram_wea           ;
reg     [P_DATA_WIDTH-1:0]  r_ram_dina          ;
reg     [11:0]              r_ram_addrb         ;
wire    [P_DATA_WIDTH-1:0]  w_ram_doutb         ;
reg                         r_ram_enb           ;
reg                         r_ram_enb_1d        ;
reg                         r_ram_enb_2d        ;

reg                         r_fifo_wr_en        ;       
reg     [P_DATA_WIDTH-1:0]  r_fifo_din          ;       
reg                         r_fifo_rd_en        ;       
reg                         r_fifo_rd_en_1d     ; 
reg                         r_fifo_rd_en_2d     ; 
wire                        w_fifo_full         ;       
wire    [P_DATA_WIDTH-1:0]  w_fifo_dout         ;
wire                        w_fifo_empty        ;

reg     [15:0]              r_rows_cnt          ;
reg                         r_interval_cnt_en   ;
reg     [15:0]              r_get_interval_cnt  ;
reg     [15:0]              r_start_interval_cnt;
reg     [15:0]              r_ouput_pixel_cnt   ;
reg     [P_DATA_WIDTH-1:0]  r_get_row_head      ;
reg     [P_DATA_WIDTH-1:0]  r_get_row_tail      ;

reg                         r_h_sync_1d         ;
reg                         r_h_sync_2d         ;
wire                        w_h_valid_sync      ;
wire                        w_h_sync_pos        ;
wire                        w_h_sync_neg        ;
wire                        r_ready_output_en   ;
// reg     [P_DATA_WIDTH-1:0]  r_shfit_reg         [P_PAD_CYCLES-1:0];
reg     [15:0]              r_state_cnt         ; //when in non-idle state, the cnt will add 1,and when in idle state, the cnt will reset to 0
reg     [15:0]              r_v_head_cnt        ;
reg     [15:0]              r_v_tail_cnt        ;
//assign output
assign o_data      = ro_data      ;
assign o_v_sync    = ro_v_sync    ;
assign o_h_sync    = ro_h_sync    ;

assign w_h_valid_sync   = ri_h_sync && ri_v_sync;
assign w_h_sync_pos     = !r_h_sync_1d && w_h_valid_sync;
assign w_h_sync_neg     = r_h_sync_1d && !w_h_valid_sync;

assign r_ready_output_en = r_ouput_pixel_cnt>= P_FIFO_RAM_MAX_LATANCY ?1'd1:1'd0;

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        ri_v_sync    <= 1'b0    ;
        ri_h_sync    <= 1'b0    ;
        ri_data      <= 'd0     ;
        ri_left_en   <= 1'b0    ;
        ri_right_en  <= 1'b0    ;
        ri_top_en    <= 1'b0    ;
        ri_bottom_en <= 1'b0    ;
    end else begin
        ri_v_sync    <= i_v_sync   ;
        ri_h_sync    <= i_h_sync   ;
        ri_data      <= i_data     ;
        ri_left_en   <= i_left_en  ;
        ri_right_en  <= i_right_en ;
        ri_top_en    <= i_top_en   ;
        ri_bottom_en <= i_bottom_en;
        
    end
end
//delay data
always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        r_h_sync_1d     <= 1'b0  ;
        r_h_sync_2d     <= 1'b0  ;
        ri_data_1d      <= 'd0   ;
        ri_v_sync_1d    <= 1'b0  ;
        ri_v_sync_2d    <= 1'b0  ;
        r_fifo_rd_en_1d <= 1'b0  ;
        r_fifo_rd_en_2d <= 1'b0  ;
        r_ram_enb_1d    <= 1'b0  ;
        r_ram_enb_2d    <= 1'b0  ;
    end else begin
        r_h_sync_1d     <= w_h_valid_sync  ;
        r_h_sync_2d     <= r_h_sync_1d     ;
        ri_data_1d      <= ri_data         ;
        ri_v_sync_1d    <= ri_v_sync      ;
        ri_v_sync_2d    <=ri_v_sync_1d    ;
        r_fifo_rd_en_1d <= r_fifo_rd_en ;
        r_fifo_rd_en_2d <= r_fifo_rd_en_1d ;
        r_ram_enb_1d    <= r_ram_enb     ;
        r_ram_enb_2d    <= r_ram_enb_1d  ;
    end
end

//rows cnt ,when negedge is coming ,the cnt aadded 1
always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_rows_cnt <= 16'd0;
    else if(r_rows_cnt == P_IMG_HEIGHT+2*P_PAD_CYCLES)
        r_rows_cnt <= 16'd0;
    else if(r_ram_enb_1d && !r_ram_enb)
        r_rows_cnt <= r_rows_cnt + 16'd1;
    else if(r_fifo_rd_en_1d && !r_fifo_rd_en)
        r_rows_cnt <= r_rows_cnt + 16'd1;
    else
        r_rows_cnt <= r_rows_cnt;
end


always@(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_interval_cnt_en <= 1'b0;
    else if(!ro_v_sync)
        r_interval_cnt_en <= 1'b0;
    else if(w_h_sync_pos && r_get_interval_cnt != 0)
        r_interval_cnt_en <= 1'b1;
    else
        r_interval_cnt_en <= r_interval_cnt_en;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_get_interval_cnt <= 16'd0;
    else if(r_rows_cnt == P_IMG_HEIGHT+2*P_PAD_CYCLES)
        r_get_interval_cnt <= 16'd0;
    else if((w_h_sync_neg || r_get_interval_cnt) && !r_interval_cnt_en)
        r_get_interval_cnt <= r_get_interval_cnt + 16'd1;
    else
        r_get_interval_cnt <= r_get_interval_cnt;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_start_interval_cnt <= 16'd0;
    else if(r_start_interval_cnt == r_get_interval_cnt && r_interval_cnt_en)
        r_start_interval_cnt <= 16'd0;
    else if((r_ram_enb_1d && !r_ram_enb)||r_start_interval_cnt)
        r_start_interval_cnt <= r_start_interval_cnt + 16'd1;
    else if((r_fifo_rd_en_1d && !r_fifo_rd_en)||r_start_interval_cnt)
        r_start_interval_cnt <= r_start_interval_cnt + 16'd1;
    else
        r_start_interval_cnt <= 16'd0;
end

// FSM
always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_ct <= P_IDLE;
    else
        r_ct <= r_nt;
end

always @(*) begin
    case (r_ct)
            P_IDLE:begin
                if(w_h_sync_pos && ri_left_en &&ri_top_en)
                    r_nt = P_PADDING_LTR;
                else if(w_h_sync_pos && ri_left_en && !ri_top_en && !ri_bottom_en)
                    r_nt = P_PADDING_TR;
                else if(w_h_sync_pos && ri_left_en && ri_bottom_en)
                    r_nt = P_PDDING_TBR;
                else
                    r_nt = P_IDLE;
            end
            P_PADDING_LTR:begin
                if(w_h_sync_neg)
                    r_nt = P_IDLE;
                else
                    r_nt = P_PADDING_LTR;
            end
            P_PADDING_TR:begin
                if(w_h_sync_neg)
                    r_nt = P_IDLE;
                else
                    r_nt = P_PADDING_TR;
            end
            P_PDDING_TBR:begin
                if(w_h_sync_neg)
                    r_nt = P_IDLE;
                else
                    r_nt = P_PDDING_TBR;
            end
        default : r_nt = P_IDLE;
    endcase
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_ram_addra <= 12'd0;
    else if(r_ram_wea)
        r_ram_addra <= r_ram_addra + 12'd1;
    else
        r_ram_addra <= 12'd0;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_ram_wea <= 1'd0;
    else if(r_ct == P_PADDING_LTR || r_ct == P_PDDING_TBR)
        r_ram_wea <= 1'd1;
    else
        r_ram_wea <= 1'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_ram_dina <=  'd0;
    else if(r_h_sync_1d)
        r_ram_dina <= ri_data_1d;
    else
        r_ram_dina <=  'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_ram_addrb <=  12'd0;
    else if(r_ram_enb)
        r_ram_addrb <= r_ram_addrb + 1;
    else
        r_ram_addrb <=  'd0;
end

always@(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_ram_enb <= 1'd0;
    else if(r_state_cnt == P_IMG_WIDTH+P_PAD_CYCLES-P_RAM_LATANCY)
        r_ram_enb <= 1'd0;
    else if(r_rows_cnt <= P_PAD_CYCLES-1 && r_state_cnt == P_PAD_CYCLES-P_RAM_LATANCY )
        r_ram_enb <= 1'd1;
    else if(r_rows_cnt > P_IMG_HEIGHT+P_PAD_CYCLES-1  && r_rows_cnt <= P_IMG_HEIGHT+P_PAD_CYCLES*2 && r_state_cnt == P_PAD_CYCLES-P_RAM_LATANCY )
        r_ram_enb <= 1'd1;
    else
        r_ram_enb <= r_ram_enb;
end

//operate fifo
always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_fifo_wr_en <= 1'd0;
    else if(w_h_valid_sync && !w_fifo_full)
        r_fifo_wr_en <= 1'd1;
    else
        r_fifo_wr_en <= 1'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_fifo_din <=  'd0;
    else if(w_h_valid_sync && !w_fifo_full)
        r_fifo_din <= ri_data;
    else
        r_fifo_din <=  'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_ouput_pixel_cnt <=  16'd0;
    else if(r_ouput_pixel_cnt == P_IMG_WIDTH + P_FIFO_RAM_MAX_LATANCY)
        r_ouput_pixel_cnt <=  16'd0;
    else if(r_ram_enb || r_ouput_pixel_cnt)
        r_ouput_pixel_cnt <= r_ouput_pixel_cnt + 1;
    else if(r_fifo_rd_en || r_ouput_pixel_cnt)
        r_ouput_pixel_cnt <= r_ouput_pixel_cnt + 1;
    else
        r_ouput_pixel_cnt <=  16'd0;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_get_row_head <=  'd0;
    else if(!ro_v_sync)
        r_get_row_head <=  'd0;
    else if(w_h_sync_pos && ri_left_en &&ri_top_en) //ct == P_PADDING_LTR
        r_get_row_head <=  ri_data;
    else if(r_fifo_rd_en && r_ouput_pixel_cnt == P_FIFO_LATANCY) //ct == P_PADDING_LR
        r_get_row_head <=  w_fifo_dout;
    else if(r_ram_enb && r_ouput_pixel_cnt == P_RAM_LATANCY && r_rows_cnt >= P_IMG_HEIGHT+P_PAD_CYCLES-1) //ct == P_PDDING_TBR
        r_get_row_head <=  w_ram_doutb;
    else
        r_get_row_head <=  r_get_row_head;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_get_row_tail <=  'd0;
    else if(!ro_v_sync)
        r_get_row_tail <=  'd0;
    else if(ri_right_en &&ri_top_en)
        r_get_row_tail <=  ri_data;
    else if(r_fifo_rd_en_2d && r_ouput_pixel_cnt == P_IMG_HEIGHT+P_FIFO_LATANCY-1)
        r_get_row_tail <=  w_fifo_dout;
    else if (r_ram_enb_2d && r_ouput_pixel_cnt == P_IMG_HEIGHT+P_RAM_LATANCY-1 && r_rows_cnt >= P_IMG_HEIGHT+P_PAD_CYCLES-1)
        r_get_row_tail <=  w_ram_doutb;
    else
        r_get_row_tail <=  r_get_row_tail;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_fifo_rd_en <= 1'd0;
    else if(r_state_cnt == P_IMG_WIDTH+P_PAD_CYCLES-P_FIFO_LATANCY)
        r_fifo_rd_en <= 1'd0;
    else if(r_rows_cnt > P_PAD_CYCLES-1 && r_rows_cnt <= P_IMG_HEIGHT+P_PAD_CYCLES-1 && r_state_cnt == P_PAD_CYCLES-P_FIFO_LATANCY && !w_fifo_empty)
        r_fifo_rd_en <= 1'd1;
    else
        r_fifo_rd_en <= r_fifo_rd_en;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_state_cnt <= 16'd0;
    else if(r_state_cnt ==  P_IMG_WIDTH+P_PAD_CYCLES*2)
        r_state_cnt <= 16'd0;
    else if((w_h_sync_pos && ri_left_en &&ri_top_en)||r_state_cnt)
        r_state_cnt <= r_state_cnt + 1;
    else if((r_get_interval_cnt == r_start_interval_cnt && r_interval_cnt_en)||r_state_cnt)
        r_state_cnt <= r_state_cnt + 1;
    else
        r_state_cnt <= 16'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        ro_data <=  'd0;
    else if(r_state_cnt >= 1 && r_state_cnt<=P_PAD_CYCLES) //the reg of "r_get_row_head",is usefull when posdege is pasted
        ro_data <= r_get_row_head;
    else if(!r_fifo_rd_en && r_state_cnt> P_PAD_CYCLES && r_state_cnt<= P_PAD_CYCLES+P_IMG_WIDTH)
        ro_data <= w_ram_doutb;
    else if(r_fifo_rd_en && r_state_cnt> P_PAD_CYCLES && r_state_cnt<= P_PAD_CYCLES+P_IMG_WIDTH)
        ro_data <= w_fifo_dout;
    else if(r_state_cnt > P_IMG_WIDTH + P_PAD_CYCLES && r_state_cnt<= P_IMG_WIDTH + P_PAD_CYCLES*2)
        ro_data <= r_get_row_tail;
    else
        ro_data <=  'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        ro_h_sync <=  'd0;
    else if(r_state_cnt>= 1 && r_state_cnt<= P_IMG_WIDTH+2*P_PAD_CYCLES)
        ro_h_sync <= 1'd1;
    else
        ro_h_sync <= 1'd0;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_v_head_cnt <= 16'd0;
    else if(r_v_head_cnt == P_V_DELAY)
        r_v_head_cnt <= 16'd0;
    else if((!ri_v_sync_1d && ri_v_sync)||r_v_head_cnt)
        r_v_head_cnt <= r_v_head_cnt + 1;
    else
        r_v_head_cnt <= 16'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        r_v_tail_cnt <= 16'd0;
    else if(r_v_tail_cnt == P_V_DELAY)
        r_v_tail_cnt <= 16'd0;
    else if((ri_v_sync_1d && !ri_v_sync)||r_v_tail_cnt)
        r_v_tail_cnt <= r_v_tail_cnt + 1;
    else
        r_v_tail_cnt <= 16'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        ro_v_sync <=  'd0;
    else if(r_v_head_cnt == P_V_DELAY)
        ro_v_sync <= 1'd1;
    else if(r_v_tail_cnt == P_V_DELAY)
        ro_v_sync <= 1'd0;
    else
        ro_v_sync <= ro_v_sync;
end


//tdram is used to save padding data
custom_xpm_tdram #( 
    .P_WRITE_DATA_WIDTH_A (P_DATA_WIDTH ),
    .P_WRITE_DATA_DEPTH_A (512          ),
    .P_READ_DATA_WIDTH_A  (P_DATA_WIDTH ),
    .P_ADDR_WIDTH_A       (12           ),
    .P_WRITE_DATA_WIDTH_B (P_DATA_WIDTH ),
    .P_READ_DATA_WIDTH_B  (P_DATA_WIDTH ),
    .P_ADDR_WIDTH_B       (12           ),
    .P_CLOCKING_MODE      ("common_clock")
)custom_xpm_tdram_inst(
    .clka                 ( i_clk        ),
    .rsta_n               ( i_rst_n      ),
    .addra                (r_ram_addra   ),
    .wea                  (r_ram_wea     ),
    .dina                 (r_ram_dina    ),
    .clkb                 (i_clk         ),
    .rstb_n               (i_rst_n       ),
    .addrb                (r_ram_addrb   ),
    .doutb                (w_ram_doutb   ),
    .enb                  (r_ram_enb     )
);



//async fifo is used to storage the input data
custom_xpm_fifo_async #(
    .P_ASYNC_FIFO_WRITE_WIDTH ( P_DATA_WIDTH ),
    .P_ASYNC_FIFO_WRITE_DEPTH ( 2048         ),
    .P_ASYNC_FIFO_READ_WIDTH  ( P_DATA_WIDTH ),
    .P_FIFO_READ_LATENCY      (1             ),
    .P_READ_MODE              ("std"         )
)custom_xpm_fifo_async_U0(
    .rst_n                    (i_rst_n      ),
    .wr_clk                   (i_clk        ),
    .full                     (w_fifo_full  ),
    .wr_en                    (r_fifo_wr_en ),
    .din                      (r_fifo_din   ),
    .wr_rst_busy              (),
    .rd_clk                   (i_clk        ),
    .rd_en                    (r_fifo_rd_en ),
    .dout                     (w_fifo_dout  ),
    .empty                    (w_fifo_empty ),
    .rd_rst_busy              ()
);

endmodule
