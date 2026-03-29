`timescale 1ns / 1ps

module graph_inputs(
    input clk,
    input [31:0] buffer,
    input [4:0] sw,
    output reg mode = 0,  // MENU
    output reg [31:0] a = 0, b = 0, c = 0, d = 0
);
    // Parameters defined INSIDE module
    localparam MENU = 0;
    localparam GRAPH = 1;
    
    always @(posedge clk) begin 
        mode <= (sw[0]) ? GRAPH : MENU;
        
        if (mode == MENU) begin
            if      (sw[1]) d <= buffer; 
            else if (sw[2]) c <= buffer;
            else if (sw[3]) b <= buffer; 
            else if (sw[4]) a <= buffer;
        end        
    end
endmodule