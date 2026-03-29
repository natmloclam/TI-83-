`timescale 1ns / 1ps

// Function evaluator that computes both f(x) and f'(x)
// For polynomial: f(x) = ax³ + bx² + cx + d
// Derivative: f'(x) = 3ax² + 2bx + c
module function_evaluator(
    input clk,
    input signed [15:0] x_coord,
    input signed [15:0] coef_a,
    input signed [15:0] coef_b,
    input signed [15:0] coef_c,
    input signed [15:0] coef_d,
    output signed [15:0] y_original,
    output signed [15:0] y_derivative
);
    // Fixed-point scaling factor (matches your graph scaling)
    localparam FUNC_SCALE = 4;  // Shift amount for fixed-point arithmetic
    
    // ========== Compute f(x) = ax³ + bx² + cx + d ==========
    wire signed [31:0] x_squared = (x_coord * x_coord) >>> FUNC_SCALE;
    wire signed [31:0] x_cubed = (x_squared * x_coord) >>> FUNC_SCALE;
    
    wire signed [31:0] term_a = (coef_a * x_cubed) >>> FUNC_SCALE;
    wire signed [31:0] term_b = (coef_b * x_squared) >>> FUNC_SCALE;
    wire signed [31:0] term_c = (coef_c * x_coord) >>> FUNC_SCALE;
    wire signed [31:0] term_d = coef_d;
    
    wire signed [31:0] y_func = term_a + term_b + term_c + term_d;
    assign y_original = y_func[15:0];
    
    // ========== Compute f'(x) = 3ax² + 2bx + c ==========
    // 3a term
    wire signed [31:0] coef_3a = (coef_a <<< 1) + coef_a;  // 3*a
    wire signed [31:0] deriv_term_a = (coef_3a * x_squared) >>> FUNC_SCALE;
    
    // 2b term
    wire signed [31:0] coef_2b = coef_b <<< 1;  // 2*b
    wire signed [31:0] deriv_term_b = (coef_2b * x_coord) >>> FUNC_SCALE;
    
    // c term (constant in derivative)
    wire signed [31:0] deriv_term_c = coef_c;
    
    wire signed [31:0] y_deriv = deriv_term_a + deriv_term_b + deriv_term_c;
    assign y_derivative = y_deriv[15:0];

endmodule