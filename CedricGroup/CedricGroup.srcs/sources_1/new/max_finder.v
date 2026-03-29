`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2025 12:51:55
// Design Name: 
// Module Name: max_finder
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


module max_finder(
    input clk,
    input signed [15:0] a, b, c, d,
    input signed [15:0] x_left, x_right,
    input find_enable,
    output reg signed [15:0] x_max = 0,
    output reg signed [31:0] y_max = -32768, // use larger bit width for y
    output reg done = 0
);

    reg signed [15:0] x_curr = 0;
    wire signed [31:0] y_curr;
    
    compute_function func_inst (.x(x_curr), .a(a), .b(b), .c(c), .d(d), .y_func(y_curr));

    localparam IDLE = 2'd0;
    localparam SCAN = 2'd1;
    localparam DONE = 2'd2;
    
    reg [1:0] state = IDLE;
    
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                done <= 0;
                if (find_enable && (x_left < x_right)) begin
                    x_curr <= x_left;
                    y_max <= -32768;
                    x_max <= x_left;
                    state <= SCAN;
                end
            end

            SCAN: begin
                if (x_curr <= x_right) begin
                    if (y_curr > y_max) begin
                        y_max <= y_curr;
                        x_max <= x_curr;
                    end
                    x_curr <= x_curr + 1; // increment scan step
                end else begin
                    state <= DONE;
                    done <= 1;
                end
            end

            DONE: begin
                if (!find_enable) state <= IDLE;
            end
        endcase
    end
endmodule