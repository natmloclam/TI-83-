`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2025 12:45:36
// Design Name: 
// Module Name: cursor
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


module cursor(input clk, mode, btnL, btnR, btnU, btnD, pan_toggle,
    input signed [15:0] x, y,
    input signed [15:0] cursor_y,
    input [15:0] x_max, input max_done,
    input [15:0] x_min, input min_done,
    output reg signed [15:0] cursor_x = 0,
    output on_cursor);

    parameter signed [15:0] STEP = 2;
    parameter CURSOR_TOL = 3;
    parameter GRAPH = 1;
    
    reg [19:0] counter = 0;
    wire tick = (counter == 20'd999_999);
    
    always @(posedge clk) begin
        counter <= counter + 1;
        if (max_done) cursor_x <= x_max;
        else if (min_done) cursor_x <= x_min;
        else if (mode == GRAPH && pan_toggle == 0 && tick) begin
            if (btnL) cursor_x <= cursor_x - STEP;
            else if (btnR) cursor_x <= cursor_x + STEP;
        end
    end
    
    assign on_cursor = (
        (
            (x - cursor_x <  CURSOR_TOL) && (x - cursor_x > -CURSOR_TOL) &&
            (y - cursor_y < (CURSOR_TOL << 1)) && (y - cursor_y > -(CURSOR_TOL << 1))
        )
        ||
        (
            (y - cursor_y <  CURSOR_TOL) && (y - cursor_y > -CURSOR_TOL) &&
            (x - cursor_x < (CURSOR_TOL << 1)) && (x - cursor_x > -(CURSOR_TOL << 1))
        )
    );

    
endmodule

