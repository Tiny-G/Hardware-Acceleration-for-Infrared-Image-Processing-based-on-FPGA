`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: TinnyG
// 
// Create Date: 2024/05/09 15:51:35
// Design Name: 
// Module Name: serial_frame2parallel_row
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 串行帧转并行行,输出的行数可以调，输出3行，那个一个周期就输出3*8位
// P_ROW_WIDTH :输入图片数据的宽度
// P_COL_HEIGHT:输入图片数据的高度
// P_DATA_WIDTH:输入的通道宽度,默认8bit
// P_WAIT_ROW_NUM:同时输出的行数,
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module serial_frame2parallel_row
#(
    parameter                                       P_ROW_WIDTH     = 256   ,
    parameter                                       P_COL_HEIGHT    = 256   ,
    parameter                                       P_DATA_WIDTH    = 8     ,   
    parameter                                       P_WAIT_ROW_NUM  = 3     ,    //range{3,5}
    parameter                                       P_ADDR_WIDTH    = 11   
)
(
    input                                           i_clk           ,
    input                                           i_rst_n         ,
    input   [P_DATA_WIDTH-1:0]                      i_serial_frame  ,
    input                                           i_h_aync        ,
    input                                           i_v_aync        ,

    output                                          o_h_aync        ,
    output                                          o_source_h_aync ,
    output                                          o_v_aync        ,  
    output  [P_DATA_WIDTH*P_WAIT_ROW_NUM-1:0]       o_parallel_row  ,   //output data consists of {first row, second row, third row}
    output                                          o_remainder_signal 

);

localparam  [P_DATA_WIDTH-1:0]  P_REMAINDER_ROWS = P_COL_HEIGHT%P_WAIT_ROW_NUM;

//input signal
reg         [P_DATA_WIDTH-1:0]   ri_serial_frame    ;
reg         [P_DATA_WIDTH-1:0]   r_serial_frame_1d  ;
reg         [P_DATA_WIDTH-1:0]   r_serial_frame_2d  ;
reg         [P_DATA_WIDTH-1:0]   r_serial_frame_3d  ;
reg                              ri_h_aync          ;
reg                              ri_v_aync          ;

//output signal
reg                              ro_h_aync          ;
reg                              ro_source_h_aync   ;
reg                              ro_v_aync          ;
reg[P_DATA_WIDTH*P_WAIT_ROW_NUM-1:0] ro_parallel_row;
reg                              ro_remainder_signal;

//temp signal
reg                              r_h_aync_1d        ;
reg                              r_h_aync_2d        ;
wire                             w_valid_async      ;
wire                             w_valid_async_neg  ;
wire                             w_valid_async_pos  ;
wire                             w_v_async_neg      ;
reg                              r_valid_async_1d   ;
reg                              r_v_async_1d       ;
reg     [15:0]                   r_input_row_cnt    ;
reg                              r_last_row_flag    ;


assign  o_parallel_row          = ro_parallel_row     ;
assign  o_remainder_signal      = ro_remainder_signal ;
assign  o_h_aync                = ro_h_aync           ;
assign  o_source_h_aync         = ro_source_h_aync    ;
assign  o_v_aync                = ro_v_aync           ;
assign  w_valid_async           = ri_h_aync && ri_v_aync    ;
assign  w_valid_async_pos       = w_valid_async && !r_valid_async_1d;
assign  w_valid_async_neg       = !w_valid_async && r_valid_async_1d;
assign  w_v_async_neg           = !ri_v_aync && r_v_async_1d;

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_serial_frame <= 'd0 ;
        r_serial_frame_1d <='d0;
        r_serial_frame_2d <='d0;
        r_serial_frame_3d <='d0;
        ri_h_aync       <= 1'd0;
        r_h_aync_1d     <= 1'd0;
        r_h_aync_2d     <= 1'd0;
        ri_v_aync       <= 1'd0;
        r_valid_async_1d<= 1'd0;
        r_v_async_1d     <= 1'd0;
    end else begin
        ri_serial_frame <= i_serial_frame;
        r_serial_frame_1d <= ri_serial_frame;
        r_serial_frame_2d <= r_serial_frame_1d;
        r_serial_frame_3d <= r_serial_frame_2d;
        ri_h_aync       <= i_h_aync      ;
        ri_v_aync       <= i_v_aync      ;
        r_valid_async_1d<= w_valid_async ;
        r_v_async_1d     <= ri_v_aync    ;
        r_h_aync_1d     <= ri_h_aync    ;
        r_h_aync_2d     <= r_h_aync_1d;
    end
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_input_row_cnt <= 16'd0;
    else if(!ri_v_aync)
        r_input_row_cnt <= 16'd0;
    else if(w_valid_async_pos)
        r_input_row_cnt <= r_input_row_cnt + 16'd1;
    else
        r_input_row_cnt <= r_input_row_cnt;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n)
        r_last_row_flag <= 1'd0;
    else if(w_valid_async_pos && r_input_row_cnt == P_COL_HEIGHT-1)
        r_last_row_flag <= 1'd1;
    else if(w_valid_async_neg && r_input_row_cnt == P_COL_HEIGHT-1)
        r_last_row_flag <= 1'd0;
    else
        r_last_row_flag <= r_last_row_flag;
end

always @(posedge i_clk , negedge i_rst_n) begin
    if(!i_rst_n) ro_source_h_aync <= 1'b0;
    else if(r_h_aync_2d) ro_source_h_aync <= 1'b1;
    else ro_source_h_aync <= 1'b0;
end
//根据输出行数实例化不同存储结构
generate
    case (P_WAIT_ROW_NUM)
        (5) :begin : initial_5rows_tdram_gen
            reg [P_ADDR_WIDTH-1:0]  r_addra1    ;
            reg                     r_wea1      ;
            reg [P_DATA_WIDTH-1:0]  r_dina1     ;
            reg [P_ADDR_WIDTH-1:0]  r_addrb1    ;
            wire[P_DATA_WIDTH-1:0]  w_doutb1    ;
            reg                     r_enb1      ;

            reg [P_ADDR_WIDTH-1:0]  r_addra2    ;
            reg                     r_wea2      ;
            reg [P_DATA_WIDTH-1:0]  r_dina2     ;
            reg [P_ADDR_WIDTH-1:0]  r_addrb2    ;
            wire[P_DATA_WIDTH-1:0]  w_doutb2    ;
            reg                     r_enb2      ;

            reg [P_ADDR_WIDTH-1:0]  r_addra3    ;
            reg                     r_wea3      ;
            reg [P_DATA_WIDTH-1:0]  r_dina3     ;
            reg [P_ADDR_WIDTH-1:0]  r_addrb3    ;
            wire[P_DATA_WIDTH-1:0]  w_doutb3    ;
            reg                     r_enb3      ;

            reg [P_ADDR_WIDTH-1:0]  r_addra4    ;
            reg                     r_wea4      ;
            reg [P_DATA_WIDTH-1:0]  r_dina4     ;
            reg [P_ADDR_WIDTH-1:0]  r_addrb4    ;
            wire[P_DATA_WIDTH-1:0]  w_doutb4    ;
            reg                     r_enb4      ;
            initial_5rows_tdram #(
                .P_ROW_WIDTH  (P_ROW_WIDTH  )   ,
                .P_DATA_WIDTH (P_DATA_WIDTH )   ,
                .P_ADDR_WIDTH (P_ADDR_WIDTH )        
            )u_initial_5rows_tdram(
                .i_clk        ( i_clk        ) ,
                .i_rst_n      ( i_rst_n      ) ,
                .addra1       ( r_addra1     ) ,
                .wea1         ( r_wea1       ) ,
                .dina1        ( r_dina1      ) ,
                .addrb1       ( r_addrb1     ) ,
                .doutb1       ( w_doutb1     ) ,
                .enb1         ( r_enb1       ) ,
                .addra2       ( r_addra2     ) ,
                .wea2         ( r_wea2       ) ,
                .dina2        ( r_dina2      ) ,
                .addrb2       ( r_addrb2     ) ,
                .doutb2       ( w_doutb2     ) ,
                .enb2         ( r_enb2       ) ,
                .addra3       ( r_addra3     ) ,
                .wea3         ( r_wea3       ) ,
                .dina3        ( r_dina3      ) ,
                .addrb3       ( r_addrb3     ) ,
                .doutb3       ( w_doutb3     ) ,
                .enb3         ( r_enb3       ) ,
                .addra4       ( r_addra4     ) ,
                .wea4         ( r_wea4       ) ,
                .dina4        ( r_dina4      ) ,
                .addrb4       ( r_addrb4     ) ,
                .doutb4       ( w_doutb4     ) ,
                .enb4         ( r_enb4       ) 
            );
            
            reg     [2:0]       rows_cnt    ;
            reg                 iswrite_en  ;
            reg                 r_enb1234_1d;
            reg                 r_enb1234_2d;
            reg                 r_v_async_2d;
            reg                 r_v_async_3d;
            //set delay times base on output row number
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    r_v_async_2d <= 1'b0;
                    r_v_async_3d <= 1'b0;
                end else begin
                    r_v_async_2d <= r_v_async_1d;
                    r_v_async_3d <= r_v_async_2d;
                end
            end
            //row cnt
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) rows_cnt <= 3'd0;
                else if(rows_cnt == 3'd4 && w_valid_async_neg) rows_cnt <= 3'd0;
                else if(w_valid_async_neg) rows_cnt <= rows_cnt + 3'd1;
                else rows_cnt <= rows_cnt;
            end
            //when start to write, set to 1, when have writen two raws done, set to 0
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) iswrite_en <= 1'b0;
                else if(w_v_async_neg) iswrite_en <= 1'b0;
                else if(w_valid_async)iswrite_en <= 1'b1;
                else iswrite_en <= iswrite_en;
            end
            //write first row to tdram
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    r_wea1 <= 1'd0;
                    r_dina1 <= 'd0;
                end else if(w_valid_async && rows_cnt == 3'd0)begin
                    r_wea1 <= 1'd1;
                    iswrite_en <= 1'd1;
                    r_dina1 <= ri_serial_frame;
                end else begin
                    r_wea1 <= 1'd0;
                    r_dina1 <= 'd0;
                end
            end
            // write addr signal need to be set singlly,since it increase with wea signal
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addra1 <= 'd0;
                else if(r_wea1) r_addra1 <= r_addra1 + 1'd1;
                else r_addra1 <= 'd0;
            end
            //write second row to tdram
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    r_wea2 <= 1'd0;
                    r_dina2 <= 'd0;
                end else if(w_valid_async && rows_cnt == 3'd1)begin
                    r_wea2 <= 1'd1;
                    r_dina2 <= ri_serial_frame;
                end else begin
                    r_wea2 <= 1'd0;
                    r_dina2 <= 'd0;
                end
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addra2 <= 'd0;
                else if(r_wea2) r_addra2 <= r_addra2 + 1'd1;
                else r_addra2 <= 'd0;
            end
            //write third row to tdram
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    r_wea3 <= 1'd0;
                    r_dina3 <= 'd0;
                end else if(w_valid_async && rows_cnt == 3'd2)begin
                    r_wea3 <= 1'd1;
                    r_dina3 <= ri_serial_frame;
                end else begin
                    r_wea3 <= 1'd0;
                    r_dina3 <= 'd0;
                end
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addra3 <= 'd0;
                else if(r_wea3) r_addra3 <= r_addra3 + 1'd1;
                else r_addra3 <= 'd0;
            end
            //write fourth row to tdram
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    r_wea4 <= 1'd0;
                    r_dina4 <= 'd0;
                end else if(w_valid_async && rows_cnt == 3'd3)begin
                    r_wea4 <= 1'd1;
                    r_dina4 <= ri_serial_frame;
                end else begin
                    r_wea4 <= 1'd0;
                    r_dina4 <= 'd0;
                end
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addra4 <= 'd0;
                else if(r_wea4) r_addra4 <= r_addra4 + 1'd1;
                else r_addra4 <= 'd0;
            end
            //when fiveth row is coming after have writen two raws data into tdram, starting to read 3 rows data(first row, second row, now row) from tdram
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    r_enb1 <= 1'b0;
                    r_enb2 <= 1'b0;
                    r_enb3 <= 1'b0;
                    r_enb4 <= 1'b0;
                end else if(w_valid_async_neg || !ri_h_aync) begin
                    r_enb1 <= 1'b0;
                    r_enb2 <= 1'b0;
                    r_enb3 <= 1'b0;
                    r_enb4 <= 1'b0;
                end else if(w_valid_async_pos && rows_cnt == 3'd4)begin
                    r_enb1 <= 1'b1;
                    r_enb2 <= 1'b1;
                    r_enb3 <= 1'b1;
                    r_enb4 <= 1'b1;
                end else if(w_valid_async_pos && r_input_row_cnt == P_COL_HEIGHT-1)begin
                    r_enb1 <= 1'b1;
                    r_enb2 <= 1'b1;
                    r_enb3 <= 1'b1;
                    r_enb4 <= 1'b1;
                end else begin
                    r_enb1 <= r_enb1;
                    r_enb2 <= r_enb2;
                    r_enb3 <= r_enb3;
                    r_enb4 <= r_enb4;
                end
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addrb1 <= 'd0;
                else if(r_enb1) r_addrb1 <= r_addrb1 +'d1;
                else r_addrb1 <= 'd0;
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addrb2 <= 'd0;
                else if(r_enb2) r_addrb2 <= r_addrb2 +'d1;
                else r_addrb2 <= 'd0;
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addrb3 <= 'd0;
                else if(r_enb3) r_addrb3 <= r_addrb3 +'d1;
                else r_addrb3 <= 'd0;
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addrb4 <= 'd0;
                else if(r_enb4) r_addrb4 <= r_addrb4 +'d1;
                else r_addrb4 <= 'd0;
            end
            //output 3rows data r_serial_frame_2d
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) begin
                    r_enb1234_1d <= 'd0;
                    r_enb1234_2d <= 'd0;
                end
                else begin
                    r_enb1234_1d <= r_enb1 && r_enb2 && r_enb3 && r_enb4;
                    r_enb1234_2d <= r_enb1234_1d;
                end
            end

            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) ro_parallel_row <= 'd0;
                else if(r_enb1234_2d && r_input_row_cnt <= P_COL_HEIGHT-1) ro_parallel_row <= {w_doutb1,w_doutb2,w_doutb3,w_doutb4,r_serial_frame_3d};
                else if(r_enb1234_2d && r_input_row_cnt == P_COL_HEIGHT) begin
                    case (P_REMAINDER_ROWS)
                            1 :  ro_parallel_row <= {r_serial_frame_3d,P_REMAINDER_ROWS[P_DATA_WIDTH-1:0],P_REMAINDER_ROWS[P_DATA_WIDTH-1:0],P_REMAINDER_ROWS[P_DATA_WIDTH-1:0],P_REMAINDER_ROWS[P_DATA_WIDTH-1:0]};
                            2 :  ro_parallel_row <= {w_doutb1,r_serial_frame_3d,P_REMAINDER_ROWS[P_DATA_WIDTH-1:0],P_REMAINDER_ROWS[P_DATA_WIDTH-1:0],P_REMAINDER_ROWS[P_DATA_WIDTH-1:0]};
                            3 :  ro_parallel_row <= {w_doutb1,w_doutb2,r_serial_frame_3d,P_REMAINDER_ROWS[P_DATA_WIDTH-1:0],P_REMAINDER_ROWS[P_DATA_WIDTH-1:0]};
                            4 :  ro_parallel_row <= {w_doutb1,w_doutb2,w_doutb3,r_serial_frame_3d,P_REMAINDER_ROWS[P_DATA_WIDTH-1:0]};
                        default :  ro_parallel_row <= {w_doutb1,w_doutb2,w_doutb3,w_doutb4,r_serial_frame_3d};
                    endcase
                end
                else ro_parallel_row <= 'd0;
            end

            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) ro_h_aync <= 1'b0;
                else if(r_enb1234_2d) ro_h_aync <= 1'b1;
                else ro_h_aync <= 1'b0;
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) ro_remainder_signal <= 1'b0;
                else if(r_enb1234_2d && r_input_row_cnt == P_COL_HEIGHT && P_REMAINDER_ROWS != 0) ro_remainder_signal <= 1'b1;
                else ro_remainder_signal <= 1'b0;
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) ro_v_aync <= 1'b0;
                else if(r_v_async_3d) ro_v_aync <= 1'b1;
                else ro_v_aync <= 1'b0;
            end
        end
        default : begin : initial_3rows_tdram_gen
            reg [P_ADDR_WIDTH-1:0]  r_addra1    ;
            reg                     r_wea1      ;
            reg [P_DATA_WIDTH-1:0]  r_dina1     ;
            
            reg [P_ADDR_WIDTH-1:0]  r_addrb1    ;
            wire[P_DATA_WIDTH-1:0]  w_doutb1    ;
            reg                     r_enb1      ;

            reg [P_ADDR_WIDTH-1:0]  r_addra2    ;
            reg                     r_wea2      ;
            reg [P_DATA_WIDTH-1:0]  r_dina2     ;

            reg [P_ADDR_WIDTH-1:0]  r_addrb2    ;
            wire[P_DATA_WIDTH-1:0]  w_doutb2    ;
            reg                     r_enb2      ;

            initial_3rows_tdram #(
                .P_ROW_WIDTH  (P_ROW_WIDTH  )   ,
                .P_DATA_WIDTH (P_DATA_WIDTH )   ,
                .P_ADDR_WIDTH (P_ADDR_WIDTH )    
            )initial_3rows_tdram_U0(
                .i_clk        ( i_clk       )   ,
                .i_rst_n      ( i_rst_n     )   ,
                .addra1       ( r_addra1    )   ,
                .wea1         ( r_wea1      )   ,
                .dina1        ( r_dina1     )   ,
                .addrb1       ( r_addrb1    )   ,
                .doutb1       ( w_doutb1    )   ,
                .enb1         ( r_enb1      )   ,
                .addra2       ( r_addra2    )   ,
                .wea2         ( r_wea2      )   ,
                .dina2        ( r_dina2     )   ,
                .addrb2       ( r_addrb2    )   ,
                .doutb2       ( w_doutb2    )   ,
                .enb2         ( r_enb2      )   
            );
            reg    [1:0]    rows_cnt;
            reg             iswrite_en;
            reg             r_enb12_1d;
            reg             r_enb12_2d;
            //row cnt
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) rows_cnt <= 2'd0;
                else if(rows_cnt == 2'd2 && w_valid_async_neg) rows_cnt <= 2'd0;
                else if(w_valid_async_neg) rows_cnt <= rows_cnt + 2'd1;
                else rows_cnt <= rows_cnt;
            end
            //when start to write, set to 1, when have writen two raws done, set to 0
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) iswrite_en <= 1'b0;
                else if(w_v_async_neg) iswrite_en <= 1'b0;
                else if(w_valid_async)iswrite_en <= 1'b1;
                else iswrite_en <= iswrite_en;
            end
            //write first row to tdram
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    r_wea1 <= 1'd0;
                    r_dina1 <= 'd0;
                end else if(w_valid_async && rows_cnt == 2'd0 )begin
                    r_wea1 <= 1'd1;
                    iswrite_en <= 1'd1;
                    r_dina1 <= ri_serial_frame;
                end else begin
                    r_wea1 <= 1'd0;
                    r_dina1 <= 'd0;
                end
            end
            // write addr signal need to be set lonely,since it increase with wea signal
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addra1 <= 'd0;
                else if(r_wea1) r_addra1 <= r_addra1 + 1'd1;
                else r_addra1 <= 'd0;
            end
            //write second row to tdram
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    r_wea2 <= 1'd0;
                    r_dina2 <= 'd0;
                end else if(w_valid_async && rows_cnt == 1'd1)begin
                    r_wea2 <= 1'd1;
                    r_dina2 <= ri_serial_frame;
                end else begin
                    r_wea2 <= 1'd0;
                    r_dina2 <= 'd0;
                end
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addra2 <= 'd0;
                else if(r_wea2) r_addra2 <= r_addra2 + 1'd1;
                else r_addra2 <= 'd0;
            end
            //when third row is coming after have writen two raws data into tdram, starting to read 3 rows data(first row, second row, now row) from tdram
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n)begin
                    r_enb1 <= 1'b0;
                    r_enb2 <= 1'b0;
                end else if(w_valid_async_neg || !ri_h_aync) begin
                    r_enb1 <= 1'b0;
                    r_enb2 <= 1'b0;
                end else if(w_valid_async_pos && rows_cnt == 2'd2)begin
                    r_enb1 <= 1'b1;
                    r_enb2 <= 1'b1;
                end else if(w_valid_async_pos && r_input_row_cnt == P_COL_HEIGHT-1)begin
                    r_enb1 <= 1'b1;
                    r_enb2 <= 1'b1;
                end else begin
                    r_enb1 <= r_enb1;
                    r_enb2 <= r_enb2;
                end
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addrb1 <= 'd0;
                else if(r_enb1) r_addrb1 <= r_addrb1 +'d1;
                else r_addrb1 <= 'd0;
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) r_addrb2 <= 'd0;
                else if(r_enb2) r_addrb2 <= r_addrb2 +'d1;
                else r_addrb2 <= 'd0;
            end
            //output 3rows data r_serial_frame_2d
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) begin
                    r_enb12_1d <= 'd0;
                    r_enb12_2d <= 'd0;
                end
                else begin
                    r_enb12_1d <= r_enb1 && r_enb2;
                    r_enb12_2d <= r_enb12_1d;
                end
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) ro_parallel_row <= 'd0;
                else if(r_enb12_2d && r_input_row_cnt <= P_COL_HEIGHT-1)
                    ro_parallel_row <= {w_doutb1,w_doutb2,r_serial_frame_3d};
                else if(r_enb12_2d && r_input_row_cnt == P_COL_HEIGHT) begin
                    case (P_REMAINDER_ROWS)
                            1 :  ro_parallel_row <= {r_serial_frame_3d,P_REMAINDER_ROWS[P_DATA_WIDTH-1:0],P_REMAINDER_ROWS[P_DATA_WIDTH-1:0]};
                            2 :  ro_parallel_row <= {w_doutb1,r_serial_frame_3d,P_REMAINDER_ROWS[P_DATA_WIDTH-1:0]};
                        default :  ro_parallel_row <= {w_doutb1,w_doutb2,r_serial_frame_3d};
                    endcase
                end else ro_parallel_row <= 'd0;
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) ro_h_aync <= 1'b0;
                else if(r_enb12_2d) ro_h_aync <= 1'b1;
                else ro_h_aync <= 1'b0;
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) ro_remainder_signal <= 1'b0;
                else if(r_enb12_2d && r_input_row_cnt == P_COL_HEIGHT && P_REMAINDER_ROWS != 0) ro_remainder_signal <= 1'b1;
                else ro_remainder_signal <= 1'b0;
            end
            always @(posedge i_clk , negedge i_rst_n) begin
                if(!i_rst_n) ro_v_aync <= 1'b0;
                else if(r_v_async_1d) ro_v_aync <= 1'b1;
                else ro_v_aync <= 1'b0;
            end

        end
    endcase
endgenerate

endmodule
