`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.11.2025 16:25:39
// Design Name: 
// Module Name: oled_result_seq
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


module oled_result_seq(
    input  wire        clk,
    input  wire [31:0] result_val,     // signed integer
    input  wire        show_result,
    output reg [127:0] res_txt_flat    // 16 ASCII chars flattened (MSB = char0)
);

    integer i;
    integer pos;
    reg [31:0] abs_val;
    reg [3:0] digits [0:9];  // up to 10 digits for 32-bit int
    reg [3:0] nd;
    reg [7:0] bytes [0:15];  // temporary byte array, bytes[0] -> first char on left

    // initialize/clear
    initial begin
        for (i = 0; i < 16; i = i + 1) bytes[i] = 8'h20;
        res_txt_flat = {16{8'h20}};
    end

    always @(posedge clk) begin
        // default: blank all bytes
        for (i = 0; i < 16; i = i + 1) bytes[i] = 8'h20;

        if (show_result) begin
            // Compute absolute value (signed)
            abs_val = result_val[31] ? -result_val : result_val;

            // convert to decimal digits LSB-first into digits[]
            for (i = 0; i < 10; i = i + 1) digits[i] = 4'd0;
            nd = 4'd0;
            if (abs_val == 0) begin
                digits[0] = 0;
                nd = 1;
            end else begin
                while (abs_val != 0 && nd < 10) begin
                    digits[nd] = abs_val % 10;
                    abs_val = abs_val / 10;
                    nd = nd + 1;
                end
            end

            // Build left-to-right text: "= ", optional sign, then digits MSB->LSB
            pos = 0;
            if (pos < 16) begin bytes[pos] = "="; pos = pos + 1; end
            if (pos < 16) begin bytes[pos] = " "; pos = pos + 1; end

            if (result_val[31]) begin
                if (pos < 16) begin bytes[pos] = "-"; pos = pos + 1; end
            end else begin
                if (pos < 16) begin bytes[pos] = " "; pos = pos + 1; end
            end

            // place digits MSB -> LSB
            for (i = 0; i < nd && pos < 16; i = i + 1) begin
                bytes[pos] = "0" + digits[nd-1-i];
                pos = pos + 1;
            end
        end

        // pack bytes[] into res_txt_flat MSB-first so Top_Cedric's unpack works:
        // bytes[0] -> res_txt_flat[127:120], bytes[1] -> [119:112], ... bytes[15] -> [7:0]
        for (i = 0; i < 16; i = i + 1) begin
            res_txt_flat[(127 - i*8) -: 8] <= bytes[i];
        end
    end
endmodule
