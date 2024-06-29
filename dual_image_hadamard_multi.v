`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/20 17:59:05
// Design Name: 
// Module Name: dual_image_hadamard_multi
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


module dual_image_hadamard_multi
#(
    parameter                           P_INPUT_DATA_WIDTH   = 8  ,
    parameter                           P_IMG_WIDTH          = 256,
    parameter                           P_IMG_HEIFGHT        = 256,
    parameter                           P_OUTPUT_DATA_WIDTH  = 32  
)
(
    input                               i_clk       ,
    input                               i_rst_n     ,
    input                               i_h_sync_a  ,
    input                               i_v_sync_a  ,
    input   [P_INPUT_DATA_WIDTH-1:0]    i_data_a    ,
    input                               i_h_sync_b  ,
    input                               i_v_sync_b  ,
    input   [P_INPUT_DATA_WIDTH-1:0]    i_data_b    ,

    output                              o_v_sync    ,
    output                              o_h_sync    ,
    output  [P_OUTPUT_DATA_WIDTH-1:0]   o_res_data  
);

//input register
reg                             ri_h_sync_a ;
reg                             ri_v_sync_a ;
reg [P_INPUT_DATA_WIDTH-1:0]    ri_data_a   ;
reg                             ri_h_sync_b ;
reg                             ri_v_sync_b ;
reg [P_INPUT_DATA_WIDTH-1:0]    ri_data_b   ;

//temp register
wire                            w_valid_v_sync;
wire                            w_valid_h_sync;
wire                            w_valid_h   ;

// wire    [31:0]                  A           ;
// wire    [31:0]                  B           ;
// wire    [31:0]                  P           ;

//output register
reg                             ro_v_sync   ;
reg                             ro_h_sync   ;
reg [P_OUTPUT_DATA_WIDTH-1:0]   ro_res_data ;


assign w_valid_v_sync = ri_v_sync_a && ri_v_sync_b;
assign w_valid_h_sync = ri_h_sync_a && ri_h_sync_b;
assign w_valid_h      = w_valid_h_sync && w_valid_v_sync;

assign o_v_sync   = ro_v_sync;
assign o_h_sync   = ro_h_sync;
assign o_res_data = ro_res_data;

// assign A = w_valid_h ?ri_data_a : 32'd0;
// assign B = w_valid_h ?ri_data_b : 32'd0;

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)begin
        ri_h_sync_a <= 1'd0 ;
        ri_v_sync_a <= 1'd0 ;
        ri_data_a   <= 'd0  ;
        ri_h_sync_b <= 1'd0 ;
        ri_v_sync_b <= 1'd0 ;
        ri_data_b   <= 'd0  ;
    end else begin
        ri_h_sync_a <= i_h_sync_a;
        ri_v_sync_a <= i_v_sync_a;
        ri_data_a   <= i_data_a  ;
        ri_h_sync_b <= i_h_sync_b;
        ri_v_sync_b <= i_v_sync_b;
        ri_data_b   <= i_data_b  ;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_v_sync <= 1'd0;
    else
        ro_v_sync <= w_valid_v_sync;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_h_sync <= 1'd0;
    else if(w_valid_h)
        ro_h_sync <= 1'd1;
    else
        ro_h_sync <= 1'd0;
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n)
        ro_res_data <= 'd0;
    else if(w_valid_h)
        // ro_res_data <= P[P_INPUT_DATA_WIDTH-1:0]; ////可以用LUT实现
        ro_res_data <= ri_data_a * ri_data_b; ////可以用LUT实现
    else
        ro_res_data <= 'd0;
end


// Multiplier_32bit Multiplier_32bit_U0 (
//     .CLK(i_clk),  // input wire CLK
//     .A(A),      // input wire [31 : 0] A
//     .B(B),      // input wire [31 : 0] B
//     .P(P)      // output wire [31 : 0] P
// );

endmodule
