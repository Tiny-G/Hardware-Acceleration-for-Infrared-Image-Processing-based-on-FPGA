`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/23 15:58:42
// Design Name: 
// Module Name: CDLCM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 查分约束函数，输入是一行图像数据，不过位宽是20bit,是经乘法的
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CDLCM
#(
    parameter          P_DATA_WIDTH     = 20    ,
    parameter          P_IMAGE_WIDTH    = 256   ,
    parameter          P_IMAGE_HEIGHT   = 256   ,
    parameter          P_OUT_DATA_WIDTH = 32   
)
(
    input                           i_clk        ,
    input                           i_rst_n      ,
    input                           i_v_sync     ,
    input                           i_h_sync     ,
    input   [P_DATA_WIDTH-1:0]      i_img_data   ,

    output                          o_v_sync     ,
    output                          o_h_sync     ,
    output  [P_OUT_DATA_WIDTH-1:0]  o_img_data 
);

wire                            w_h_sync    ;  
wire                            w_v_sync    ;  
wire    [P_DATA_WIDTH-1:0]      w_data      ;  
wire                            w_left_en   ;  
wire                            w_right_en  ;  
wire                            w_top_en    ;  
wire                            w_bottom_en ;  

frame_insert_edge #(
    .P_DATA_WIDTH   (P_DATA_WIDTH   ),
    .P_IMAGE_HEIGHT (P_IMAGE_HEIGHT )
)u_frame_insert_edge(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .i_h_sync     ( i_h_sync     ),
    .i_v_sync     ( i_v_sync     ),
    .i_data       ( i_img_data   ),
    .o_h_sync     (w_h_sync      ),
    .o_v_sync     (w_v_sync      ),
    .o_data       (w_data        ),
    .o_left_en    (w_left_en     ),
    .o_right_en   (w_right_en    ),
    .o_top_en     (w_top_en      ),
    .o_bottom_en  (w_bottom_en   )
);
localparam         P_MASK_SIZE  = 3 ;
/*------------------尺度3------------------*/
localparam         P_SCALE_SIZE_3 = 3 ;
localparam         P_PADDING_CYCLES_4= 4;
localparam         P_SLIDE_WINDOW_N_33 = P_MASK_SIZE *P_SCALE_SIZE_3;

wire    [P_DATA_WIDTH-1:0]  w_data11   ;
wire                        w_v_sync11 ;
wire                        w_h_sync11 ;
image_replicate_padding #(
    .P_DATA_WIDTH (P_DATA_WIDTH ),
    .P_PAD_CYCLES (P_PADDING_CYCLES_4),
    .P_IMG_WIDTH  (P_IMAGE_WIDTH)
)image_replicate_padding_U0(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .i_v_sync     (w_v_sync      ),
    .i_h_sync     (w_h_sync      ),
    .i_data       (w_data        ),
    .i_left_en    (w_left_en     ),
    .i_right_en   (w_right_en    ),
    .i_top_en     (w_top_en      ),
    .i_bottom_en  (w_bottom_en   ),
    .o_data       (w_data11       ),
    .o_v_sync     (w_v_sync11     ),
    .o_h_sync     (w_h_sync11     )
);



wire    [P_DATA_WIDTH*P_SLIDE_WINDOW_N_33*P_SLIDE_WINDOW_N_33-1:0]  w_data21   ;
wire                        w_v_sync21 ;
wire                        w_h_sync21 ;

line_sliding_window_NXN #(
    .P_DATA_WIDTH     (P_DATA_WIDTH     ),
    .P_IMAGE_WIDTH    (P_IMAGE_WIDTH    ),
    .P_IMAGE_HEIGHT   (P_IMAGE_HEIGHT   ),
    .P_SLIDE_WINDOW_N (P_SLIDE_WINDOW_N_33 ),
    .P_PADDING_CYCLES (P_PADDING_CYCLES_4 )
)
line_sliding_window_NXN_U0(
    .i_clk            ( i_clk            ),
    .i_rst_n          ( i_rst_n          ),
    .i_h_sync         (w_h_sync11         ),
    .i_v_sync         (w_v_sync11         ),
    .i_data           (w_data11           ),
    .o_h_aync         (w_h_sync21        ),
    .o_v_sync         (w_v_sync21         ),
    .o_data_matrix    (w_data21           )
);

wire            w_h_sync31    ;
wire            w_v_sync31    ;
wire    [31:0]  w_data31      ;

greater_than_mean_num_mean #(
    .P_DATA_WIDTH        (P_DATA_WIDTH      ),
    .P_SCALE_SIZE        (P_SCALE_SIZE_3    ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH  ),
    .P_MASK_SIZE         (P_MASK_SIZE       )
)greater_than_mean_num_mean_U0(
    .i_clk               ( i_clk            ),
    .i_rst_n             ( i_rst_n          ),
    .i_v_sync            ( w_v_sync21        ),
    .i_h_sync            ( w_h_sync21        ),
    .i_data              ( w_data21          ),
    .o_h_sync            ( w_h_sync31        ),
    .o_v_sync            ( w_v_sync31        ),
    .o_data              ( w_data31          )
);

/*------------------尺度5------------------*/
localparam         P_SCALE_SIZE_5 = 5 ;
localparam         P_PADDING_CYCLES_7 = 10;
localparam         P_SLIDE_WINDOW_N_35 = P_MASK_SIZE *P_SCALE_SIZE_5;

wire    [P_DATA_WIDTH-1:0]  w_data12   ;
wire                        w_v_sync12 ;
wire                        w_h_sync12 ;
image_replicate_padding #(
    .P_DATA_WIDTH (P_DATA_WIDTH ),
    .P_PAD_CYCLES (P_PADDING_CYCLES_7),
    .P_IMG_WIDTH  (P_IMAGE_WIDTH)
)image_replicate_padding_U1(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .i_v_sync     (w_v_sync      ),
    .i_h_sync     (w_h_sync      ),
    .i_data       (w_data        ),
    .i_left_en    (w_left_en     ),
    .i_right_en   (w_right_en    ),
    .i_top_en     (w_top_en      ),
    .i_bottom_en  (w_bottom_en   ),
    .o_data       (w_data12       ),
    .o_v_sync     (w_v_sync12     ),
    .o_h_sync     (w_h_sync12     )
);



wire    [P_DATA_WIDTH*P_SLIDE_WINDOW_N_35*P_SLIDE_WINDOW_N_35-1:0]  w_data22   ;
wire                        w_v_sync22 ;
wire                        w_h_sync22 ;

line_sliding_window_NXN #(
    .P_DATA_WIDTH     (P_DATA_WIDTH     ),
    .P_IMAGE_WIDTH    (P_IMAGE_WIDTH    ),
    .P_IMAGE_HEIGHT   (P_IMAGE_HEIGHT   ),
    .P_SLIDE_WINDOW_N (P_SLIDE_WINDOW_N_35 ),
    .P_PADDING_CYCLES (P_PADDING_CYCLES_7 )
)
line_sliding_window_NXN_U1(
    .i_clk            ( i_clk            ),
    .i_rst_n          ( i_rst_n          ),
    .i_h_sync         (w_h_sync12         ),
    .i_v_sync         (w_v_sync12         ),
    .i_data           (w_data12           ),
    .o_h_aync         (w_h_sync22        ),
    .o_v_sync         (w_v_sync22         ),
    .o_data_matrix    (w_data22           )
);

wire            w_h_sync32    ;
wire            w_v_sync32    ;
wire    [31:0]  w_data32      ;

greater_than_mean_num_mean #(
    .P_DATA_WIDTH        (P_DATA_WIDTH      ),
    .P_SCALE_SIZE        (P_SCALE_SIZE_5    ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH  ),
    .P_MASK_SIZE         (P_MASK_SIZE       )
)greater_than_mean_num_mean_U1(
    .i_clk               ( i_clk            ),
    .i_rst_n             ( i_rst_n          ),
    .i_v_sync            ( w_v_sync22        ),
    .i_h_sync            ( w_h_sync22        ),
    .i_data              ( w_data22          ),
    .o_h_sync            ( w_h_sync32        ),
    .o_v_sync            ( w_v_sync32        ),
    .o_data              ( w_data32          )
);
/*------------------尺度7------------------*/
localparam         P_SCALE_SIZE_7 = 7 ;
localparam         P_PADDING_CYCLES_10 = 10;
localparam         P_SLIDE_WINDOW_N_37 = P_MASK_SIZE *P_SCALE_SIZE_7;

wire    [P_DATA_WIDTH-1:0]  w_data13   ;
wire                        w_v_sync13 ;
wire                        w_h_sync13 ;

image_replicate_padding #(
    .P_DATA_WIDTH (P_DATA_WIDTH ),
    .P_PAD_CYCLES (P_PADDING_CYCLES_10),
    .P_IMG_WIDTH  (P_IMAGE_WIDTH)
)image_replicate_padding_U2(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .i_v_sync     (w_v_sync      ),
    .i_h_sync     (w_h_sync      ),
    .i_data       (w_data        ),
    .i_left_en    (w_left_en     ),
    .i_right_en   (w_right_en    ),
    .i_top_en     (w_top_en      ),
    .i_bottom_en  (w_bottom_en   ),
    .o_data       (w_data13       ),
    .o_v_sync     (w_v_sync13     ),
    .o_h_sync     (w_h_sync13     )
);



wire    [P_DATA_WIDTH*P_SLIDE_WINDOW_N_37*P_SLIDE_WINDOW_N_37-1:0]  w_data23   ;
wire                        w_v_sync23 ;
wire                        w_h_sync23 ;

line_sliding_window_NXN #(
    .P_DATA_WIDTH     (P_DATA_WIDTH     ),
    .P_IMAGE_WIDTH    (P_IMAGE_WIDTH    ),
    .P_IMAGE_HEIGHT   (P_IMAGE_HEIGHT   ),
    .P_SLIDE_WINDOW_N (P_SLIDE_WINDOW_N_37 ),
    .P_PADDING_CYCLES (P_PADDING_CYCLES_10 )
)
line_sliding_window_NXN_U2(
    .i_clk            ( i_clk            ),
    .i_rst_n          ( i_rst_n          ),
    .i_h_sync         (w_h_sync13         ),
    .i_v_sync         (w_v_sync13         ),
    .i_data           (w_data13           ),
    .o_h_aync         (w_h_sync23        ),
    .o_v_sync         (w_v_sync23         ),
    .o_data_matrix    (w_data23           )
);

wire            w_h_sync33    ;
wire            w_v_sync33    ;
wire    [31:0]  w_data33      ;

greater_than_mean_num_mean #(
    .P_DATA_WIDTH        (P_DATA_WIDTH      ),
    .P_SCALE_SIZE        (P_SCALE_SIZE_7    ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH  ),
    .P_MASK_SIZE         (P_MASK_SIZE       )
)greater_than_mean_num_mean_U2(
    .i_clk               ( i_clk            ),
    .i_rst_n             ( i_rst_n          ),
    .i_v_sync            ( w_v_sync23        ),
    .i_h_sync            ( w_h_sync23        ),
    .i_data              ( w_data23          ),
    .o_h_sync            ( w_h_sync33        ),
    .o_v_sync            ( w_v_sync33        ),
    .o_data              ( w_data33          )
);
/*------------------尺度9------------------*/
localparam         P_SCALE_SIZE_9 = 7 ;
localparam         P_PADDING_CYCLES_13 = 13;
localparam         P_SLIDE_WINDOW_N_39 = P_MASK_SIZE *P_SCALE_SIZE_9;

wire    [P_DATA_WIDTH-1:0]  w_data14   ;
wire                        w_v_sync14 ;
wire                        w_h_sync14 ;

image_replicate_padding #(
    .P_DATA_WIDTH (P_DATA_WIDTH ),
    .P_PAD_CYCLES (P_PADDING_CYCLES_13),
    .P_IMG_WIDTH  (P_IMAGE_WIDTH)
)image_replicate_padding_U3(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .i_v_sync     (w_v_sync      ),
    .i_h_sync     (w_h_sync      ),
    .i_data       (w_data        ),
    .i_left_en    (w_left_en     ),
    .i_right_en   (w_right_en    ),
    .i_top_en     (w_top_en      ),
    .i_bottom_en  (w_bottom_en   ),
    .o_data       (w_data14      ),
    .o_v_sync     (w_v_sync14    ),
    .o_h_sync     (w_h_sync14    )
);



wire    [P_DATA_WIDTH*P_SLIDE_WINDOW_N_39*P_SLIDE_WINDOW_N_39-1:0]  w_data24   ;
wire                        w_v_sync24 ;
wire                        w_h_sync24 ;

line_sliding_window_NXN #(
    .P_DATA_WIDTH     (P_DATA_WIDTH     ),
    .P_IMAGE_WIDTH    (P_IMAGE_WIDTH    ),
    .P_IMAGE_HEIGHT   (P_IMAGE_HEIGHT   ),
    .P_SLIDE_WINDOW_N (P_SLIDE_WINDOW_N_39 ),
    .P_PADDING_CYCLES (P_PADDING_CYCLES_13 )
)
line_sliding_window_NXN_U3(
    .i_clk            ( i_clk            ),
    .i_rst_n          ( i_rst_n          ),
    .i_h_sync         (w_h_sync14         ),
    .i_v_sync         (w_v_sync14         ),
    .i_data           (w_data14           ),
    .o_h_aync         (w_h_sync24        ),
    .o_v_sync         (w_v_sync24         ),
    .o_data_matrix    (w_data24           )
);

wire            w_h_sync34    ;
wire            w_v_sync34    ;
wire    [31:0]  w_data34      ;

greater_than_mean_num_mean #(
    .P_DATA_WIDTH        (P_DATA_WIDTH      ),
    .P_SCALE_SIZE        (P_SCALE_SIZE_9    ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH  ),
    .P_MASK_SIZE         (P_MASK_SIZE       )
)greater_than_mean_num_mean_U3(
    .i_clk               ( i_clk            ),
    .i_rst_n             ( i_rst_n          ),
    .i_v_sync            ( w_v_sync24        ),
    .i_h_sync            ( w_h_sync24        ),
    .i_data              ( w_data24          ),
    .o_h_sync            ( w_h_sync34        ),
    .o_v_sync            ( w_v_sync34        ),
    .o_data              ( w_data34          )
);

/*------------------尺度3、5、7、9将其在z轴上叠加，取最大值------------------*/
find_max_value_on_zaxis_4sacles #(
    .P_DATA_WIDTH       (P_OUT_DATA_WIDTH)
)
find_max_value_on_zaxis_4sacles_U0(
    .i_clk              ( i_clk           ) ,
    .i_rst_n            ( i_rst_n         ) ,
    .i_v_sync_1         (w_v_sync31       ) ,
    .i_h_sync_1         (w_h_sync31       ) ,
    .i_data_1           (w_data31         ) ,
    .i_v_sync_2         (w_v_sync32       ) ,
    .i_h_sync_2         (w_h_sync32       ) ,
    .i_data_2           (w_data32         ) ,
    .i_v_sync_3         (w_v_sync33       ) ,
    .i_h_sync_3         (w_h_sync33       ) ,
    .i_data_3           (w_data33         ) ,
    .i_v_sync_4         (w_v_sync34       ) ,
    .i_h_sync_4         (w_h_sync34       ) ,
    .i_data_4           (w_data34         ) ,
    .o_v_sync           ( o_v_sync        ) ,
    .o_h_sync           ( o_h_sync        ) ,
    .o_data             ( o_img_data      ) 
);

endmodule
