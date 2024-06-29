`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Tinny_G
// 
// Create Date: 2024/06/18 18:11:48
// Design Name: 
// Module Name: find_max_value_on_zaxis_4sacles
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 从输入的
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module find_max_value_on_zaxis_4sacles
#(
    parameter          P_DATA_WIDTH =  32
)
(
    input                       i_clk       ,
    input                       i_rst_n     ,

    input                       i_v_sync_1  ,
    input                       i_h_sync_1  ,
    input   [P_DATA_WIDTH-1:0]  i_data_1    ,
    input                       i_v_sync_2  ,
    input                       i_h_sync_2  ,
    input   [P_DATA_WIDTH-1:0]  i_data_2    ,
    input                       i_v_sync_3  ,
    input                       i_h_sync_3  ,
    input   [P_DATA_WIDTH-1:0]  i_data_3    ,
    input                       i_v_sync_4  ,
    input                       i_h_sync_4  ,
    input   [P_DATA_WIDTH-1:0]  i_data_4    ,

    output                      o_v_sync    ,
    output                      o_h_sync    ,
    output  [P_DATA_WIDTH-1:0]  o_data       

);

//input register
reg                     ri_v_sync_1 ;
reg                     ri_h_sync_1 ;
reg [P_DATA_WIDTH-1:0]  ri_data_1   ;
reg                     ri_v_sync_2 ;
reg                     ri_h_sync_2 ;
reg [P_DATA_WIDTH-1:0]  ri_data_2   ;
reg                     ri_v_sync_3 ;
reg                     ri_h_sync_3 ;
reg [P_DATA_WIDTH-1:0]  ri_data_3   ;
reg                     ri_v_sync_4 ;
reg                     ri_h_sync_4 ;
reg [P_DATA_WIDTH-1:0]  ri_data_4   ;

//output register
reg                     ro_v_sync   ;
reg                     ro_h_sync   ;
reg [P_DATA_WIDTH-1:0]  ro_data     ;

//tmeporary register
wire                    r_v_valid_sync;
wire                    r_h_valid_sync;
wire                    r_h_valid     ;
reg  [P_DATA_WIDTH-1:0] r_temp_data [3:0]   ;

//assign output
assign o_v_sync   = ro_v_sync   ;
assign o_h_sync   = ro_h_sync   ;
assign o_data     = ro_data     ;

assign r_v_valid_sync = ri_v_sync_1 && ri_v_sync_2 && ri_v_sync_3 && ri_v_sync_4;
assign r_h_valid_sync = ri_h_sync_1 && ri_h_sync_2 && ri_h_sync_3 && ri_h_sync_4;
assign r_h_valid      = r_h_valid_sync && r_v_valid_sync;

//input register
always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n) begin
        ri_v_sync_1 <= 1'b0;
        ri_h_sync_1 <= 1'b0;
        ri_data_1   <= 32'b0;
        ri_v_sync_2 <= 1'b0;
        ri_h_sync_2 <= 1'b0;
        ri_data_2   <= 32'b0;
    end else begin
        ri_v_sync_1 <= i_v_sync_1   ;
        ri_h_sync_1 <= i_h_sync_1   ;
        ri_data_1   <= i_data_1     ;
        ri_v_sync_2 <= i_v_sync_2   ;
        ri_h_sync_2 <= i_h_sync_2   ;
        ri_data_2   <= i_data_2     ;
        ri_v_sync_3 <= i_v_sync_3   ;
        ri_h_sync_3 <= i_h_sync_3   ;
        ri_data_3   <= i_data_3     ;
        ri_v_sync_4 <= i_v_sync_4   ;
        ri_h_sync_4 <= i_h_sync_4   ;
        ri_data_4   <= i_data_4     ;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        ro_v_sync <= 1'b0;
    else if(r_v_valid_sync)
        ro_v_sync <= 1'b1;
    else
        ro_v_sync <= 1'b0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(~i_rst_n)
        ro_h_sync <= 1'b0;
    else if(r_h_valid)
        ro_h_sync <= 1'b1;
    else
        ro_h_sync <= 1'b0;
end

integer i;
always @(*) begin
    //intial temp data
    r_temp_data[0] = ri_data_1;
    r_temp_data[1] = ri_data_2;
    r_temp_data[2] = ri_data_3;
    r_temp_data[3] = ri_data_4;
    //Start with the first value as the maximum
    ro_data = r_temp_data[0];
    //Loop through the rest of the values and compare them to the current maximum
    for(i = 0; i < 4; i = i + 1) begin
        if(r_temp_data[i] > ro_data)
            ro_data = r_temp_data[i];
        else
            ro_data = ro_data;
    end
end

endmodule
