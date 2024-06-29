`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/25 17:53:49
// Design Name: 
// Module Name: HBF_filter
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


module HBF_filter
#(
    parameter P_IMAGE_WIDTH        = 256   ,
    parameter P_IMAGE_HEIGHT       = 256   ,
    parameter P_PIXEL_WIDTH        =  8    ,
    parameter P_OUTPUT_ROWS_NUM    =  3    ,
    parameter P_ADDR_WIDTH         =  11   ,
    parameter P_EXPEND_NUM         =   1      //填充圈数，默认填充一圈
)
(
    input                           i_clk           ,
    input                           i_rst_n         ,
    input                           i_h_sync        ,
    input                           i_v_sync        ,
    input   [P_PIXEL_WIDTH-1:0]     i_image_data    ,

    output                          o_v_sync        ,
    output                          o_h_sync        ,
    output   [19:0]                 o_mean_value    
);


//frame data is converted to parallel row data
wire                                        w_h_aync        ;
wire                                        w_v_aync        ;
wire [P_PIXEL_WIDTH*P_OUTPUT_ROWS_NUM-1:0]  w_parallel_row  ;
wire                                        w_remain_sig    ;
wire                                        w_source_h_aync ;

serial_frame2parallel_row #(
    .P_ROW_WIDTH        (P_IMAGE_WIDTH      ),
    .P_COL_HEIGHT       (P_IMAGE_HEIGHT     ),
    .P_DATA_WIDTH       (P_PIXEL_WIDTH      ),
    .P_WAIT_ROW_NUM     (P_OUTPUT_ROWS_NUM  ),
    .P_ADDR_WIDTH       (P_ADDR_WIDTH       )
)serial_frame2parallel_row_U0(
    .i_clk              (i_clk              ),
    .i_rst_n            (i_rst_n            ),
    .i_serial_frame     (i_image_data       ),
    .i_h_aync           (i_h_sync           ),
    .i_v_aync           (i_v_sync           ),
    .o_v_aync           (w_v_aync           ),
    .o_h_aync           (w_h_aync           ),
    .o_parallel_row     (w_parallel_row     ),
    .o_remainder_signal (w_remain_sig       ),
    .o_source_h_aync    (w_source_h_aync    )
);


// insert edge signal
wire                    w_v_async         ;
wire                    w_h_async         ;
wire    [P_PIXEL_WIDTH*P_OUTPUT_ROWS_NUM-1:0]     w_rows_data;
wire                    w_remainder_signal;
wire                    w_lefe_edge_en    ;
wire                    w_top_edge_en     ;
wire                    w_right_edge_en   ;
wire                    w_bottom_edge_en  ;

//insert edge signal
rows_insert_edge #(
    .P_INPUT_ROWS_NUM   (P_OUTPUT_ROWS_NUM   ),
    .P_IMAGE_HEIGHT     (P_IMAGE_HEIGHT      ),
    .P_IMAGE_WIDTH      (P_IMAGE_WIDTH       ),
    .P_ROW_DATA_WIDTH   (P_PIXEL_WIDTH       )
)rows_insert_edge_U0(
    .i_clk              ( i_clk              ),
    .i_rst_n            ( i_rst_n            ),
    .i_v_async          ( w_v_aync           ),
    .i_h_async          ( w_h_aync           ),
    .i_remainder_signal ( w_remain_sig       ),
    .i_rows_data        ( w_parallel_row     ),

    .o_v_async          ( w_v_async          ),
    .o_h_async          ( w_h_async          ),
    .o_rows_data        ( w_rows_data        ),
    .o_remainder_signal ( w_remainder_signal ),
    .o_lefe_edge_en     ( w_lefe_edge_en     ),
    .o_top_edge_en      ( w_top_edge_en      ),
    .o_right_edge_en    ( w_right_edge_en    ),
    .o_bottom_edge_en   ( w_bottom_edge_en   )
);

wire               w_v_sync1    ;
wire               w_h_sync1    ;
wire  [P_PIXEL_WIDTH*P_OUTPUT_ROWS_NUM-1:0]  w_pads_data ;
wire               w_padding_remain_sign ;

//symmetric padding
image_symmetric_padding #(
    .P_INPUT_ROWS_NUM    (P_OUTPUT_ROWS_NUM ),
    .P_IMAGE_WIDTH       (P_IMAGE_WIDTH     ),
    .P_DATA_WIDTH        (P_PIXEL_WIDTH     ),
    .P_ADDR_WIDTH        (P_ADDR_WIDTH      ),
    .P_EXPEND_NUM        (P_EXPEND_NUM      )
)
image_symmetric_padding_U0(
    .i_clk               ( i_clk             ),
    .i_rst_n             ( i_rst_n           ),
    .i_h_async           ( w_h_async         ),
    .i_v_async           ( w_v_async         ),
    .i_raws_data         ( w_rows_data       ),
    .i_remainder_signal  ( w_remainder_signal),
    .i_left_en           ( w_lefe_edge_en    ),
    .i_right_en          ( w_right_edge_en   ),
    .i_top_en            ( w_top_edge_en     ),
    .i_bottom_en         ( w_bottom_edge_en  ),
    .o_v_sync            ( w_v_sync1         ),
    .o_h_sync            ( w_h_sync1         ),
    .o_pads_data         ( w_pads_data       ),
    .o_padding_remain_sign(w_padding_remain_sign)
);

wire                        w_v_sync2    ;
wire                        w_h_sync2    ;
wire [P_PIXEL_WIDTH-1:0]    w_data2      ;

parallel_3rows2serial_frame #(
    .P_DATA_WIDTH        ( P_PIXEL_WIDTH    ),
    .P_ROW_WIDTH         ( P_IMAGE_WIDTH+2*P_EXPEND_NUM),
    .P_ADDR_WIDTH        ( P_ADDR_WIDTH+1   )
)
parallel_3rows2serial_frame_U0(
    .i_clk               (i_clk             ),
    .i_rst_n             (i_rst_n           ),
    .i_h_sync            (w_h_sync1         ),
    .i_v_sync            (w_v_sync1         ),
    .i_source_h_sync     (w_source_h_aync   ),
    .i_data              (w_pads_data       ),
    .i_remainder_signal  (w_padding_remain_sign),
    .o_h_sync            (w_h_sync2         ),
    .o_v_sync            (w_v_sync2         ),
    .o_data              (w_data2           )
);

wire                w_h_sync3  ;
wire                w_v_sync3  ;
wire    [P_PIXEL_WIDTH*P_OUTPUT_ROWS_NUM-1:0] w_rows_row1;
wire    [P_PIXEL_WIDTH*P_OUTPUT_ROWS_NUM-1:0] w_rows_row2;
wire    [P_PIXEL_WIDTH*P_OUTPUT_ROWS_NUM-1:0] w_rows_row3;

line_sliding_window_3X3 #(
    .P_DATA_WIDTH        (P_PIXEL_WIDTH ),
    .P_IMAGE_WIDTH       (P_IMAGE_WIDTH+2*P_EXPEND_NUM)
)line_sliding_window_3X3_U0(
    .i_clk              ( i_clk        ),
    .i_rst_n            ( i_rst_n      ),
    .i_h_sync           ( w_h_sync2    ),
    .i_v_sync           ( w_v_sync2    ),
    .i_data             ( w_data2      ),
    .o_h_aync           ( w_h_sync3    ),
    .o_v_sync           ( w_v_sync3    ),
    .o_data_row3        ( w_rows_row1  ),
    .o_data_row2        ( w_rows_row2  ),
    .o_data_row1        ( w_rows_row3  )
);

wire               w_h_sync4    ;
wire               w_v_sync4    ;
wire    [P_PIXEL_WIDTH-1:0]    w_mean_value;

//mean filter
mean_filter_3X3 mean_filter_3X3_U0(
    .i_clk              ( i_clk           ),
    .i_rst_n            ( i_rst_n         ),
    .i_h_sync           ( w_h_sync3       ),
    .i_v_sync           ( w_v_sync3       ),
    .i_raws_col1        ( w_rows_row1     ),
    .i_raws_col2        ( w_rows_row2     ),
    .i_raws_col3        ( w_rows_row3     ),
    .o_h_sync           ( w_h_sync4       ),
    .o_v_sync           ( w_v_sync4       ),
    .o_mean_value       ( w_mean_value    )
);

wire                            w_h_sync5;
wire                            w_v_sync5;
wire    [P_PIXEL_WIDTH-1:0]     w_data5  ;

delay_line_data #(
    .P_DATA_WIDTH   (P_PIXEL_WIDTH  ),
    .P_DELAY_TIMES  (3217           )
)
delay_line_data_Delay16
(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .i_v_sync     (w_img_vsync   ),
    .i_h_sync     (w_img_hsync   ),
    .i_data       (w_Y_channel   ),
    .o_h_sync     (w_h_sync5     ),
    .o_v_sync     (w_v_sync5     ),
    .o_data       (w_data5       )
);



wire                            w_h_aync_m   ;
wire                            w_v_aync_m   ;
wire    [P_PIXEL_WIDTH-1:0]     w_data_m     ;
wire                            w_v_aync_s   ;
wire                            w_h_aync_s   ;
wire    [P_PIXEL_WIDTH-1:0]     w_data_s     ;

input_data_alignment #(
    .P_DATA_WIDTH (P_PIXEL_WIDTH),
    .P_IMAGE_WIDTH( 256         )
)
input_data_alignment_U0(
    .i_clk        (i_clk        ),
    .i_rst_n      (i_rst_n      ),
    .i_h_aync_m   (w_h_sync5    ),
    .i_v_aync_m   (w_v_sync5    ),
    .i_data_m     (w_data5      ),
    .i_v_aync_s   (w_v_sync4    ),
    .i_h_aync_s   (w_h_sync4    ),
    .i_data_s     (w_mean_value ),
    .o_h_aync_m   (w_h_aync_m   ),
    .o_v_aync_m   (w_v_aync_m   ),
    .o_data_m     (w_data_m     ),
    .o_v_aync_s   (w_v_aync_s   ),
    .o_h_aync_s   (w_h_aync_s   ),
    .o_data_s     (w_data_s     )
);

wire                            w_h_sync6;
wire                            w_v_sync6;
wire    [P_PIXEL_WIDTH-1:0]     w_data6  ;

subtraction_remove_less_than_zero #(
    .P_DATA_WIDTH (P_PIXEL_WIDTH)
)subtraction_remove_less_than_zero_U0(
    .i_clk       ( i_clk        ),
    .i_rst_n     ( i_rst_n      ),
    .i_h_aync_m  (w_h_aync_m    ),
    .i_v_aync_m  (w_v_aync_m    ),
    .i_data_m    (w_data_m      ),
    .i_v_aync_s  (w_v_aync_s    ),
    .i_h_aync_s  (w_h_aync_s    ),
    .i_data_s    (w_data_s      ),
    .o_h_aync    (w_h_sync6     ),
    .o_v_aync    (w_v_sync6     ),
    .o_res_data  (w_data6       )
);

wire              w_h_sync7;
wire              w_v_sync7;
wire    [7:0]     w_data7  ;

delay_line_data #(
    .P_DATA_WIDTH   (P_PIXEL_WIDTH  ),
    .P_DELAY_TIMES  (3228           )
)
delay_line_data_Delay20
(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .i_v_sync     (w_img_vsync   ),
    .i_h_sync     (w_img_hsync   ),
    .i_data       (w_Y_channel   ),
    .o_h_sync     (w_h_sync7     ),
    .o_v_sync     (w_v_sync7     ),
    .o_data       (w_data7       )
);

wire                            w_h_aync_m1   ;
wire                            w_v_aync_m1   ;
wire    [P_PIXEL_WIDTH-1:0]     w_data_m1     ;
wire                            w_v_aync_s1   ;
wire                            w_h_aync_s1   ;
wire    [P_PIXEL_WIDTH-1:0]     w_data_s1     ;
input_data_alignment #(
    .P_DATA_WIDTH (P_PIXEL_WIDTH),
    .P_IMAGE_WIDTH( 256         )
)
input_data_alignment_U1(
    .i_clk        (i_clk        ),
    .i_rst_n      (i_rst_n      ),
    .i_h_aync_m   (w_h_sync7    ),
    .i_v_aync_m   (w_v_sync7    ),
    .i_data_m     (w_data7      ),
    .i_v_aync_s   (w_v_sync6    ),
    .i_h_aync_s   (w_h_sync6    ),
    .i_data_s     (w_data6      ),
    .o_h_aync_m   (w_h_aync_m1  ),
    .o_v_aync_m   (w_v_aync_m1  ),
    .o_data_m     (w_data_m1    ),
    .o_v_aync_s   (w_v_aync_s1  ),
    .o_h_aync_s   (w_h_aync_s1  ),
    .o_data_s     (w_data_s1    )
);

multi_hight_feature multi_hight_feature_U0(
    .i_clk       ( i_clk       ),
    .i_rst_n     ( i_rst_n     ),
    .i_h_aync_m  (w_h_aync_m1   ),
    .i_v_aync_m  (w_v_aync_m1   ),
    .i_data_m    (w_data_m1     ),
    .i_v_aync_s  (w_v_aync_s1   ),
    .i_h_aync_s  (w_h_aync_s1   ),
    .i_data_s    (w_data_s1     ),
    .o_h_aync    (o_h_sync     ),
    .o_v_aync    (o_v_sync     ),
    .o_res_data  (o_mean_value )
);



endmodule
