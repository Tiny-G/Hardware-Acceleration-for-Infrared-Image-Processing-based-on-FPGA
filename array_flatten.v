`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/06/15 17:15:12
// Design Name: 
// Module Name: array_flatten
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 因为verilog不能直接传递二维数组，所以这种写法只能用systemverilog来实现，

// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// module array_flatten
// #(
//     parameter P_DATA_WIDTH = 8,
//     parameter P_DATA_NUM   = 8
// )
// (
//     input  [P_DATA_WIDTH-1:0] i_data_array [P_DATA_NUM-1:0], 
//     output [P_DATA_WIDTH*P_DATA_NUM-1:0] o_array_flat
// );

//     integer i;
//     always @(*) begin
//         for (i = 0; i < P_DATA_NUM; i = i + 1) begin
//             o_array_flat[i*P_DATA_WIDTH +: P_DATA_WIDTH] = i_data_array[i];
//         end
//     end
// endmodule

// 如果要用verilog来写的话，使用生成式代码直接实现，参考代码如下：
// reg [P_OUTPUT_DATA_WIDTH-1:0]       r_masks_means    [P_SLIDE_WINDOW-1:0];
// wire [P_OUTPUT_DATA_WIDTH*P_SLIDE_WINDOW-1:0] w_r_masks_means_flatten; //展平
// generate
//     for (i=0;i<P_SLIDE_WINDOW;i=i+1) begin : loop_max_mean 
//         assign w_r_masks_means_flatten[i*P_OUTPUT_DATA_WIDTH +:P_OUTPUT_DATA_WIDTH] = r_masks_means[i];
//     end
// endgenerate