`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/09 18:34:11
// Design Name: 
// Module Name: custom_xpm_tdram
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


module custom_xpm_tdram#(
    parameter           P_WRITE_DATA_WIDTH_A = 32 ,
    parameter           P_WRITE_DATA_DEPTH_A = 64 ,
    parameter           P_READ_DATA_WIDTH_A  = 32 ,
    parameter           P_ADDR_WIDTH_A       = 6  ,

    parameter           P_WRITE_DATA_WIDTH_B = 32 ,
    parameter           P_READ_DATA_WIDTH_B  = 32 ,
    parameter           P_ADDR_WIDTH_B       = 6  ,
    
    parameter           P_CLOCKING_MODE = "common_clock" // "independent_clock",or "common_clock"(clka)
)
(
    //port A
    input                                   clka    ,   //parameter CLOCKING_MODE is "common_clock".
    input                                   rsta_n  ,
    input   [P_ADDR_WIDTH_A-1:0]            addra   ,
    input                                   wea     ,
    input   [P_WRITE_DATA_WIDTH_A-1:0]      dina    ,
    //port B
    input                                   clkb    ,
    input                                   rstb_n  ,
    input   [P_ADDR_WIDTH_B-1:0]            addrb   ,
    output  [P_READ_DATA_WIDTH_B-1:0]       doutb   ,
    input                                   enb      
);

localparam  P_MEMORY_SIZE = P_WRITE_DATA_WIDTH_A*P_WRITE_DATA_DEPTH_A;

xpm_memory_tdpram #(
    .ADDR_WIDTH_A               (P_ADDR_WIDTH_A )   ,// DECIMAL
    .ADDR_WIDTH_B               (P_ADDR_WIDTH_B )   ,// DECIMAL
    .AUTO_SLEEP_TIME            (0              )   ,// DECIMAL
    .BYTE_WRITE_WIDTH_A         (P_WRITE_DATA_WIDTH_A)   ,// DECIMAL
    .BYTE_WRITE_WIDTH_B         (P_WRITE_DATA_WIDTH_B)   ,// DECIMAL
    .CLOCKING_MODE              (P_CLOCKING_MODE)   ,// String
    .ECC_MODE                   ("no_ecc"       )   ,// String
    .MEMORY_INIT_FILE           ("none"         )   ,// String
    .MEMORY_INIT_PARAM          ("0"            )   ,// String
    .MEMORY_OPTIMIZATION        ("true"         )   ,// String
    // .MEMORY_PRIMITIVE           ("ultra"        )   ,// String
    .MEMORY_PRIMITIVE           ("block"        )   ,// String
    // .MEMORY_PRIMITIVE           ("auto"         )   ,// String
    .MEMORY_SIZE                (P_MEMORY_SIZE  )   ,// DECIMAL
    .MESSAGE_CONTROL            (0              )   ,// DECIMAL
    .READ_DATA_WIDTH_A          (P_WRITE_DATA_WIDTH_A)   ,// DECIMAL
    .READ_DATA_WIDTH_B          (P_WRITE_DATA_WIDTH_B)   ,// DECIMAL
    .READ_LATENCY_A             (2              )   ,// DECIMAL
    .READ_LATENCY_B             (2              )   ,// DECIMAL
    .READ_RESET_VALUE_A         ("0"            )   ,// String
    .READ_RESET_VALUE_B         ("0"            )   ,// String
    .RST_MODE_A                 ("SYNC"         )   ,// String
    // .RST_MODE_A                 ("ASYNC"        )   ,// String
    .RST_MODE_B                 ("SYNC"         )   ,// String
    .USE_EMBEDDED_CONSTRAINT    (0              )   ,// DECIMAL
    .USE_MEM_INIT               (1              )   ,// DECIMAL
    .WAKEUP_TIME                ("disable_sleep")   ,// String
    .WRITE_DATA_WIDTH_A         (P_WRITE_DATA_WIDTH_A)   ,// DECIMAL
    .WRITE_DATA_WIDTH_B         (P_WRITE_DATA_WIDTH_B)    ,// DECIMAL
    .WRITE_MODE_A               ("no_change"    )   ,// String
    .WRITE_MODE_B               ("no_change"    )    // String
)
xpm_memory_tdpram_inst (
    .dbiterra                   (),
    .dbiterrb                   (),
    .sbiterra                   (),
    .sbiterrb                   (),
    .douta                      (),                   
    .doutb                      (doutb),                   
    .addra                      (addra),
    .addrb                      (addrb),
    .clka                       (clka),
    .clkb                       (clkb),
    .dina                       (dina),
    .dinb                       (8'd0),
    .ena                        (1'b1),
    // .enb                        (1'b1),
    .enb                        (enb),
    .injectdbiterra             (1'b0),
    .injectdbiterrb             (1'b0), 
    .injectsbiterra             (1'b0), 
    .injectsbiterrb             (1'b0),
    .regcea                     (1'b1),
    .regceb                     (1'b1), 
    .rsta                       (!rsta_n),
    .rstb                       (!rstb_n),
    .sleep                      (1'b0),
    .wea                        (wea),
    .web                        (1'b0)
);
endmodule
