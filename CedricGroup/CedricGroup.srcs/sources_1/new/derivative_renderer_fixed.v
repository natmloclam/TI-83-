`timescale 1ns / 1ps

// Clean derivative renderer - no duplicate drivers
module derivative_renderer_fixed(
    input clk,
//    input [12:0] pixel_index,
    input [6:0] pixel_x, input [5:0] pixel_y,
    input signed [15:0] x_offset,
    input signed [15:0] y_offset,
    input [2:0] zoom_level,
    input signed [15:0] tangent_x0,
    input signed [15:0] tangent_y0,
    input signed [15:0] tangent_slope,
    input tangent_active,
    input cursor_visible,
    
    input signed [15:0] coef_a,
    input signed [15:0] coef_b,
    input signed [15:0] coef_c,
    input signed [15:0] coef_d,
    
    output reg [15:0] pixel_color
);

    // Pixel coordinates
//    wire [6:0] pixel_x = pixel_index % 96;
//    wire [5:0] pixel_y = pixel_index / 96;

    // Graph coordinates
    wire signed [15:0] graph_x = ((pixel_x - 48) <<< zoom_level) + x_offset;
    wire signed [15:0] graph_y = ((32 - pixel_y) <<< zoom_level) + y_offset;

    // ========== Function and Derivative Calculation ==========
    localparam SCALE = 4;
    
    // Compute x^2 and x^3 ONCE
    wire signed [31:0] x_squared = (graph_x * graph_x) >>> SCALE;
    wire signed [31:0] x_cubed = (x_squared * graph_x) >>> SCALE;
    
    // Original function: f(x) = ax³ + bx² + cx + d
    wire signed [31:0] func_a_term = (coef_a * x_cubed) >>> SCALE;
    wire signed [31:0] func_b_term = (coef_b * x_squared) >>> SCALE;
    wire signed [31:0] func_c_term = (coef_c * graph_x) >>> SCALE;
    wire signed [31:0] func_d_term = coef_d;
    
    wire signed [31:0] func_sum = func_a_term + func_b_term + func_c_term + func_d_term;
    wire signed [15:0] func_y = func_sum[15:0];
    
    // Derivative: f'(x) = 3ax² + 2bx + c
    wire signed [31:0] deriv_3a = coef_a + (coef_a <<< 1);  // 3a = a + 2a
    wire signed [31:0] deriv_2b = coef_b <<< 1;              // 2b
    
    wire signed [31:0] deriv_a_term = (deriv_3a * x_squared) >>> SCALE;
    wire signed [31:0] deriv_b_term = (deriv_2b * graph_x) >>> SCALE;
    wire signed [31:0] deriv_c_term = coef_c;
    
    wire signed [31:0] deriv_sum = deriv_a_term + deriv_b_term + deriv_c_term;
    wire signed [15:0] deriv_y = deriv_sum[15:0];

    // Convert to pixel coordinates
    wire signed [31:0] func_offset = func_y - y_offset;
    wire signed [31:0] deriv_offset = deriv_y - y_offset;
    
    wire signed [15:0] func_pixel_y = 32 - (func_offset >>> zoom_level);
    wire signed [15:0] deriv_pixel_y = 32 - (deriv_offset >>> zoom_level);

    // ========== Tangent Line ==========
    wire signed [31:0] tangent_dx = graph_x - tangent_x0;
    wire signed [63:0] tangent_rise_raw = tangent_slope * tangent_dx;
    wire signed [31:0] tangent_rise = tangent_rise_raw >>> 4;
    wire signed [31:0] tangent_y_val = tangent_y0 + tangent_rise;
    wire signed [31:0] tangent_offset = tangent_y_val - y_offset;
    wire signed [15:0] tangent_pixel_y = 32 - (tangent_offset >>> zoom_level);

    // ========== Line Detection ==========
    localparam LINE_THICK = 2;

    // On-screen checks
    wire func_visible = (func_pixel_y >= 0) && (func_pixel_y < 64);
    wire deriv_visible = (deriv_pixel_y >= 0) && (deriv_pixel_y < 64);
    wire tangent_visible = (tangent_pixel_y >= 0) && (tangent_pixel_y < 64);

    // Previous y values for interpolation
    reg signed [15:0] prev_func_y = 0;
    reg signed [15:0] prev_deriv_y = 0;
    reg signed [15:0] prev_tangent_y = 0;

    always @(posedge clk) begin
        prev_func_y <= func_pixel_y;
        prev_deriv_y <= deriv_pixel_y;
        prev_tangent_y <= tangent_pixel_y;
    end

    // Determine if pixel is on each curve
    wire signed [15:0] func_y_min = (func_pixel_y < prev_func_y) ? func_pixel_y : prev_func_y;
    wire signed [15:0] func_y_max = (func_pixel_y > prev_func_y) ? func_pixel_y : prev_func_y;
    wire on_func = func_visible && 
                   (pixel_y >= (func_y_min - LINE_THICK)) && 
                   (pixel_y <= (func_y_max + LINE_THICK));

    wire signed [15:0] deriv_y_min = (deriv_pixel_y < prev_deriv_y) ? deriv_pixel_y : prev_deriv_y;
    wire signed [15:0] deriv_y_max = (deriv_pixel_y > prev_deriv_y) ? deriv_pixel_y : prev_deriv_y;
    wire on_deriv = deriv_visible && 
                    (pixel_y >= (deriv_y_min - LINE_THICK)) && 
                    (pixel_y <= (deriv_y_max + LINE_THICK));

    wire signed [15:0] tangent_y_min = (tangent_pixel_y < prev_tangent_y) ? tangent_pixel_y : prev_tangent_y;
    wire signed [15:0] tangent_y_max = (tangent_pixel_y > prev_tangent_y) ? tangent_pixel_y : prev_tangent_y;
    wire on_tangent = tangent_active && tangent_visible &&
                      (pixel_y >= (tangent_y_min - LINE_THICK)) && 
                      (pixel_y <= (tangent_y_max + LINE_THICK));

    // ========== Axes ==========
    wire signed [15:0] x_axis_pos = 32 + (y_offset >>> zoom_level);
    wire signed [15:0] y_axis_pos = 48 - (x_offset >>> zoom_level);
    
    wire on_x_axis = (pixel_y == x_axis_pos) || (pixel_y == x_axis_pos + 1);
    wire on_y_axis = (pixel_x == y_axis_pos) || (pixel_x == y_axis_pos + 1);

    // Grid lines
    wire on_grid = ((graph_x & 16'h000F) == 0) || ((graph_y & 16'h000F) == 0);

    // ========== Cursor Dot ==========
    wire signed [31:0] cursor_dx = graph_x - tangent_x0;
    wire signed [31:0] cursor_dy = graph_y - tangent_y0;
    wire signed [31:0] cursor_dist_sq = cursor_dx * cursor_dx + cursor_dy * cursor_dy;
    wire [31:0] cursor_threshold = 16 <<< (zoom_level <<< 1);
    wire on_cursor = tangent_active && cursor_visible && (cursor_dist_sq <= cursor_threshold);

    // ========== Colors (RGB565) ==========
    localparam COLOR_BLACK     = 16'h0000;
    localparam COLOR_BLUE      = 16'h001F;
    localparam COLOR_RED       = 16'hF800;
    localparam COLOR_WHITE     = 16'hFFFF;
    localparam COLOR_DARK_GRAY = 16'h39E7;
    localparam COLOR_ORANGE    = 16'hFD20;
    localparam COLOR_YELLOW    = 16'hFFE0;

    // ========== Render Priority ==========
    always @(*) begin
        if (on_cursor)
            pixel_color = COLOR_YELLOW;
        else if (on_x_axis || on_y_axis)
            pixel_color = COLOR_WHITE;
        else if (on_tangent)
            pixel_color = COLOR_RED;
        else if (on_deriv)
            pixel_color = COLOR_ORANGE;
        else if (on_func)
            pixel_color = COLOR_BLUE;
        else if (on_grid)
            pixel_color = COLOR_DARK_GRAY;
        else
            pixel_color = COLOR_BLACK;
    end

endmodule