`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/12 17:13:32
// Design Name: 
// Module Name: greater_than_mean_num_mean
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


module greater_than_mean_num_mean
#(
    parameter          P_DATA_WIDTH             = 20    ,
    parameter          P_SCALE_SIZE             = 3     ,
    parameter          P_OUTPUT_DATA_WIDTH      = 32    ,
    parameter          P_MASK_SIZE              = 3     //P_SLIDE_WINDOW = P_SCALE_SIZE*P_MASK_SIZE
)
(
    input                                                       i_clk            ,
    input                                                       i_rst_n          ,
    input                                                       i_v_sync         ,
    input                                                       i_h_sync         ,
    input   [P_DATA_WIDTH*P_SCALE_SIZE*P_SCALE_SIZE*P_SCALE_SIZE*P_SCALE_SIZE-1:0]    i_data           ,

    output                                                      o_h_sync         ,
    output                                                      o_v_sync         ,
    output          [P_OUTPUT_DATA_WIDTH-1:0]                   o_data            
);

//滑窗大小
localparam         P_SLIDE_WINDOW           = P_SCALE_SIZE*P_MASK_SIZE ;
//input registers
reg                                                     ri_v_sync   ;
reg                                                     ri_v_sync_1d;
reg                                                     ri_v_sync_2d;
reg                                                     ri_v_sync_3d;
reg                                                     ri_v_sync_4d;
reg                                                     ri_h_sync   ;
reg [P_DATA_WIDTH*P_SLIDE_WINDOW*P_SLIDE_WINDOW-1:0]    ri_data     ;
reg                                                     ri_h_sync_1d;
reg                                                     ri_h_sync_2d;
reg                                                     ri_h_sync_3d;
reg                                                     ri_h_sync_4d;
reg [P_DATA_WIDTH*P_SLIDE_WINDOW*P_SLIDE_WINDOW-1:0]    ri_data_1d  ;
reg [P_DATA_WIDTH*P_SLIDE_WINDOW*P_SLIDE_WINDOW-1:0]    ri_data_2d  ;

//output registers
reg                                                     ro_h_sync   ;
reg                                                     ro_v_sync   ;
reg [P_OUTPUT_DATA_WIDTH-1:0]                           ro_data     ;

//temporary registers
reg [P_OUTPUT_DATA_WIDTH-1:0]       r_masks_means    [P_MASK_SIZE*P_MASK_SIZE-1:0];
wire [P_OUTPUT_DATA_WIDTH*(P_MASK_SIZE*P_MASK_SIZE-1)-1:0] w_r_masks_means_flatten; //展平,

assign o_h_sync = ro_h_sync ;
assign o_v_sync = ro_v_sync ;
assign o_data   = ro_data   ;

always @(posedge i_clk or negedge i_rst_n)begin
    if(~i_rst_n)begin
        ri_h_sync <= 1'd0;
        ri_v_sync <= 1'd0;
        ri_data   <=  'd0;
    end else begin
        ri_h_sync <= i_h_sync;
        ri_v_sync <= i_v_sync;
        ri_data   <= i_data  ;
    end
end

//delay registers
always @(posedge i_clk or negedge i_rst_n)begin
    if(~i_rst_n)begin
        ri_h_sync_1d <= 1'd0;
        ri_h_sync_2d <= 1'd0;
        ri_h_sync_3d <= 1'd0;
        ri_h_sync_4d <= 1'd0;
        ri_data_1d   <=  'd0;
        ri_data_2d   <=  'd0;
        ri_v_sync_1d <= 1'd0;
        ri_v_sync_2d <= 1'd0;
        ri_v_sync_3d <= 1'd0;
        ri_v_sync_4d <= 1'd0;
    end else begin
        ri_h_sync_1d <= ri_h_sync   ;
        ri_h_sync_2d <= ri_h_sync_1d;
        ri_h_sync_3d <= ri_h_sync_2d;
        ri_h_sync_4d <= ri_h_sync_3d;
        ri_data_1d   <= ri_data     ;
        ri_data_2d   <= ri_data_1d  ;
        ri_v_sync_1d <= ri_v_sync   ;
        ri_v_sync_2d <= ri_v_sync_1d   ;
        ri_v_sync_3d <= ri_v_sync_2d   ;
        ri_v_sync_4d <= ri_v_sync_3d   ;
    end
end

//求九个分块的平均值
genvar i,j;
generate
    for(i=0;i<P_MASK_SIZE;i=i+1) begin : loop_masks_means
        for(j=0;j<P_MASK_SIZE;j=j+1) begin : loop_masks_means_inner
            always @(posedge i_clk or negedge i_rst_n)
                if(~i_rst_n)
                    r_masks_means [i*P_MASK_SIZE+j] <=  'd0;
                else
                    r_masks_means [i*P_MASK_SIZE+j] <=  ((ri_data[(i*P_SLIDE_WINDOW+j*P_MASK_SIZE+i)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[(i*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+1)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[(i*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+2)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+1)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+1)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+1)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+1)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+2)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+2)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i)*P_DATA_WIDTH +:P_DATA_WIDTH] +
                                                          ri_data[((i+2)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+1)*P_DATA_WIDTH +:P_DATA_WIDTH] + 
                                                          ri_data[((i+2)*P_SLIDE_WINDOW+j*P_MASK_SIZE+i+2)*P_DATA_WIDTH +:P_DATA_WIDTH]
                                                          )*227)>>12;
        end
    end
endgenerate


wire [P_OUTPUT_DATA_WIDTH-1:0]      w_max_mean          ; //周围八个分块的最大平均值
wire [7:0]                          w_max_mean_index    ; //最大平均值所在的索引
wire [P_OUTPUT_DATA_WIDTH-1:0]      w_center_mean       ; //中心分块的平均值
wire [7:0]                          w_center_mean_index ; //中心分块的索引
reg  [P_OUTPUT_DATA_WIDTH-1:0]      r_max_mean_1d       ;
reg  [P_OUTPUT_DATA_WIDTH-1:0]      r_max_mean_2d       ;
reg  [P_OUTPUT_DATA_WIDTH-1:0]      r_max_mean_3d       ;
reg  [P_OUTPUT_DATA_WIDTH-1:0]      w_center_mean_1d    ;
reg  [P_OUTPUT_DATA_WIDTH-1:0]      w_center_mean_2d    ;
reg  [P_OUTPUT_DATA_WIDTH-1:0]      w_center_mean_3d    ;

wire [P_OUTPUT_DATA_WIDTH-1:0]      w_max_value         ; //周围八个数的最大值
wire [$clog2(P_MASK_SIZE*P_MASK_SIZE-1)-1:0]   w_max_index        ; //最大值所在的索引]w_max_index
wire                                w_valid             ; //是否有有效数据;

assign w_center_mean_index = 4;
assign w_center_mean = r_masks_means[4];

assign w_max_mean = w_valid ? w_max_value :  'd0;
assign w_max_mean_index = w_valid ? (w_max_index>4?w_max_index+1:w_max_index):'d0;

generate
    for (i=0;i<P_MASK_SIZE*P_MASK_SIZE;i=i+1) begin : loop_max_mean //绕过中心最大值
        if(i < 4) begin
            assign w_r_masks_means_flatten[i*P_OUTPUT_DATA_WIDTH +:P_OUTPUT_DATA_WIDTH] = r_masks_means[i];
        end else if(i>4)
            assign w_r_masks_means_flatten[(i-1)*P_OUTPUT_DATA_WIDTH +:P_OUTPUT_DATA_WIDTH] = r_masks_means[i];
    end
endgenerate

find_max_value #(
    .P_DATA_WIDTH ( P_OUTPUT_DATA_WIDTH ),
    .P_DATA_NUM   ( P_MASK_SIZE*P_MASK_SIZE-1)
)u_find_max_value(
    .i_clk        ( i_clk        ),
    .i_rst_n      ( i_rst_n      ),
    .i_data       ( w_r_masks_means_flatten ),
    .i_valid      ( ri_h_sync_1d ),
    .o_valid      ( w_valid      ),
    .o_max_value  ( w_max_value  ),
    .o_max_index  ( w_max_index  )
);


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        r_max_mean_1d    <=  'd0;
        r_max_mean_2d    <=  'd0;
        r_max_mean_3d    <=  'd0;
        w_center_mean_1d <=  'd0;
        w_center_mean_2d <=  'd0;
        w_center_mean_3d <=  'd0;
    end else begin
        r_max_mean_1d <= w_max_mean;
        r_max_mean_2d <= r_max_mean_1d;
        r_max_mean_3d <= r_max_mean_2d;
        w_center_mean_1d <= w_center_mean;
        w_center_mean_2d <= w_center_mean_1d;
        w_center_mean_3d <= w_center_mean_2d;
    end
end

//求周围分块大于均值所在块的数的均值
reg [P_OUTPUT_DATA_WIDTH-1:0] r_greater_mean_num_sum ; //大于均值的数的和
reg [31:0]                    r_greater_mean_num_num ; //大于均值的数的个数,注意个数如果为0，要赋值为1
reg [P_OUTPUT_DATA_WIDTH-1:0] r_greater_mean_num_mean; //大于均值的数的均值


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_greater_mean_num_sum <=  'd0;
    else if(ri_h_sync_2d)begin:iner
        integer i, j;
        for (i = 0; i < P_SCALE_SIZE; i = i + 1) begin
            for (j = 0; j < P_SCALE_SIZE; j = j + 1) begin
                if (ri_data_2d[(w_max_index-1)*P_SCALE_SIZE*P_SCALE_SIZE*P_DATA_WIDTH + (i*P_SCALE_SIZE+j)*P_DATA_WIDTH +: P_DATA_WIDTH] > w_max_mean) begin
                    r_greater_mean_num_sum <= r_greater_mean_num_sum + ri_data_2d[(w_max_index-1)*P_SCALE_SIZE*P_SCALE_SIZE*P_DATA_WIDTH + (i*P_SCALE_SIZE+j)*P_DATA_WIDTH +: P_DATA_WIDTH];
                end
            end
        end
    end
    else
        r_greater_mean_num_sum <=  'd0;
end
/*--------------------------------*/

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_greater_mean_num_num <=  32'd0;
    else if(ri_h_sync_2d)begin:inner
        integer i, j;
        for (i = 0; i < P_SCALE_SIZE; i = i + 1) begin
            for (j = 0; j < P_SCALE_SIZE; j = j + 1) begin
                if (ri_data_2d[(w_max_index-1)*P_SCALE_SIZE*P_SCALE_SIZE*P_DATA_WIDTH + (i*P_SCALE_SIZE+j)*P_DATA_WIDTH +: P_DATA_WIDTH] > w_max_mean) begin
                    r_greater_mean_num_num <= r_greater_mean_num_num + 1;
                end
            end
        end
    end else
        r_greater_mean_num_num <=  32'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_greater_mean_num_mean <=  'd0;
    else if(ri_h_sync_2d && r_greater_mean_num_num!= 32'd0)
        r_greater_mean_num_mean <= r_greater_mean_num_sum/r_greater_mean_num_num;
    else if(ri_h_sync_2d && r_greater_mean_num_num == 32'd0)
        r_greater_mean_num_mean <=  r_greater_mean_num_sum;
    else
        r_greater_mean_num_mean <=  'd0;
end
//求出中心分块大于均值的数的均值
reg [P_OUTPUT_DATA_WIDTH-1:0] r_greatew_center_mean_num_sum ; //中心分块大于均值的数的和
reg [31:0]                    r_greatew_center_mean_num_num ; //中心分块大于均值的数的个数,注意个数如果为0，要赋值为1
reg [P_OUTPUT_DATA_WIDTH-1:0] r_greatew_center_mean_num_mean; //中心分块大于均值的数的均值

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_greatew_center_mean_num_sum <=  'd0;
    else if(ri_h_sync_1d)
        r_greatew_center_mean_num_sum <= ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+0*P_MASK_SIZE+0)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+0*P_MASK_SIZE+0)*P_DATA_WIDTH +:P_DATA_WIDTH]:1'd0 +
                                         ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+0*P_MASK_SIZE+1)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+0*P_MASK_SIZE+1)*P_DATA_WIDTH +:P_DATA_WIDTH]:1'd0 +
                                         ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+0*P_MASK_SIZE+2)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+0*P_MASK_SIZE+2)*P_DATA_WIDTH +:P_DATA_WIDTH]:1'd0 +
                                         ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+1*P_MASK_SIZE+0)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+1*P_MASK_SIZE+0)*P_DATA_WIDTH +:P_DATA_WIDTH]:1'd0 +
                                         ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+1*P_MASK_SIZE+1)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+1*P_MASK_SIZE+1)*P_DATA_WIDTH +:P_DATA_WIDTH]:1'd0 +
                                         ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+1*P_MASK_SIZE+2)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+1*P_MASK_SIZE+2)*P_DATA_WIDTH +:P_DATA_WIDTH]:1'd0 +
                                         ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+2*P_MASK_SIZE+0)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+2*P_MASK_SIZE+0)*P_DATA_WIDTH +:P_DATA_WIDTH]:1'd0 +
                                         ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+2*P_MASK_SIZE+1)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+2*P_MASK_SIZE+1)*P_DATA_WIDTH +:P_DATA_WIDTH]:1'd0 +
                                         ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+2*P_MASK_SIZE+2)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+2*P_MASK_SIZE+2)*P_DATA_WIDTH +:P_DATA_WIDTH]:1'd0 ;
    else
        r_greatew_center_mean_num_sum <=  'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_greatew_center_mean_num_num <=  32'd0;
    else if(ri_h_sync_1d)
        r_greatew_center_mean_num_num <=   ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+0*P_MASK_SIZE+0)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? 1'd1:1'd0+
                                           ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+0*P_MASK_SIZE+1)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? 1'd1:1'd0+
                                           ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+0*P_MASK_SIZE+2)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? 1'd1:1'd0+
                                           ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+1*P_MASK_SIZE+0)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? 1'd1:1'd0+
                                           ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+1*P_MASK_SIZE+1)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? 1'd1:1'd0+
                                           ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+1*P_MASK_SIZE+2)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? 1'd1:1'd0+
                                           ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+2*P_MASK_SIZE+0)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? 1'd1:1'd0+
                                           ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+2*P_MASK_SIZE+1)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? 1'd1:1'd0+
                                           ri_data_1d[((w_center_mean_index-1)*P_MASK_SIZE*P_MASK_SIZE+2*P_MASK_SIZE+2)*P_DATA_WIDTH +:P_DATA_WIDTH]>w_max_mean? 1'd1:1'd0;
    else
        r_greatew_center_mean_num_num <=  32'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_greatew_center_mean_num_mean <=  'd0;
    else if(ri_h_sync_2d && r_greater_mean_num_num!= 0)
        r_greatew_center_mean_num_mean <= r_greater_mean_num_sum/r_greater_mean_num_num; //除法最好能优化一下
    else if(ri_h_sync_2d && r_greater_mean_num_num == 0)
        r_greatew_center_mean_num_mean <= r_greater_mean_num_sum;
    else
        r_greatew_center_mean_num_mean <=  'd0;
end

reg   [P_OUTPUT_DATA_WIDTH-1:0]     r_MD    ;
reg   [P_OUTPUT_DATA_WIDTH-1:0]     r_DD    ;

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_MD    <=  'd0;
    else if(ri_h_sync_3d)
        r_MD   <= (r_greatew_center_mean_num_mean-w_center_mean_3d)-(r_greater_mean_num_mean-r_max_mean_3d);
    else
        r_MD    <=  'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        r_DD    <=  'd0;
    else if(ri_h_sync_3d)
        r_DD   <= w_center_mean_3d - r_max_mean_3d;
    else
        r_DD    <=  'd0;
end


always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_data    <=  'd0;
    else if(ri_h_sync_4d )
        ro_data   <= (r_MD >0 && r_DD >0)?r_MD*r_DD:1'd0;
    else
        ro_data    <=  'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_sync    <=  'd0;
    else if(ri_h_sync_4d )
        ro_h_sync   <= 1'd1;
    else
        ro_h_sync    <=  'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_v_sync   <=  'd0;
    else if(ri_v_sync_4d )
        ro_v_sync   <= 1'd1;
    else
        ro_v_sync   <=  'd0;
end

endmodule
