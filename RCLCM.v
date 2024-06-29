`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/07 20:00:16
// Design Name: 
// Module Name: RCLCM
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


module RCLCM
#(
    parameter          P_INPUT_DATA_WIDTH   = 8     ,
    parameter          P_IMAGE_WIDTH        = 256   ,
    parameter          P_IMAGE_HEIGHT       = 256   ,
    parameter          P_OUTPUT_DATA_WIDTH  = 8 
)
(
    input                               i_clk       ,
    input                               i_rst_n     ,
    input                               i_v_sync    ,
    input                               i_h_sync    ,
    input   [P_INPUT_DATA_WIDTH-1:0]    i_img_data  ,

    output                              o_v_sync    ,
    output                              o_h_sync    ,
    output  [P_OUTPUT_DATA_WIDTH-1:0]   o_img_data  
);

wire                                    w_v_sync     ;
wire                                    w_h_sync     ;
wire            [19:0]                  w_mean_value ;

HBF_filter #(
    .P_IMAGE_WIDTH                      (P_IMAGE_WIDTH      ),
    .P_IMAGE_HEIGHT                     (P_IMAGE_HEIGHT     ),
    .P_PIXEL_WIDTH                      (P_INPUT_DATA_WIDTH ),
    .P_OUTPUT_ROWS_NUM                  ( 3                 ),
    .P_ADDR_WIDTH                       ( 11                ),
    .P_EXPEND_NUM                       ( 1                 )
)
HBF_filter_U0(
    .i_clk                              (i_clk              ),
    .i_rst_n                            (i_rst_n            ),
    .i_h_sync                           ( i_h_sync          ),
    .i_v_sync                           ( i_v_sync          ),
    .i_image_data                       ( i_img_data        ),
    .o_v_sync                           ( w_v_sync          ),
    .o_h_sync                           ( w_h_sync          ),
    .o_mean_value                       ( w_mean_value      )
);

wire                                    w_v_sync1    ;
wire                                    w_h_sync1    ;
wire            [31:0]                  w_img_data1  ;

CDLCM #(
    .P_DATA_WIDTH                       ( 20                ),
    .P_IMAGE_WIDTH                      (P_IMAGE_WIDTH      ),
    .P_IMAGE_HEIGHT                     (P_IMAGE_HEIGHT     ),
    .P_OUT_DATA_WIDTH                   ( 32                )
)
CDLCM_U0(
    .i_clk                              ( i_clk             ),
    .i_rst_n                            ( i_rst_n           ),
    .i_v_sync                           ( w_v_sync          ),
    .i_h_sync                           ( w_h_sync          ),
    .i_img_data                         ( w_mean_value      ),
    .o_v_sync                           ( w_v_sync1         ),
    .o_h_sync                           ( w_h_sync1         ),
    .o_img_data                         ( w_img_data1       )
);

wire                                    w_v_sync2    ;
wire                                    w_h_sync2    ;
wire            [31:0]                  w_img_data2  ;

RDLCM #(
    .P_DATA_WIDTH                       (P_INPUT_DATA_WIDTH ),
    .P_IMG_WIDTH                        (P_IMAGE_WIDTH      ),
    .P_IMG_HEIGHT                       (P_IMAGE_HEIGHT     ),
    .P_OUT_DATA_WIDTH                   ( 32                )
)
RDLCM_U0(
    .i_clk                              ( i_clk             ),
    .i_rst_n                            ( i_rst_n           ),
    .i_v_sync                           ( i_v_sync          ),
    .i_h_sync                           ( i_h_sync          ),
    .i_img_data                         ( i_img_data        ),
    .o_v_sync                           ( w_v_sync2         ),
    .o_h_sync                           ( w_h_sync2         ),
    .o_img_data                         ( w_img_data2       )
);

//做点积
dual_image_hadamard_multi #(
    .P_INPUT_DATA_WIDTH                 ( 32                ),
    .P_IMG_WIDTH                        ( P_IMAGE_WIDTH     ),
    .P_IMG_HEIFGHT                      ( P_IMAGE_HEIGHT    ),
    .P_OUTPUT_DATA_WIDTH                (P_OUTPUT_DATA_WIDTH)
)
dual_image_hadamard_multi_U0(
    .i_clk              ( i_clk              ),
    .i_rst_n            ( i_rst_n            ),
    .i_v_sync_a         ( w_v_sync1          ),
    .i_h_sync_a         ( w_h_sync1          ),
    .i_data_a           ( w_img_data1        ),
    .i_v_sync_b         ( w_v_sync2          ),
    .i_h_sync_b         ( w_h_sync2          ),
    .i_data_b           ( w_img_data2        ),
    .o_v_sync           ( o_v_sync           ),
    .o_h_sync           ( o_h_sync           ),
    .o_res_data         ( o_img_data         )
);



endmodule
