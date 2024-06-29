`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/06/15 14:04:21
// Design Name: 
// Module Name: find_max_value
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 输入多个数据，求最大值
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module find_max_value #(
    parameter P_DATA_WIDTH = 8,
    parameter P_DATA_NUM   = 8
)
(
    input                                   i_clk       ,
    input                                   i_rst_n     ,
    input  [P_DATA_WIDTH*P_DATA_NUM-1:0]    i_data      ,
    input                                   i_valid     ,
    output reg                              o_valid     ,
    output reg [P_DATA_WIDTH-1:0]           o_max_value ,
    output reg [$clog2(P_DATA_NUM)-1:0]     o_max_index   // 输出最大值的索引
);

// Intermediate variables
integer i;
reg [P_DATA_WIDTH-1:0] current_value;
reg [P_DATA_WIDTH-1:0] max_value;
reg [$clog2(P_DATA_NUM)-1:0] max_index;  // 存储最大值的索引

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_valid <= 1'b0;
        o_max_value <= 'd0;
        o_max_index <= 'd0;
    end else if (i_valid) begin
        // Initialize max_value to the first element and max_index to 0
        max_value = i_data[P_DATA_WIDTH-1:0];
        max_index = 0;
        // Iterate over the data and find the maximum value and its index
        for (i = 1; i < P_DATA_NUM; i = i + 1) begin
            current_value = i_data[i*P_DATA_WIDTH +: P_DATA_WIDTH];
            if (current_value > max_value) begin
                max_value = current_value;
                max_index = i[$clog2(P_DATA_NUM)-1:0];
            end
        end
        o_max_value <= max_value;
        o_max_index <= max_index;
        o_valid <= 1'b1;
    end else begin
        o_valid <= 1'b0;
    end
end

endmodule
