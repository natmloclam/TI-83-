`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2025 19:56:57
// Design Name: 
// Module Name: seq_calc
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


module seq_calc (
    input  wire        clk,
    input  wire        start,
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [7:0]  op_in,      // '+','-','*','/','^'
    output reg  [31:0] result,
    output reg         busy,
    output reg         done
);

    localparam IDLE  = 3'd0,
               MUL   = 3'd1,
               DIV   = 3'd2,
               POW   = 3'd3,
               DONE  = 3'd4;

    reg [2:0] state;
    reg [31:0] reg_a, reg_b, acc;
    reg [4:0] pow_cnt; // supports exponent up to 31

    always @(posedge clk) begin
        case(state)
            IDLE: begin
                done <= 1'b0;
                busy <= 1'b0;
                if(start) begin
                    reg_a <= a_in;
                    reg_b <= b_in;
                    acc   <= 0;
                    pow_cnt <= 0;
                    busy <= 1'b1;
                    case(op_in)
                        "+", "-": begin
                            result <= (op_in == "+") ? a_in + b_in : a_in - b_in;
                            state <= DONE;
                        end
                        "*": state <= MUL;
                        "/": state <= DIV;
                        "^": begin
                            acc <= 1;
                            state <= POW;
                        end
                        default: begin
                            result <= a_in;
                            state <= DONE;
                        end
                    endcase
                end
            end

            MUL: begin
                if(reg_b != 0) begin
                    acc <= acc + reg_a;   // sequential multiply
                    reg_b <= reg_b - 1;
                end else begin
                    result <= acc;
                    state <= DONE;
                end
            end

            DIV: begin
                if(reg_b == 0) begin
                    result <= 0; // divide by zero
                    state <= DONE;
                end else if(reg_a >= reg_b) begin
                    reg_a <= reg_a - reg_b;
                    acc <= acc + 1;
                end else begin
                    result <= acc;
                    state <= DONE;
                end
            end

            POW: begin
                if(pow_cnt < reg_b) begin
                    acc <= acc * reg_a;
                    pow_cnt <= pow_cnt + 1;
                end else begin
                    result <= acc;
                    state <= DONE;
                end
            end

            DONE: begin
                busy <= 1'b0;
                done <= 1'b1;
                state <= IDLE;
            end

            default: state <= IDLE;
        endcase
    end
endmodule
