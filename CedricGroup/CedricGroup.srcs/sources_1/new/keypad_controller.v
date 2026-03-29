`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.11.2025 01:49:10
// Design Name: 
// Module Name: keypad_controller
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


module keypad_controller(
    input  wire       clk_200hz,
    input  wire       u_re, d_re, l_re, r_re, c_re,
    input  wire [2:0] mode,          
    input  wire graph_mode,
    output reg  [2:0] cur_row = 0,
    output reg  [2:0] cur_col = 0,
    output wire  [7:0] key_pressed
);
    
    localparam MODE_MENU = 3'd0,
               MODE_CALC = 3'd1,
               MODE_GRAPH = 3'd2,
               MODE_DERIVATIVE = 3'd3,
               MODE_INTEGRATE = 3'd4;
               
    // can add for other modes
    wire keypad_active = ((mode == MODE_CALC ) || (mode == MODE_GRAPH && !graph_mode)
                          || (mode == MODE_INTEGRATE && !graph_mode) || mode == MODE_DERIVATIVE);
    
    // Key mapping function
    function [7:0] key_at;
        input [2:0] r, c;
        begin
            case ({r,c})
                {3'd0,3'd0}: key_at = "7"; {3'd0,3'd1}: key_at = "8"; {3'd0,3'd2}: key_at = "9"; {3'd0,3'd3}: key_at = "/"; {3'd0,3'd4}: key_at = "B";
                {3'd1,3'd0}: key_at = "4"; {3'd1,3'd1}: key_at = "5"; {3'd1,3'd2}: key_at = "6"; {3'd1,3'd3}: key_at = "*"; {3'd1,3'd4}: key_at = "C";
                {3'd2,3'd0}: key_at = "1"; {3'd2,3'd1}: key_at = "2"; {3'd2,3'd2}: key_at = "3"; {3'd2,3'd3}: key_at = "-"; {3'd2,3'd4}: key_at = "^";
                {3'd3,3'd0}: key_at = "0"; {3'd3,3'd1}: key_at = "X"; {3'd3,3'd2}: key_at = "Y"; {3'd3,3'd3}: key_at = "+"; {3'd3,3'd4}: key_at = "=";
                default: key_at = 8'h20;
            endcase
        end
    endfunction

    always @(posedge clk_200hz) begin
        if (keypad_active) begin
            if (u_re)      cur_row <= (cur_row == 0) ? 3 : cur_row - 1;
            else if (d_re) cur_row <= (cur_row == 3) ? 0 : cur_row + 1;
            else if (l_re) cur_col <= (cur_col == 0) ? 4 : cur_col - 1;
            else if (r_re) cur_col <= (cur_col == 4) ? 0 : cur_col + 1;
        end
        else 
        begin
            cur_row <= 0;
            cur_col <= 0;
        end
    end
    
    assign key_pressed = keypad_active ? key_at(cur_row, cur_col) : 8'h20;
endmodule
