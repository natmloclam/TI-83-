`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.11.2025 00:29:19
// Design Name: 
// Module Name: calc_integal
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.11.2025 19:03:05
// Design Name: 
// Module Name: Integral_Value_Calculator
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


module calc_integral #(
    parameter APPROX_THIRD = 1  // 1 = use 11/32 approximation, 0 = use exact /3
)(
    input clk,
    input start,
    input signed [15:0] lower_bound,    // scaled by 16
    input signed [15:0] upper_bound,    // scaled by 16
    input signed [15:0] coeff_a,        // x³ coefficient
    input signed [15:0] coeff_b,        // x² coefficient
    input signed [15:0] coeff_c,        // x coefficient
    input signed [15:0] coeff_d,        // constant
    output reg done,
    output reg signed [31:0] integral_result  // scaled by 16
);

    // State machine 
    reg computing;
    
    // ========== Antiderivative Function: F(x) = A·x?/4 + B·x³/3 + C·x²/2 + D·x ==========
    
    function signed [47:0] evaluate_antiderivative;
        input signed [15:0] x;
        input signed [15:0] a, b, c, d;
        reg signed [31:0] x2, x3, x4;
        reg signed [47:0] term_a, term_b, term_c, term_d;
    begin
        // Calculate powers (with proper scaling)
        x2 = (x * x) >>> 4;           // x² (scale: 16)
        x3 = (x2 * x) >>> 4;          // x³ (scale: 16)
        x4 = (x3 * x) >>> 4;          // x? (scale: 16)
        
        // Term A: A·x?/4 = (A·x?) >> 2
        term_a = (a * x4) >>> 2;      // Divide by 4 using shift (exact)
        
        // Term B: B·x³/3
        if (APPROX_THIRD) begin
            // Approximation: 1/3 ? 11/32 (shift by 5, multiply by 11)
            // Error: ~3%, saves division hardware
            term_b = ((b * x3) * 11) >>> 5;
        end else begin
            // Exact division (uses more LUTs)
            term_b = (b * x3) / 3;
        end
        
        // Term C: C·x²/2 = (C·x²) >> 1
        term_c = (c * x2) >>> 1;      // Divide by 2 using shift (exact)
        
        // Term D: D·x (no division)
        term_d = d * x;
        
        // Sum all terms
        evaluate_antiderivative = term_a + term_b + term_c + term_d;
    end
    endfunction
    
    // ========== Main Computation ==========
    
    always @(posedge clk) begin
        if (start && !computing) begin
            computing <= 1;
            done <= 0;
        end 
        else if (computing) begin
            // Evaluate F(upper_bound) - F(lower_bound)
            integral_result <= (evaluate_antiderivative(upper_bound, coeff_a, coeff_b, coeff_c, coeff_d) -
                              evaluate_antiderivative(lower_bound, coeff_a, coeff_b, coeff_c, coeff_d)) >>> 4;
            
            computing <= 0;
            done <= 1;
        end 
        else if (!start) begin
            done <= 0;
        end
    end

endmodule