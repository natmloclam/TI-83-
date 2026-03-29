`timescale 1ns / 1ps
// OLED calc display that ONLY RENDERS given text (no math/formatting here)
module oled_calc_display_text (
    input  wire        clk,                 // 6.25 MHz pixel clock
//    input  wire [12:0] pixel_index,         // 0..6143
    input [6:0] x, y,
    // expression (first row)
    input  wire [7:0]  in_buf0,  input wire [7:0] in_buf1,
    input  wire [7:0]  in_buf2,  input wire [7:0] in_buf3,
    input  wire [7:0]  in_buf4,  input wire [7:0] in_buf5,
    input  wire [7:0]  in_buf6,  input wire [7:0] in_buf7,
    input  wire [7:0]  in_buf8,  input wire [7:0] in_buf9,
    input  wire [7:0]  in_buf10, input wire [7:0] in_buf11,
    input  wire [7:0]  in_buf12, input wire [7:0] in_buf13,
    input  wire [7:0]  in_buf14, input wire [7:0] in_buf15,
    // result text (second row) - already formatted as ASCII
    input  wire [7:0]  res0,  input wire [7:0] res1,
    input  wire [7:0]  res2,  input wire [7:0] res3,
    input  wire [7:0]  res4,  input wire [7:0] res5,
    input  wire [7:0]  res6,  input wire [7:0] res7,
    input  wire [7:0]  res8,  input wire [7:0] res9,
    input  wire [7:0]  res10, input wire [7:0] res11,
    input  wire [7:0]  res12, input wire [7:0] res13,
    input  wire [7:0]  res14, input wire [7:0] res15,
    input  wire        show_result,         // 1 -> draw result line
    output reg  [15:0] pixel_data
);
    // coords
//    wire [6:0] x  = pixel_index % 96;
//    wire [6:0] y  = pixel_index / 96;
    wire [3:0] col = x / 6;
    wire [2:0] cx  = x % 6;
    wire top_row   = (y < 8);
    wire bot_row   = (y >= 16 && y < 24);
    wire [6:0] y_minus_16 = y - 7'd16;
    wire [2:0] ry         = top_row ? y[2:0] : y_minus_16[2:0];


    // line buffers
    reg [7:0] expr [0:15];
    reg [7:0] rest [0:15];
    always @* begin
        expr[0]=in_buf0;   expr[1]=in_buf1;   expr[2]=in_buf2;   expr[3]=in_buf3;
        expr[4]=in_buf4;   expr[5]=in_buf5;   expr[6]=in_buf6;   expr[7]=in_buf7;
        expr[8]=in_buf8;   expr[9]=in_buf9;   expr[10]=in_buf10; expr[11]=in_buf11;
        expr[12]=in_buf12; expr[13]=in_buf13; expr[14]=in_buf14; expr[15]=in_buf15;

        rest[0]=res0;  rest[1]=res1;  rest[2]=res2;  rest[3]=res3;
        rest[4]=res4;  rest[5]=res5;  rest[6]=res6;  rest[7]=res7;
        rest[8]=res8;  rest[9]=res9;  rest[10]=res10;rest[11]=res11;
        rest[12]=res12;rest[13]=res13;rest[14]=res14;rest[15]=res15;
    end

    // ASCII -> glyph id
    function [4:0] gid;
        input [7:0] c;
        begin
            case (c)
                " " : gid = 5'd0;
                "0" : gid = 5'd1;
                "1" : gid = 5'd2;
                "2" : gid = 5'd3;
                "3" : gid = 5'd4;
                "4" : gid = 5'd5;
                "5" : gid = 5'd6;
                "6" : gid = 5'd7;
                "7" : gid = 5'd8;
                "8" : gid = 5'd9;
                "9" : gid = 5'd10;
                "+" : gid = 5'd11;
                "-" : gid = 5'd12;
                "*" : gid = 5'd13;
                "/" : gid = 5'd14;
                "^" : gid = 5'd15;
                "=" : gid = 5'd16;
                "B" : gid = 5'd17;
                "C" : gid = 5'd18;
                "." : gid = 5'd19;
                default: gid = 5'd0;
            endcase
        end
    endfunction

    // 5×7 font ROM (BRAM)
    (* rom_style="block" *) reg [4:0] font [0:(20*8)-1];
    task automatic F; input integer g,r; input [4:0] b; begin font[(g<<3)+r]=b; end endtask
    integer i;
    initial begin
        for (i=0;i<20*8;i=i+1) font[i]=5'b0;
        // 0..9, + - * / ^ = B C .
        F(1,0,5'b01110);F(1,1,5'b10001);F(1,2,5'b10011);F(1,3,5'b10101);F(1,4,5'b11001);F(1,5,5'b10001);F(1,6,5'b01110);
        F(2,0,5'b00100);F(2,1,5'b01100);F(2,2,5'b00100);F(2,3,5'b00100);F(2,4,5'b00100);F(2,5,5'b00100);F(2,6,5'b01110);
        F(3,0,5'b11110);F(3,1,5'b00001);F(3,2,5'b00010);F(3,3,5'b01100);F(3,4,5'b10000);F(3,5,5'b10000);F(3,6,5'b11111);
        F(4,0,5'b11110);F(4,1,5'b00001);F(4,2,5'b00110);F(4,3,5'b00001);F(4,4,5'b00001);F(4,5,5'b00001);F(4,6,5'b11110);
        F(5,0,5'b00010);F(5,1,5'b00110);F(5,2,5'b01010);F(5,3,5'b11111);F(5,4,5'b00010);F(5,5,5'b00010);F(5,6,5'b00010);
        F(6,0,5'b11111);F(6,1,5'b10000);F(6,2,5'b11110);F(6,3,5'b00001);F(6,4,5'b00001);F(6,5,5'b00001);F(6,6,5'b11110);
        F(7,0,5'b01110);F(7,1,5'b10000);F(7,2,5'b11110);F(7,3,5'b10001);F(7,4,5'b10001);F(7,5,5'b10001);F(7,6,5'b01110);
        F(8,0,5'b11111);F(8,1,5'b00010);F(8,2,5'b00100);F(8,3,5'b01000);F(8,4,5'b01000);F(8,5,5'b01000);F(8,6,5'b01000);
        F(9,0,5'b01110);F(9,1,5'b10001);F(9,2,5'b01110);F(9,3,5'b10001);F(9,4,5'b10001);F(9,5,5'b10001);F(9,6,5'b01110);
        F(10,0,5'b01110);F(10,1,5'b10001);F(10,2,5'b10001);F(10,3,5'b01111);F(10,4,5'b00001);F(10,5,5'b00010);F(10,6,5'b01100);
        F(11,0,5'b00100);F(11,1,5'b00100);F(11,2,5'b11111);F(11,3,5'b00100);F(11,4,5'b00100);
        F(12,2,5'b11111);
        F(13,0,5'b00100);F(13,1,5'b10101);F(13,2,5'b01110);F(13,3,5'b10101);F(13,4,5'b00100);
        F(14,0,5'b00001);F(14,1,5'b00010);F(14,2,5'b00100);F(14,3,5'b01000);F(14,4,5'b10000);
        F(15,0,5'b00100);F(15,1,5'b01010);F(15,2,5'b10001);
        F(16,0,5'b11111);F(16,2,5'b11111);
        F(17,0,5'b11110);F(17,1,5'b10001);F(17,2,5'b11110);F(17,3,5'b10001);F(17,4,5'b11110);
        F(18,0,5'b01110);F(18,1,5'b10000);F(18,2,5'b10000);F(18,3,5'b10000);F(18,4,5'b01110);
        F(19,5,5'b00100);F(19,6,5'b00100);
    end

    wire [7:0] ch = top_row ? expr[col] : (bot_row && show_result ? rest[col] : " ");
    wire [4:0] bits = font[{gid(ch), ry}];

    reg draw;
    always @* begin
        draw = 1'b0;
        if (cx < 5) draw = bits[4 - cx];
    end
    always @(posedge clk)
        pixel_data <= draw ? 16'hFFFF : 16'h0000;
endmodule
