`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/11 20:24:58
// Design Name: 
// Module Name: image_symmetric_padding
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// this module is used to add symmetric padding to the input image
// Dependencies: 
// 图像镜像拓展模块，将一次输入的【多行】图像拓展，注意输入的行数一定要大于拓展的行数！！！
// 输出图像的行数为输入图像的行数+2,输出的行的宽度是P_DATA_WIDTH*(P_EXPEND_NUM*2 + P_IMAGE_WIDTH )
// 注意最后补的那一行，里面的余数没改，按理说最优的情况应该修改的
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module image_symmetric_padding
#(
    parameter       P_INPUT_ROWS_NUM = 5    ,  // input image's rows number,defalut is 5
    parameter       P_IMAGE_WIDTH    = 256  ,  // input image's cols number,defalut is 5
    parameter       P_IMAGE_HEIGHT   = 256  ,  // input image's rows number,defalut is 5
    parameter       P_DATA_WIDTH     = 8    ,  // width of each row's data,default is 8-bit
    parameter       P_ADDR_WIDTH     = 11   ,  // width of the address bus,default is 12
    parameter       P_EXPEND_NUM     = 1        // specify the numbers of the padding cicrcles (default is 1) which package the input image data
)
(
    input           i_clk                   ,
    input           i_rst_n                 ,
    input           i_h_async               ,
    input           i_v_async               ,
    input   [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] i_raws_data,
    input           i_remainder_signal      ,
    input           i_left_en               ,
    input           i_right_en              ,
    input           i_top_en                ,
    input           i_bottom_en             ,

    output          o_v_sync                ,
    output          o_h_sync                ,
    output  [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] o_pads_data,
    output          o_padding_remain_sign       
);

localparam          P_MAX_INPUT_BITS        = P_INPUT_ROWS_NUM*P_DATA_WIDTH     ;
localparam          P_ROW_PIXEL_CNT_MAX     = P_IMAGE_WIDTH+2*P_EXPEND_NUM      ;
localparam          P_PAD_ROW_WIDTH         = P_IMAGE_WIDTH+2*P_EXPEND_NUM      ;
localparam          P_REMAINDER_NUM         = P_IMAGE_HEIGHT%P_INPUT_ROWS_NUM   ;
localparam          P_RRMAINDER_EXPAND      = P_REMAINDER_NUM + 2*P_EXPEND_NUM  ;
localparam          P_DIFF_EXPAND           = P_RRMAINDER_EXPAND - P_INPUT_ROWS_NUM ? P_RRMAINDER_EXPAND - P_INPUT_ROWS_NUM : 0;
localparam          P_EXPAND_REMAINDER_FLAG = ((P_REMAINDER_NUM==0)||(P_RRMAINDER_EXPAND - P_INPUT_ROWS_NUM > 0)) ?1'b1:1'b0;//if need to expand a new raw, then set this flag to 1
localparam          P_CAL_WIDTH             = (P_INPUT_ROWS_NUM - P_RRMAINDER_EXPAND+1)*P_DATA_WIDTH;

localparam          P_IDLE                  = 4'b0000,
                    P_LEFT_TOP_RIGHT        = 4'b0001,
                    P_LEFT_RIGHT            = 4'b0010,
                    P_LEFT_BOTTOM_RIGHT     = 4'b0100,
                    P_NEW_RAW               = 4'b1000;

//input registers
reg                             ri_h_async              ;
reg                             ri_v_async              ;
reg     [P_MAX_INPUT_BITS-1:0]  ri_raws_data            ;
reg                             ri_remainder_signal     ;
reg                             ri_left_en              ;
reg                             ri_right_en             ;    
reg                             ri_top_en               ;
reg                             ri_top_en_1d            ;
reg                             ri_bottom_en            ;
reg                             ri_bottom_en_1d         ;
//output registers
reg                             ro_v_sync               ;
reg                             ro_h_sync               ;
reg     [P_MAX_INPUT_BITS-1:0]  ro_pads_data            ;
reg                             ro_padding_remain_sign;
//temp  registers
reg                             ri_v_async_1d           ;
reg                             ri_v_async_2d           ;
reg     [P_MAX_INPUT_BITS-1:0]  ri_raws_data_1d         ;
reg     [P_MAX_INPUT_BITS-1:0]  ri_raws_data_2d         ;
reg                             r_H_valid_async_1d      ;
reg     [3:0]                   ct                      ;
reg     [3:0]                   nt                      ;
reg     [15:0]                  r_row_pixel_cnt         ;
reg                             r_cnt_work_en           ;
reg     [1:0]                   r_interval_cnt          ;
reg     [15:0]                  r_regard_intervals      ;
reg     [15:0]                  r_start_product_intervals;

wire                            w_H_async_posedge       ;
wire                            w_H_valid_async         ;
wire                            w_H_async_negedge       ;




assign w_H_valid_async      = ri_h_async && ri_v_async;
assign w_H_async_posedge    = (w_H_valid_async && !r_H_valid_async_1d);
assign w_H_async_negedge    = (!w_H_valid_async &&  r_H_valid_async_1d);
assign o_v_sync             = ro_v_sync     ;
assign o_h_sync             = ro_h_sync     ;
assign o_pads_data          = ro_pads_data  ;
assign o_padding_remain_sign= ro_padding_remain_sign;

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_h_async   <= 1'b0;
        ri_v_async   <= 1'b0;
        ri_raws_data <= 'd0;
        ri_remainder_signal <= 1'b0;
        ri_left_en  <= 1'b0;
        ri_right_en <= 1'b0;
        ri_top_en   <= 1'b0;
        ri_top_en_1d <= 1'b0;
        ri_bottom_en <= 1'b0;
        ri_bottom_en_1d <= 1'b0;
        r_H_valid_async_1d <= 1'b0;
        ri_raws_data_1d <= 'd0;
        ri_raws_data_2d <= 'd0;
    end else begin
        ri_h_async <= i_h_async;
        ri_v_async <= i_v_async;
        ri_raws_data <= i_raws_data;
        ri_remainder_signal <= i_remainder_signal;
        ri_left_en <= i_left_en;
        ri_right_en <= i_right_en;
        ri_top_en <= i_top_en;
        ri_top_en_1d <= ri_top_en;
        ri_bottom_en <= i_bottom_en;
        ri_bottom_en_1d <= ri_bottom_en;
        r_H_valid_async_1d<=w_H_valid_async;
        ri_raws_data_1d <= ri_raws_data;
        ri_raws_data_2d <= ri_raws_data_1d;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_row_pixel_cnt <= 16'd0;
    else if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX+1)
        r_row_pixel_cnt <= 16'd0;
    else if(w_H_async_posedge || r_row_pixel_cnt)
        r_row_pixel_cnt <= r_row_pixel_cnt + 16'd1;
    else
        r_row_pixel_cnt <= 16'd0;
end

always @(posedge i_clk,negedge i_rst_n) begin
    if(!i_rst_n)
        r_cnt_work_en <= 1'b0;
    else if(!ri_v_async)
        r_cnt_work_en <= 1'b0;
    else if(r_interval_cnt == 2'd3)
        r_cnt_work_en <= 1'b1;
    else
        r_cnt_work_en <= r_cnt_work_en;
end

always @(posedge i_clk,negedge i_rst_n) begin
    if(!i_rst_n)
        r_interval_cnt <= 2'd0;
    else if(r_interval_cnt == 2'd3 && ri_v_async)
        r_interval_cnt <= 2'd0;
    else if((w_H_async_posedge || w_H_async_negedge)&&!r_cnt_work_en)
        r_interval_cnt <= r_interval_cnt + 2'd1;
    else
        r_interval_cnt <= r_interval_cnt;
end
always @(posedge i_clk,negedge i_rst_n) begin
    if(!i_rst_n)
        r_regard_intervals <= 16'd0;
    else if(!ro_v_sync)
        r_regard_intervals <= 16'd0;
    else if(r_interval_cnt >= 2'd2 && r_interval_cnt < 2'd3)
        r_regard_intervals <= r_regard_intervals + 16'd1;
    else
        r_regard_intervals <= r_regard_intervals;
end
always @(posedge i_clk,negedge i_rst_n) begin
    if(!i_rst_n)
        r_start_product_intervals <= 16'd0;
    else if(r_start_product_intervals == r_regard_intervals && r_start_product_intervals!=16'd0)
        r_start_product_intervals <= 16'd0;
    else if(P_REMAINDER_NUM == 0 && ri_bottom_en_1d && !ri_bottom_en)
        r_start_product_intervals <= r_start_product_intervals + 16'd1;
    else
        r_start_product_intervals <= r_start_product_intervals;
end

//state Machine
always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        ct <= P_IDLE;
    else
        ct <= nt;
end

always @(*) begin
    case (ct)
        P_IDLE: begin
            if(ri_left_en && ri_top_en && w_H_async_posedge)
                nt = P_LEFT_TOP_RIGHT;
            else if(ri_left_en && !ri_top_en && !ri_bottom_en && w_H_async_posedge)
                nt = P_LEFT_RIGHT;
            else if(ri_left_en && ri_bottom_en && w_H_async_posedge)
                nt = P_LEFT_BOTTOM_RIGHT;
            else if( P_EXPAND_REMAINDER_FLAG && r_start_product_intervals == r_regard_intervals &&r_start_product_intervals!=16'd0)
                nt = P_NEW_RAW;
            else
                nt = P_IDLE;
        end
        P_LEFT_TOP_RIGHT: begin
            if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX+1)
                nt = P_IDLE;
            else
                nt = P_LEFT_TOP_RIGHT;
        end
        P_LEFT_RIGHT: begin
            if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX+1)
                nt = P_IDLE;
            else
                nt = P_LEFT_RIGHT;
        end
        P_LEFT_BOTTOM_RIGHT: begin
            if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX+1)
                nt = P_IDLE;
            else
                nt = P_LEFT_BOTTOM_RIGHT;
        end
        P_NEW_RAW:begin
            if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX+1)
                nt = P_IDLE;
            else
                nt = P_NEW_RAW;
        end
        default nt = P_IDLE  ;
    endcase 
end


generate
    case (P_EXPEND_NUM)
            3:  begin:generate_3_padding  //it's need to actually save 3 rows instead of outputing 2 raws when the third comming
            
            end
        default : begin:generate_1_padding
            reg   [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] r_saved_right_data;
            reg   [P_INPUT_ROWS_NUM*P_DATA_WIDTH-1:0] r_saved_left_data ;
            reg                             r_wea1      ;
            reg   [P_ADDR_WIDTH-1:0]        r_addra1    ;
            reg   [P_DATA_WIDTH-1:0]        r_dina1     ;
            wire                            w_enb1      ;
            reg   [P_ADDR_WIDTH-1:0]        r_addrb1    ;
            wire  [P_DATA_WIDTH-1:0]        w_doutb1    ;
            initial_1row_tdram #(
                .P_ROW_WIDTH  (P_PAD_ROW_WIDTH),
                .P_DATA_WIDTH (P_DATA_WIDTH  ),
                .P_ADDR_WIDTH (P_ADDR_WIDTH  )
            )initial_1row_tdram_U0(
                .i_clk        ( i_clk        ),
                .i_rst_n      ( i_rst_n      ),
                .addra1       ( r_addra1     ),
                .wea1         ( r_wea1       ),
                .dina1        ( r_dina1      ),
                .addrb1       ( r_addrb1     ),
                .doutb1       ( w_doutb1     ),
                .enb1         ( w_enb1       )
            );

            assign w_enb1 = (i_h_async ||  r_H_valid_async_1d )&&!ri_top_en && !ri_top_en_1d;

            always @(posedge i_clk,negedge i_rst_n) begin
                if(!i_rst_n) begin
                    ri_v_async_1d <= 1'b0;
                    ri_v_async_2d <= 1'b0;
                    
                end else begin
                    ri_v_async_1d <= ri_v_async;
                    ri_v_async_2d <= ri_v_async_1d;
                end
            end

            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)
                    r_saved_left_data  <= 'd0;
                else if(!ro_v_sync)
                    r_saved_left_data  <= 'd0;
                else if(P_EXPAND_REMAINDER_FLAG && ct == P_LEFT_BOTTOM_RIGHT)
                    r_saved_left_data  <= ri_raws_data_1d;
                else
                    r_saved_left_data  <= r_saved_left_data ;
            end

            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)
                    r_saved_right_data <= 'd0;
                else if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX+1)
                    r_saved_right_data <= 'd0;
                else if(w_H_valid_async && ri_right_en)
                    r_saved_right_data <= ri_raws_data;
                else
                    r_saved_right_data <= r_saved_right_data;
            end

            always @(posedge i_clk,negedge i_rst_n) begin
                if(!i_rst_n)
                    r_addra1 <= 'd0;
                else if(r_wea1)
                    r_addra1 <= r_addra1 + 1;
                else
                    r_addra1 <= 'd0;
            end

            always @(posedge i_clk,negedge i_rst_n) begin
                if(!i_rst_n)
                    r_addrb1 <= 'd0;
                else if(w_enb1)
                    r_addrb1 <= r_addrb1 + 1;
                else
                    r_addrb1 <= 'd0;
            end
            // 第三段输出
            always @(posedge i_clk,negedge i_rst_n) begin
                if(!i_rst_n) begin
                    r_wea1 <= 1'b0;
                    ro_padding_remain_sign <= 1'b0;
                    ro_pads_data <= 'd0;
                    ro_h_sync <= 1'b0;
                    r_dina1 <= 'd0;
                end
                else begin
                    case (ct)
                            P_IDLE :begin
                                r_wea1 <= 1'b0;
                                ro_padding_remain_sign <= 1'b0;
                                ro_pads_data <= 'd0;
                                ro_h_sync <= 1'b0;
                                r_dina1 <= 'd0;
                            end
                            P_LEFT_TOP_RIGHT:begin  //sysmbolic padding
                                ro_padding_remain_sign <= 1'b0;
                                if(r_row_pixel_cnt == 16'd1 ) begin
                                    r_wea1 <= 1'b1;
                                    ro_h_sync <= 1'd1;
                                    ro_pads_data <= {ri_raws_data_1d[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_DATA_WIDTH],
                                                    ri_raws_data_1d[P_MAX_INPUT_BITS-1:P_DATA_WIDTH]};
                                    r_dina1 <= ri_raws_data_1d[P_DATA_WIDTH-1:0];
                                end else if(r_row_pixel_cnt > 16'd1 && r_row_pixel_cnt < P_ROW_PIXEL_CNT_MAX) begin
                                    r_wea1 <= 1'b1;
                                    ro_h_sync <= 1'd1;
                                    ro_pads_data <= {ri_raws_data_2d[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_DATA_WIDTH],
                                                ri_raws_data_2d[P_MAX_INPUT_BITS-1:P_DATA_WIDTH]};
                                    r_dina1 <= ri_raws_data_2d[P_DATA_WIDTH-1:0];
                                end else if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX) begin
                                    r_wea1 <= 1'b1;
                                    ro_h_sync <= 1'd1;
                                    ro_pads_data <= {r_saved_right_data[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_DATA_WIDTH],
                                                    r_saved_right_data[P_MAX_INPUT_BITS-1:P_DATA_WIDTH]};
                                    r_dina1 <= r_saved_right_data[P_DATA_WIDTH-1:0];
                                end else begin
                                    r_wea1 <= 1'b0;
                                    ro_h_sync <= 1'd0;
                                    ro_pads_data <= 'd0;
                                    r_dina1 <= 'd0;
                                end
                            end
                            P_LEFT_RIGHT:begin
                                ro_padding_remain_sign <= 1'b0;
                                if(r_row_pixel_cnt == 16'd1 ) begin
                                    ro_h_sync <= 1'd1;
                                    r_wea1 <= 1'b1;
                                    ro_pads_data <= {w_doutb1,ri_raws_data_1d[P_MAX_INPUT_BITS-1:P_DATA_WIDTH]};
                                    r_dina1 <= ri_raws_data_1d[P_DATA_WIDTH-1:0];
                                end else if(r_row_pixel_cnt > 16'd1&& r_row_pixel_cnt < P_ROW_PIXEL_CNT_MAX) begin
                                    ro_h_sync <= 1'd1;
                                    r_wea1 <= 1'b1;
                                    ro_pads_data <= {w_doutb1,
                                        ri_raws_data_2d[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_DATA_WIDTH],
                                        ri_raws_data_2d[P_MAX_INPUT_BITS-1:P_DATA_WIDTH]};
                                    r_dina1 <= ri_raws_data_2d[P_DATA_WIDTH-1:0];
                                end else if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX) begin
                                    ro_h_sync <= 1'd1;
                                    r_wea1 <= 1'b1;
                                    ro_pads_data <= {w_doutb1,r_saved_right_data[P_MAX_INPUT_BITS-1:P_DATA_WIDTH]};
                                    r_dina1 <= r_saved_right_data[P_DATA_WIDTH-1:0];
                                end else begin
                                    ro_h_sync <= 1'd0;
                                    r_wea1 <= 1'b0;
                                    ro_pads_data <= 'd0;
                                    r_dina1 <= 'd0;
                                end
                            end
                            P_LEFT_BOTTOM_RIGHT:begin
                                case (P_EXPAND_REMAINDER_FLAG)
                                        1:begin
                                            ro_padding_remain_sign <= 1'b0;
                                            if(r_row_pixel_cnt == 16'd1 ) begin
                                                ro_h_sync <= 1'd1;
                                                r_wea1 <= 1'b1;
                                                ro_pads_data <= {w_doutb1,ri_raws_data_1d[P_MAX_INPUT_BITS-1:P_DATA_WIDTH]};
                                                r_dina1 <= ri_raws_data_1d[P_DATA_WIDTH-1:0];
                                            end else if(r_row_pixel_cnt > 16'd1&& r_row_pixel_cnt < P_ROW_PIXEL_CNT_MAX) begin
                                                ro_h_sync <= 1'd1;
                                                r_wea1 <= 1'b1;
                                                ro_pads_data <= {w_doutb1,
                                                    ri_raws_data_2d[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_DATA_WIDTH],
                                                    ri_raws_data_2d[P_MAX_INPUT_BITS-1:P_DATA_WIDTH]};
                                                r_dina1 <= ri_raws_data_2d[P_DATA_WIDTH-1:0];
                                            end else if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX) begin
                                                ro_h_sync <= 1'd1;
                                                r_wea1 <= 1'b1;
                                                ro_pads_data <= {w_doutb1,r_saved_right_data[P_MAX_INPUT_BITS-1:P_DATA_WIDTH]};
                                                r_dina1 <= r_saved_right_data[P_DATA_WIDTH-1:0];
                                            end else begin
                                                ro_h_sync <= 1'd0;
                                                r_wea1 <= 1'b0;
                                                ro_pads_data <= 'd0;
                                                r_dina1 <= 'd0;
                                            end
                                        end
                                    default : begin
                                        r_wea1  <= 1'b0;
                                        r_dina1 <= 'd0;
                                        ro_padding_remain_sign <= P_INPUT_ROWS_NUM > P_RRMAINDER_EXPAND ? 1'b1:1'b0;
                                        if(r_row_pixel_cnt == 16'd1) begin
                                            ro_pads_data <= {w_doutb1,
                                            ri_raws_data_1d[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_DATA_WIDTH],
                                            ri_raws_data_1d[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_CAL_WIDTH]};
                                            ro_h_sync <= 1'd1;
                                        end else if(r_row_pixel_cnt > 16'd1 && r_row_pixel_cnt < P_ROW_PIXEL_CNT_MAX) begin
                                            ro_h_sync <= 1'd1;
                                            ro_pads_data <= {w_doutb1,
                                                ri_raws_data_2d[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_DATA_WIDTH],
                                                ri_raws_data_2d[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_CAL_WIDTH]};
                                        end else if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX) begin
                                            ro_h_sync <= 1'd1;
                                            ro_pads_data <= {w_doutb1,r_saved_right_data[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_DATA_WIDTH],
                                                            r_saved_right_data[P_MAX_INPUT_BITS-1:P_MAX_INPUT_BITS-P_CAL_WIDTH]};
                                        end else begin
                                            ro_h_sync <= 1'd0;
                                            ro_pads_data <= 'd0;
                                        end
                                    end
                                endcase
                            end
                            P_NEW_RAW:begin
                                ro_padding_remain_sign <= 1'b1;
                                r_wea1 <= 1'b0;
                                r_dina1 <= 'd0;
                                if(r_row_pixel_cnt == 16'd1) begin
                                    ro_pads_data <= {w_doutb1,P_DIFF_EXPAND[(P_INPUT_ROWS_NUM - 1)*P_DATA_WIDTH-1:0]};
                                    ro_h_sync <= 1'd1;
                                end else if(r_row_pixel_cnt > 16'd1 && r_row_pixel_cnt < P_ROW_PIXEL_CNT_MAX) begin
                                    ro_h_sync <= 1'd1;
                                    ro_pads_data <= {w_doutb1,P_DIFF_EXPAND[(P_INPUT_ROWS_NUM - 1)*P_DATA_WIDTH-1:0]};
                                end else if(r_row_pixel_cnt == P_ROW_PIXEL_CNT_MAX) begin
                                    ro_h_sync <= 1'd1;
                                    ro_pads_data <= {w_doutb1,P_DIFF_EXPAND[(P_INPUT_ROWS_NUM - 1)*P_DATA_WIDTH-1:0]};
                                end else begin
                                    ro_h_sync <= 1'd0;
                                    ro_padding_remain_sign <= 1'b1;
                                    ro_pads_data <= 'd0;
                                end
                            end
                        default :  begin
                            r_wea1 <= 1'b0;
                            ro_padding_remain_sign <= 1'b0;
                            ro_pads_data <= 'd0;
                            ro_h_sync <= 1'b0;
                            r_dina1 <= 'd0;
                        end
                    endcase
                end
            end
            
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    ro_v_sync <= 1'b0;
                end else begin
                    ro_v_sync <= ri_v_async_2d;
                end
            end
        end
    endcase
endgenerate
endmodule
