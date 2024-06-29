`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/05/23 18:08:44
// Design Name: 
// Module Name: RDLCM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 比差模块
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module RDLCM
#(
    parameter          P_DATA_WIDTH     =  8    ,
    parameter          P_IMG_WIDTH      =  256  ,
    parameter          P_IMG_HEIGHT     =  256  ,
    parameter          P_OUT_DATA_WIDTH =  32
)
(
    input                           i_clk       ,
    input                           i_rst_n     ,
    input                           i_v_sync    ,
    input                           i_h_sync    ,
    input  [P_DATA_WIDTH-1:0]       i_img_data  ,

    output                          o_v_sync    ,
    output                          o_h_sync    ,
    output  [P_OUT_DATA_WIDTH-1:0]  o_img_data
);

localparam         P_MASK_SIZE  = 3 ;

//先插入边界信号
wire                        w_v_sync   ;
wire                        w_h_sync   ;
wire [P_DATA_WIDTH-1:0]     w_data     ;
wire                        w_left_en  ;
wire                        w_right_en ;
wire                        w_top_en   ;
wire                        w_bottom_en;

frame_insert_edge #(
    .P_DATA_WIDTH   (P_DATA_WIDTH),
    .P_IMAGE_HEIGHT (P_IMG_HEIGHT)
)
frame_insert_edge_U1(
    .i_clk        (i_clk         ),
    .i_rst_n      (i_rst_n       ),
    .i_h_sync     (i_h_sync      ),
    .i_v_sync     (i_v_sync      ),
    .i_data       (i_img_data    ),
    .o_v_sync     (w_v_sync      ),
    .o_h_sync     (w_h_sync      ),
    .o_data       (w_data        ),
    .o_left_en    (w_left_en     ),
    .o_right_en   (w_right_en    ),
    .o_top_en     (w_top_en      ),
    .o_bottom_en  (w_bottom_en   )
);


/*-------------------尺度3---------------------*/
localparam         P_SCALE_SIZE_3 = 3 ;
localparam         P_PADDING_CYCLES_4= 4;
localparam         P_SLIDE_WINDOW_N_33 = P_MASK_SIZE *P_SCALE_SIZE_3;


wire    [P_DATA_WIDTH-1:0]  w_data11   ;
wire                        w_v_sync11 ;
wire                        w_h_sync11 ;

//先边界padding
image_replicate_padding #(
    .P_DATA_WIDTH       (P_DATA_WIDTH   ),
    .P_PAD_CYCLES       (P_PADDING_CYCLES_4),
    .P_IMG_WIDTH        (P_IMG_WIDTH    )
)image_replicate_padding_U5(
    .i_clk              ( i_clk         ),
    .i_rst_n            ( i_rst_n       ),
    .i_v_sync           (w_v_sync       ),
    .i_h_sync           (w_h_sync       ),
    .i_data             (w_data         ),
    .i_left_en          (w_left_en      ),
    .i_right_en         (w_right_en     ),
    .i_top_en           (w_top_en       ),
    .i_bottom_en        (w_bottom_en    ),
    .o_data             (w_data11       ),
    .o_v_sync           (w_v_sync11     ),
    .o_h_sync           (w_h_sync11     )
);

wire    [P_DATA_WIDTH*P_SLIDE_WINDOW_N_33*P_SLIDE_WINDOW_N_33-1:0]  w_data12   ;
wire                        w_v_sync12 ;
wire                        w_h_sync12 ;

line_sliding_window_NXN #(
    .P_DATA_WIDTH       (P_DATA_WIDTH       ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        ),
    .P_IMAGE_HEIGHT     (P_IMG_HEIGHT       ),
    .P_SLIDE_WINDOW_N   (P_SLIDE_WINDOW_N_33),
    .P_PADDING_CYCLES   (P_PADDING_CYCLES_4 )
)
line_sliding_window_NXN_U5(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_h_sync           (w_h_sync11         ),
    .i_v_sync           (w_v_sync11         ),
    .i_data             (w_data11           ),
    .o_h_aync           (w_h_sync12         ),
    .o_v_sync           (w_v_sync12         ),
    .o_data_matrix      (w_data12           )
);


wire                            w_v_sync13   ;
wire                            w_h_sync13   ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_max_mean13 ;

//找出九宫格中除开中心周围八个块的均值最大的
find_max_mean_except_center #(
    .P_DATA_WIDTH        (P_DATA_WIDTH         ),
    .P_SCALE_SIZE        (P_SCALE_SIZE_3       ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH     ),
    .P_MASK_SIZE         (P_MASK_SIZE          )
)find_max_mean_except_center_U5(
    .i_clk               ( i_clk               ),
    .i_rst_n             ( i_rst_n             ),
    .i_v_sync            ( w_v_sync12          ),
    .i_h_sync            ( w_h_sync12          ),
    .i_data              ( w_data12            ),
    .o_v_sync            ( w_v_sync13          ),
    .o_h_sync            ( w_h_sync13          ),
    .o_max_mean          ( w_max_mean13        )
);

wire                            w_v_sync14    ;
wire                            w_h_sync14    ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_res_data14  ;

//求输入的原始图像数据的点积
dual_image_hadamard_multi #(
    .P_INPUT_DATA_WIDTH  ( P_DATA_WIDTH       ),
    .P_IMG_WIDTH         ( P_IMG_WIDTH        ),
    .P_IMG_HEIFGHT       ( P_IMG_HEIGHT       ),
    .P_OUTPUT_DATA_WIDTH ( P_OUT_DATA_WIDTH   )
)
dual_image_hadamard_multi_U0(
    .i_clk              ( i_clk               ),
    .i_rst_n            ( i_rst_n             ),
    .i_h_sync_a         ( i_h_sync            ),
    .i_v_sync_a         ( i_v_sync            ),
    .i_data_a           ( i_img_data          ),
    .i_h_sync_b         ( i_h_sync            ),
    .i_v_sync_b         ( i_v_sync            ),
    .i_data_b           ( i_img_data          ),
    .o_v_sync           ( w_v_sync14          ),
    .o_h_sync           ( w_h_sync14          ),
    .o_res_data         ( w_res_data14        )
);

wire                            w_h_sync15  ;
wire                            w_v_sync15  ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_data15    ;

//延迟点积的结果
delay_line_data #(
    .P_DATA_WIDTH       (P_OUT_DATA_WIDTH   ),
    .P_DELAY_TIMES      ( 8                 ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        )
)
delay_line_data_U0(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_v_sync           ( w_v_sync14        ),
    .i_h_sync           ( w_h_sync14        ),
    .i_data             ( w_res_data14      ),
    .o_h_sync           ( w_h_sync15        ),
    .o_v_sync           ( w_v_sync15        ),
    .o_data             ( w_data15          )
);

wire                            w_v_sync16  ;
wire                            w_h_sync16  ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_res_data16;

//除法:原数据除以当前尺度中八个块的最大均值矩阵中每个元素
dual_image_element_wise_division #(
    .P_INPUT_DATA_WIDTH  (P_OUT_DATA_WIDTH  ),
    .P_IMG_WIDTH         (P_IMG_WIDTH       ),
    .P_IMG_HEIFGHT       (P_IMG_HEIGHT      ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH  )
)
dual_image_element_wise_division_U0(
    .i_clk              ( i_clk              ),
    .i_rst_n            ( i_rst_n            ),
    .i_h_sync_m         ( w_h_sync15         ),
    .i_v_sync_m         ( w_v_sync15         ),
    .i_data_m           ( w_data15           ),
    .i_h_sync_s         ( w_h_sync13         ),
    .i_v_sync_s         ( w_v_sync13         ),
    .i_data_s           ( w_max_mean13       ),
    .o_v_sync           ( w_v_sync16         ),
    .o_h_sync           ( w_h_sync16         ),
    .o_res_data         ( w_res_data16       )
);

wire                            w_h_sync17  ;
wire                            w_v_sync17  ;
wire    [P_DATA_WIDTH-1:0]      w_data17    ;

//延迟输入的结果
delay_line_data #(
    .P_DATA_WIDTH       (P_DATA_WIDTH       ),
    .P_DELAY_TIMES      ( 12               ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        )
)
delay_line_data_U1(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_v_sync           ( i_h_sync          ),
    .i_h_sync           ( i_v_sync          ),
    .i_data             ( i_img_data        ),
    .o_h_sync           ( w_h_sync17        ),
    .o_v_sync           ( w_v_sync17        ),
    .o_data             ( w_data17          )
);

wire                            w_v_sync18   ;
wire                            w_h_sync18   ;
wire   [P_OUT_DATA_WIDTH-1:0]   w_res_data18 ;

//减法，原数据减去输入数据，如小于0则取0
dual_image_subtraction #(
    .P_INPUT_DATA_WIDTH (P_OUT_DATA_WIDTH   ),
    .P_IMG_WIDTH        (P_IMG_WIDTH        ),
    .P_IMG_HEIFGHT      (P_IMG_HEIGHT       ),
    .P_OUTPUT_DATA_WIDTH(P_OUT_DATA_WIDTH   )
)u_dual_image_subtraction(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_h_sync_m         ( w_h_sync16        ),
    .i_v_sync_m         ( w_v_sync16        ),
    .i_data_m           ( w_res_data16      ),
    .i_h_sync_s         ( w_h_sync17        ),
    .i_v_sync_s         ( w_v_sync17        ),
    .i_data_s           ( w_data17          ),
    .o_v_sync           ( w_v_sync18        ),
    .o_h_sync           ( w_h_sync18        ),
    .o_res_data         ( w_res_data18      )
);


/*-------------------尺度5---------------------*/
localparam         P_SCALE_SIZE_5 = 5 ;
localparam         P_PADDING_CYCLES_7= 7;
localparam         P_SLIDE_WINDOW_N_35 = P_MASK_SIZE *P_SCALE_SIZE_5;


wire    [P_DATA_WIDTH-1:0]  w_data21   ;
wire                        w_v_sync21 ;
wire                        w_h_sync21 ;

//先边界padding
image_replicate_padding #(
    .P_DATA_WIDTH       (P_DATA_WIDTH   ),
    .P_PAD_CYCLES       (P_PADDING_CYCLES_7),
    .P_IMG_WIDTH        (P_IMG_WIDTH    )
)image_replicate_padding_U6(
    .i_clk              ( i_clk         ),
    .i_rst_n            ( i_rst_n       ),
    .i_v_sync           (w_v_sync       ),
    .i_h_sync           (w_h_sync       ),
    .i_data             (w_data         ),
    .i_left_en          (w_left_en      ),
    .i_right_en         (w_right_en     ),
    .i_top_en           (w_top_en       ),
    .i_bottom_en        (w_bottom_en    ),
    .o_data             (w_data21       ),
    .o_v_sync           (w_v_sync21     ),
    .o_h_sync           (w_h_sync21     )
);

wire    [P_DATA_WIDTH*P_SLIDE_WINDOW_N_35*P_SLIDE_WINDOW_N_35-1:0]  w_data22   ;
wire                        w_v_sync22 ;
wire                        w_h_sync22 ;

line_sliding_window_NXN #(
    .P_DATA_WIDTH       (P_DATA_WIDTH       ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        ),
    .P_IMAGE_HEIGHT     (P_IMG_HEIGHT       ),
    .P_SLIDE_WINDOW_N   (P_SLIDE_WINDOW_N_35),
    .P_PADDING_CYCLES   (P_PADDING_CYCLES_7 )
)
line_sliding_window_NXN_U6(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_h_sync           (w_h_sync21         ),
    .i_v_sync           (w_v_sync21         ),
    .i_data             (w_data21           ),
    .o_h_aync           (w_h_sync22         ),
    .o_v_sync           (w_v_sync22         ),
    .o_data_matrix      (w_data22           )
);


wire                            w_v_sync23   ;
wire                            w_h_sync23   ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_max_mean23 ;

//找出九宫格中除开中心周围八个块的均值最大的
find_max_mean_except_center #(
    .P_DATA_WIDTH        (P_DATA_WIDTH         ),
    .P_SCALE_SIZE        (P_SCALE_SIZE_5       ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH     ),
    .P_MASK_SIZE         (P_MASK_SIZE          )
)
find_max_mean_except_center_U6(
    .i_clk               ( i_clk               ),
    .i_rst_n             ( i_rst_n             ),
    .i_v_sync            ( w_v_sync22          ),
    .i_h_sync            ( w_h_sync22          ),
    .i_data              ( w_data22            ),
    .o_v_sync            ( w_v_sync23          ),
    .o_h_sync            ( w_h_sync23          ),
    .o_max_mean          ( w_max_mean23        )
);


wire                            w_v_sync24    ;
wire                            w_h_sync24    ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_res_data24  ;

//求输入的原始图像数据的点积
dual_image_hadamard_multi #(
    .P_INPUT_DATA_WIDTH  ( P_DATA_WIDTH       ),
    .P_IMG_WIDTH         ( P_IMG_WIDTH        ),
    .P_IMG_HEIFGHT       ( P_IMG_HEIGHT       ),
    .P_OUTPUT_DATA_WIDTH ( P_OUT_DATA_WIDTH   )
)
dual_image_hadamard_multi_U1(
    .i_clk              ( i_clk               ),
    .i_rst_n            ( i_rst_n             ),
    .i_h_sync_a         ( i_h_sync            ),
    .i_v_sync_a         ( i_v_sync            ),
    .i_data_a           ( i_img_data          ),
    .i_h_sync_b         ( i_h_sync            ),
    .i_v_sync_b         ( i_v_sync            ),
    .i_data_b           ( i_img_data          ),
    .o_v_sync           ( w_v_sync24          ),
    .o_h_sync           ( w_h_sync24          ),
    .o_res_data         ( w_res_data24        )
);

wire                            w_h_sync25  ;
wire                            w_v_sync25  ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_data25    ;

//延迟点积的结果
delay_line_data #(
    .P_DATA_WIDTH       (P_OUT_DATA_WIDTH   ),
    .P_DELAY_TIMES      ( 8                 ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        )
)
delay_line_data_U2(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_v_sync           ( w_v_sync24        ),
    .i_h_sync           ( w_h_sync24        ),
    .i_data             ( w_res_data24      ),
    .o_h_sync           ( w_h_sync25        ),
    .o_v_sync           ( w_v_sync25        ),
    .o_data             ( w_data25          )
);

wire                            w_v_sync26  ;
wire                            w_h_sync26  ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_res_data26;


//除法:原数据除以当前尺度中八个块的最大均值矩阵中每个元素
dual_image_element_wise_division #(
    .P_INPUT_DATA_WIDTH  (P_OUT_DATA_WIDTH  ),
    .P_IMG_WIDTH         (P_IMG_WIDTH       ),
    .P_IMG_HEIFGHT       (P_IMG_HEIGHT      ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH  )
)
dual_image_element_wise_division_U1(
    .i_clk              ( i_clk              ),
    .i_rst_n            ( i_rst_n            ),
    .i_h_sync_m         ( w_h_sync25         ),
    .i_v_sync_m         ( w_v_sync25         ),
    .i_data_m           ( w_data25           ),
    .i_h_sync_s         ( w_h_sync23         ),
    .i_v_sync_s         ( w_v_sync23         ),
    .i_data_s           ( w_max_mean23       ),
    .o_v_sync           ( w_v_sync26         ),
    .o_h_sync           ( w_h_sync26         ),
    .o_res_data         ( w_res_data26       )
);

wire                            w_h_sync27  ;
wire                            w_v_sync27  ;
wire    [P_DATA_WIDTH-1:0]      w_data27    ;

//延迟输入的结果
delay_line_data #(
    .P_DATA_WIDTH       (P_DATA_WIDTH       ),
    .P_DELAY_TIMES      (12                 ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        )
)
delay_line_data_U3(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_v_sync           ( i_v_sync          ),
    .i_h_sync           ( i_h_sync          ),
    .i_data             ( i_img_data        ),
    .o_h_sync           ( w_h_sync27        ),
    .o_v_sync           ( w_v_sync27        ),
    .o_data             ( w_data27          )
);

wire                            w_v_sync28   ;
wire                            w_h_sync28   ;
wire   [P_OUT_DATA_WIDTH-1:0]   w_res_data28 ;

//减法，原数据减去输入数据，如小于0则取0
dual_image_subtraction #(
    .P_INPUT_DATA_WIDTH (P_OUT_DATA_WIDTH   ),
    .P_IMG_WIDTH        (P_IMG_WIDTH        ),
    .P_IMG_HEIFGHT      (P_IMG_HEIGHT       ),
    .P_OUTPUT_DATA_WIDTH(P_OUT_DATA_WIDTH   )
)
dual_image_subtraction_U1(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_h_sync_m         ( w_h_sync16        ),
    .i_v_sync_m         ( w_v_sync16        ),
    .i_data_m           ( w_res_data16      ),
    .i_h_sync_s         ( w_h_sync27        ),
    .i_v_sync_s         ( w_v_sync27        ),
    .i_data_s           ( w_data27          ),
    .o_v_sync           ( w_v_sync28        ),
    .o_h_sync           ( w_h_sync28        ),
    .o_res_data         ( w_res_data28      )
);

/*-------------------尺度7---------------------*/
localparam         P_SCALE_SIZE_7       = 7 ;
localparam         P_PADDING_CYCLES_10  = 13;
localparam         P_SLIDE_WINDOW_N_37  = P_MASK_SIZE*P_SCALE_SIZE_7;


wire    [P_DATA_WIDTH-1:0]  w_data31   ;
wire                        w_v_sync31 ;
wire                        w_h_sync31 ;

//先边界padding
image_replicate_padding #(
    .P_DATA_WIDTH       (P_DATA_WIDTH   ),
    .P_PAD_CYCLES       (P_PADDING_CYCLES_10),
    .P_IMG_WIDTH        (P_IMG_WIDTH    )
)image_replicate_padding_U7(
    .i_clk              ( i_clk         ),
    .i_rst_n            ( i_rst_n       ),
    .i_v_sync           (w_v_sync       ),
    .i_h_sync           (w_h_sync       ),
    .i_data             (w_data         ),
    .i_left_en          (w_left_en      ),
    .i_right_en         (w_right_en     ),
    .i_top_en           (w_top_en       ),
    .i_bottom_en        (w_bottom_en    ),
    .o_data             (w_data31       ),
    .o_v_sync           (w_v_sync31     ),
    .o_h_sync           (w_h_sync31     )
);

wire    [P_DATA_WIDTH*P_SLIDE_WINDOW_N_37*P_SLIDE_WINDOW_N_37-1:0]  w_data32   ;
wire                        w_v_sync32 ;
wire                        w_h_sync32 ;

line_sliding_window_NXN #(
    .P_DATA_WIDTH       (P_DATA_WIDTH       ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        ),
    .P_IMAGE_HEIGHT     (P_IMG_HEIGHT       ),
    .P_SLIDE_WINDOW_N   (P_SLIDE_WINDOW_N_37),
    .P_PADDING_CYCLES   (P_PADDING_CYCLES_10 )
)
line_sliding_window_NXN_U7(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_h_sync           (w_h_sync31         ),
    .i_v_sync           (w_v_sync31         ),
    .i_data             (w_data31           ),
    .o_h_aync           (w_h_sync32         ),
    .o_v_sync           (w_v_sync32         ),
    .o_data_matrix      (w_data32           )
);


wire                            w_v_sync33   ;
wire                            w_h_sync33   ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_max_mean33 ;

//找出九宫格中除开中心周围八个块的均值最大的
find_max_mean_except_center #(
    .P_DATA_WIDTH        (P_DATA_WIDTH         ),
    .P_SCALE_SIZE        (P_SCALE_SIZE_7       ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH     ),
    .P_MASK_SIZE         (P_MASK_SIZE          )
)
find_max_mean_except_center_U7(
    .i_clk               ( i_clk               ),
    .i_rst_n             ( i_rst_n             ),
    .i_v_sync            ( w_v_sync32          ),
    .i_h_sync            ( w_h_sync32          ),
    .i_data              ( w_data32            ),
    .o_v_sync            ( w_v_sync33          ),
    .o_h_sync            ( w_h_sync33          ),
    .o_max_mean          ( w_max_mean33        )
);


wire                            w_v_sync34    ;
wire                            w_h_sync34    ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_res_data34  ;

//求输入的原始图像数据的点积
dual_image_hadamard_multi #(
    .P_INPUT_DATA_WIDTH  ( P_DATA_WIDTH       ),
    .P_IMG_WIDTH         ( P_IMG_WIDTH        ),
    .P_IMG_HEIFGHT       ( P_IMG_HEIGHT       ),
    .P_OUTPUT_DATA_WIDTH ( P_OUT_DATA_WIDTH   )
)
dual_image_hadamard_multi_U2(
    .i_clk              ( i_clk               ),
    .i_rst_n            ( i_rst_n             ),
    .i_h_sync_a         ( i_h_sync            ),
    .i_v_sync_a         ( i_v_sync            ),
    .i_data_a           ( i_img_data          ),
    .i_h_sync_b         ( i_h_sync            ),
    .i_v_sync_b         ( i_v_sync            ),
    .i_data_b           ( i_img_data          ),
    .o_v_sync           ( w_v_sync34          ),
    .o_h_sync           ( w_h_sync34          ),
    .o_res_data         ( w_res_data34        )
);

wire                            w_h_sync35  ;
wire                            w_v_sync35  ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_data35    ;

//延迟点积的结果
delay_line_data #(
    .P_DATA_WIDTH       (P_OUT_DATA_WIDTH   ),
    .P_DELAY_TIMES      ( 8                 ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        )
)
delay_line_data_U4(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_v_sync           ( w_v_sync34        ),
    .i_h_sync           ( w_h_sync34        ),
    .i_data             ( w_res_data34      ),
    .o_h_sync           ( w_h_sync35        ),
    .o_v_sync           ( w_v_sync35        ),
    .o_data             ( w_data35          )
);

wire                            w_v_sync36  ;
wire                            w_h_sync36  ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_res_data36;
//除法:原数据除以当前尺度中八个块的最大均值矩阵中每个元素
dual_image_element_wise_division #(
    .P_INPUT_DATA_WIDTH  (P_OUT_DATA_WIDTH  ),
    .P_IMG_WIDTH         (P_IMG_WIDTH       ),
    .P_IMG_HEIFGHT       (P_IMG_HEIGHT      ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH  )
)
dual_image_element_wise_division_U2(
    .i_clk              ( i_clk              ),
    .i_rst_n            ( i_rst_n            ),
    .i_h_sync_m         ( w_h_sync15         ),
    .i_v_sync_m         ( w_v_sync15         ),
    .i_data_m           ( w_data15           ),
    .i_h_sync_s         ( w_h_sync13         ),
    .i_v_sync_s         ( w_v_sync13         ),
    .i_data_s           ( w_max_mean13       ),
    .o_v_sync           ( w_v_sync36         ),
    .o_h_sync           ( w_h_sync36         ),
    .o_res_data         ( w_res_data36       )
);

wire                            w_h_sync37  ;
wire                            w_v_sync37  ;
wire    [P_DATA_WIDTH-1:0]      w_data37    ;

//延迟输入的结果
delay_line_data #(
    .P_DATA_WIDTH       (P_DATA_WIDTH       ),
    .P_DELAY_TIMES      ( 12               ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        )
)
delay_line_data_U5(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_v_sync           ( i_v_sync          ),
    .i_h_sync           ( i_h_sync          ),
    .i_data             ( i_img_data        ),
    .o_h_sync           ( w_h_sync37        ),
    .o_v_sync           ( w_v_sync37        ),
    .o_data             ( w_data37          )
);

wire                            w_v_sync38   ;
wire                            w_h_sync38   ;
wire   [P_OUT_DATA_WIDTH-1:0]   w_res_data38 ;

//减法，原数据减去输入数据，如小于0则取0
dual_image_subtraction #(
    .P_INPUT_DATA_WIDTH (P_OUT_DATA_WIDTH   ),
    .P_IMG_WIDTH        (P_IMG_WIDTH        ),
    .P_IMG_HEIFGHT      (P_IMG_HEIGHT       ),
    .P_OUTPUT_DATA_WIDTH(P_OUT_DATA_WIDTH   )
)
dual_image_subtraction_U2(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_h_sync_m         ( w_h_sync16        ),
    .i_v_sync_m         ( w_v_sync16        ),
    .i_data_m           ( w_res_data16      ),
    .i_h_sync_s         ( w_h_sync17        ),
    .i_v_sync_s         ( w_v_sync17        ),
    .i_data_s           ( w_data17          ),
    .o_v_sync           ( w_v_sync38        ),
    .o_h_sync           ( w_h_sync38        ),
    .o_res_data         ( w_res_data38      )
);

/*-------------------尺度9---------------------*/
localparam         P_SCALE_SIZE_9       = 9 ;
localparam         P_PADDING_CYCLES_13  = 13;
localparam         P_SLIDE_WINDOW_N_39  = P_MASK_SIZE*P_SCALE_SIZE_9;


wire    [P_DATA_WIDTH-1:0]  w_data41   ;
wire                        w_v_sync41 ;
wire                        w_h_sync41 ;

//先边界padding
image_replicate_padding #(
    .P_DATA_WIDTH       (P_DATA_WIDTH   ),
    .P_PAD_CYCLES       (P_PADDING_CYCLES_13),
    .P_IMG_WIDTH        (P_IMG_WIDTH    )
)image_replicate_padding_U8(
    .i_clk              ( i_clk         ),
    .i_rst_n            ( i_rst_n       ),
    .i_v_sync           (w_v_sync       ),
    .i_h_sync           (w_h_sync       ),
    .i_data             (w_data         ),
    .i_left_en          (w_left_en      ),
    .i_right_en         (w_right_en     ),
    .i_top_en           (w_top_en       ),
    .i_bottom_en        (w_bottom_en    ),
    .o_data             (w_data41       ),
    .o_v_sync           (w_v_sync41     ),
    .o_h_sync           (w_h_sync41     )
);

wire    [P_DATA_WIDTH*P_SLIDE_WINDOW_N_39*P_SLIDE_WINDOW_N_39-1:0]  w_data42   ;
wire                        w_v_sync42 ;
wire                        w_h_sync42 ;

line_sliding_window_NXN #(
    .P_DATA_WIDTH       (P_DATA_WIDTH       ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        ),
    .P_IMAGE_HEIGHT     (P_IMG_HEIGHT       ),
    .P_SLIDE_WINDOW_N   (P_SLIDE_WINDOW_N_39),
    .P_PADDING_CYCLES   (P_PADDING_CYCLES_13 )
)
line_sliding_window_NXN_U8(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_h_sync           (w_h_sync41         ),
    .i_v_sync           (w_v_sync41         ),
    .i_data             (w_data41           ),
    .o_h_aync           (w_h_sync42         ),
    .o_v_sync           (w_v_sync42         ),
    .o_data_matrix      (w_data42           )
);


wire                            w_v_sync43   ;
wire                            w_h_sync43   ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_max_mean43 ;

//找出九宫格中除开中心周围八个块的均值最大的
find_max_mean_except_center #(
    .P_DATA_WIDTH        (P_DATA_WIDTH         ),
    .P_SCALE_SIZE        (P_SCALE_SIZE_9       ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH     ),
    .P_MASK_SIZE         (P_MASK_SIZE          )
)
find_max_mean_except_center_U8(
    .i_clk               ( i_clk               ),
    .i_rst_n             ( i_rst_n             ),
    .i_v_sync            ( w_v_sync40          ),
    .i_h_sync            ( w_h_sync40          ),
    .i_data              ( w_data40            ),
    .o_v_sync            ( w_v_sync43          ),
    .o_h_sync            ( w_h_sync43          ),
    .o_max_mean          ( w_max_mean43        )
);


wire                            w_v_sync44    ;
wire                            w_h_sync44    ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_res_data44  ;

//求输入的原始图像数据的点积
dual_image_hadamard_multi #(
    .P_INPUT_DATA_WIDTH  ( P_DATA_WIDTH       ),
    .P_IMG_WIDTH         ( P_IMG_WIDTH        ),
    .P_IMG_HEIFGHT       ( P_IMG_HEIGHT       ),
    .P_OUTPUT_DATA_WIDTH ( P_OUT_DATA_WIDTH   )
)
dual_image_hadamard_multi_U3(
    .i_clk              ( i_clk               ),
    .i_rst_n            ( i_rst_n             ),
    .i_h_sync_a         ( i_h_sync            ),
    .i_v_sync_a         ( i_v_sync            ),
    .i_data_a           ( i_img_data          ),
    .i_h_sync_b         ( i_h_sync            ),
    .i_v_sync_b         ( i_v_sync            ),
    .i_data_b           ( i_img_data          ),
    .o_v_sync           ( w_v_sync44          ),
    .o_h_sync           ( w_h_sync44          ),
    .o_res_data         ( w_res_data44        )
);

wire                            w_h_sync45  ;
wire                            w_v_sync45  ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_data45    ;

//延迟点积的结果
delay_line_data #(
    .P_DATA_WIDTH       (P_OUT_DATA_WIDTH   ),
    .P_DELAY_TIMES      ( 8                 ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        )
)
delay_line_data_U6(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_v_sync           ( w_v_sync44        ),
    .i_h_sync           ( w_h_sync44        ),
    .i_data             ( w_res_data44      ),
    .o_h_sync           ( w_h_sync45        ),
    .o_v_sync           ( w_v_sync45        ),
    .o_data             ( w_data45          )
);

wire                            w_v_sync46  ;
wire                            w_h_sync46  ;
wire    [P_OUT_DATA_WIDTH-1:0]  w_res_data46;
//除法:原数据除以当前尺度中八个块的最大均值矩阵中每个元素
dual_image_element_wise_division #(
    .P_INPUT_DATA_WIDTH  (P_OUT_DATA_WIDTH  ),
    .P_IMG_WIDTH         (P_IMG_WIDTH       ),
    .P_IMG_HEIFGHT       (P_IMG_HEIGHT      ),
    .P_OUTPUT_DATA_WIDTH (P_OUT_DATA_WIDTH  )
)
dual_image_element_wise_division_U3(
    .i_clk              ( i_clk              ),
    .i_rst_n            ( i_rst_n            ),
    .i_h_sync_m         ( w_h_sync45         ),
    .i_v_sync_m         ( w_v_sync45         ),
    .i_data_m           ( w_data45           ),
    .i_h_sync_s         ( w_h_sync43         ),
    .i_v_sync_s         ( w_v_sync43         ),
    .i_data_s           ( w_max_mean43       ),
    .o_v_sync           ( w_v_sync46         ),
    .o_h_sync           ( w_h_sync46         ),
    .o_res_data         ( w_res_data46       )
);

wire                            w_h_sync47  ;
wire                            w_v_sync47  ;
wire    [P_DATA_WIDTH-1:0]      w_data47    ;

//延迟输入的结果
delay_line_data #(
    .P_DATA_WIDTH       (P_DATA_WIDTH       ),
    .P_DELAY_TIMES      ( 12               ),
    .P_IMAGE_WIDTH      (P_IMG_WIDTH        )
)
delay_line_data_U7(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_v_sync           ( i_v_sync          ),
    .i_h_sync           ( i_h_sync          ),
    .i_data             ( i_img_data        ),
    .o_h_sync           ( w_h_sync47        ),
    .o_v_sync           ( w_v_sync47        ),
    .o_data             ( w_data47          )
);

wire                            w_v_sync48   ;
wire                            w_h_sync48   ;
wire   [P_OUT_DATA_WIDTH-1:0]   w_res_data48 ;

//减法，原数据减去输入数据，如小于0则取0
dual_image_subtraction #(
    .P_INPUT_DATA_WIDTH (P_OUT_DATA_WIDTH   ),
    .P_IMG_WIDTH        (P_IMG_WIDTH        ),
    .P_IMG_HEIFGHT      (P_IMG_HEIGHT       ),
    .P_OUTPUT_DATA_WIDTH(P_OUT_DATA_WIDTH   )
)
dual_image_subtraction_U3(
    .i_clk              ( i_clk             ),
    .i_rst_n            ( i_rst_n           ),
    .i_h_sync_m         ( w_h_sync16        ),
    .i_v_sync_m         ( w_v_sync16        ),
    .i_data_m           ( w_res_data16      ),
    .i_h_sync_s         ( w_h_sync47        ),
    .i_v_sync_s         ( w_v_sync47        ),
    .i_data_s           ( w_data47          ),
    .o_v_sync           ( w_v_sync48        ),
    .o_h_sync           ( w_h_sync48        ),
    .o_res_data         ( w_res_data48      )
);

//四个尺度在z轴上（纵向叠加）求最大值
find_max_value_on_zaxis_4sacles #(
    .P_DATA_WIDTH       (P_OUT_DATA_WIDTH)
)
find_max_value_on_zaxis_4sacles_U0(
    .i_clk              ( i_clk           ) ,
    .i_rst_n            ( i_rst_n         ) ,
    .i_v_sync_1         (w_v_sync18       ) ,
    .i_h_sync_1         (w_h_sync18       ) ,
    .i_data_1           (w_data18         ) ,
    .i_v_sync_2         (w_v_sync28       ) ,
    .i_h_sync_2         (w_h_sync28       ) ,
    .i_data_2           (w_data28         ) ,
    .i_v_sync_3         (w_v_sync38       ) ,
    .i_h_sync_3         (w_h_sync38       ) ,
    .i_data_3           (w_data38         ) ,
    .i_v_sync_4         (w_v_sync48       ) ,
    .i_h_sync_4         (w_h_sync48       ) ,
    .i_data_4           (w_data48         ) ,
    .o_v_sync           (o_v_sync         ) ,
    .o_h_sync           (o_h_sync         ) ,
    .o_data             (o_img_data       ) 
);

endmodule
