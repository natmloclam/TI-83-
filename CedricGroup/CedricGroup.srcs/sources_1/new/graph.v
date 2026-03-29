`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.10.2025 09:49:13
// Design Name: 
// Module Name: graph
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


module graph(input clk, 
             input signed [15:0] x, y, a, b , c, d, 
             input signed [15:0] scale,
             input show_line_left, show_line_right, // used for max/min
             input signed [15:0] x_left, x_right, 
             input find_enable, enable_integral, on_cursor,
             output reg [15:0] oled_data);
             
    parameter WHITE =   16'hFFFF;
    parameter BLACK =   16'h0000;
    parameter GREEN =   16'h07E0;
    parameter RED =     16'hF800;
    parameter BLUE =    16'h001F;
    parameter GRAY =    16'h39E7;
    parameter ORANGE =  16'hFC00;
    parameter CYAN =    16'h07FF;

    
    wire signed [15:0] VERT_TOL = (scale <= 2) ? 1 : 2;
    
    // graph equation
    wire signed [15:0] TOLERANCE = scale * 2;
    wire signed [31:0] y_func;
    compute_function unit_comp(.x(x), .a(a), .b(b), .c(c), .d(d), .y_func(y_func));
    
    
    // draw axis ticks 
    wire signed [15:0] x_shifted;
    wire signed [15:0] y_shifted;
    
    assign x_shifted = x - (x % scale);
    assign y_shifted = y - (y % scale);

    wire tick_on;
    axis_ticks unit_axis(.x(x_shifted), .y(y_shifted), .scale(scale), .tick_on(tick_on));
    
    
      
    always @(posedge clk)
    begin
        // MAX/MIN FN
        if ((show_line_left && (x >= x_left - VERT_TOL && x <= x_left + VERT_TOL)) ||
                 (show_line_right && (x >= x_right - VERT_TOL && x <= x_right + VERT_TOL)))
            oled_data <= RED;

        // CURSOR
        else if (on_cursor) oled_data <= (find_enable) ? RED : ORANGE; 
        
        // INTEGRAL
        else if (enable_integral && (x >= x_left && x <= x_right) && 
                ((y >= 0 && y <= y_func) || y <= 0 && y >= y_func)) 
            oled_data <= CYAN;
            
        // GRAPH 
        else if ((y - y_func < TOLERANCE) && (y - y_func > -TOLERANCE)) oled_data <= BLUE;  
                       
        // AXES 
        else if (x_shifted == 0 || y_shifted == 0) oled_data <= WHITE; 
        
        // TICKS -> GRIDS 
        else if (tick_on == 1) oled_data <= GRAY;
        
        // BACKGROUND
        else oled_data <= BLACK;
    end 
endmodule
