`timescale 1ns / 1ps
module oled_main_menu #(
    parameter W   = 96,
    parameter H   = 64,
    parameter BG  = 16'h0000,   // black
    parameter FG  = 16'hFFFF,   // white
    parameter SEL = 16'h07FF    // cyan
)(
    input  wire        clk,
//    input  wire [12:0] pixel_index,   // 0..6143
    input wire [6:0] x, y,
    input  wire [1:0]  sel_index,     // 0..3
    output reg  [15:0] pixel_data
);
    // --- pixel -> x,y ---
//    wire [6:0] x = pixel_index % W;
//    wire [6:0] y = pixel_index / W;

    // --- menu geometry ---
    localparam ITEM_H  = 16;      // vertical spacing per line
    localparam X0      = 8;       // left margin for text
    localparam CELL_W  = 6;       // 5×7 font packed into 6×8 cells
    localparam CELL_H  = 8;
    localparam Y_INSET = 4;       // centre 5×7 within the 16-pixel line

    // which of the four items are we in?
    wire [1:0] item_idx = y / ITEM_H;
    wire in_any_item    = (y < 4*ITEM_H);
    wire is_sel         = (item_idx == sel_index);

    // vertical highlight band (leave 1-pixel margins)
    wire [3:0] y_in_item = y % ITEM_H;
    wire in_highlight = in_any_item && is_sel &&
                        (y_in_item >= 1) && (y_in_item <= ITEM_H-2);

    // --- tiny 5×7 font ---
    function [34:0] glyph_bitmap;
        input [7:0] ch;
        begin
            case (ch)
                "A": glyph_bitmap = 35'b01110_10001_11111_10001_10001_10001_10001;
                "C": glyph_bitmap = 35'b01111_10000_10000_10000_10000_10000_01111;
                "D": glyph_bitmap = 35'b11110_10001_10001_10001_10001_10001_11110;
                "E": glyph_bitmap = 35'b11111_10000_11111_10000_10000_10000_11111;
                "G": glyph_bitmap = 35'b01111_10000_10000_10011_10001_10001_01110;
                "H": glyph_bitmap = 35'b10001_10001_11111_10001_10001_10001_10001;
                "I": glyph_bitmap = 35'b01110_00100_00100_00100_00100_00100_01110;
                "L": glyph_bitmap = 35'b10000_10000_10000_10000_10000_10000_11111;
                "N": glyph_bitmap = 35'b10001_11001_10101_10011_10001_10001_10001;
                "P": glyph_bitmap = 35'b11110_10001_10001_11110_10000_10000_10000;
                "R": glyph_bitmap = 35'b11110_10001_10001_11110_10100_10010_10001;
                "T": glyph_bitmap = 35'b11111_00100_00100_00100_00100_00100_00100;
                "V": glyph_bitmap = 35'b10001_10001_10001_10001_01010_01010_00100;
                "1": glyph_bitmap = 35'b00100_01100_00100_00100_00100_00100_01110;
                "2": glyph_bitmap = 35'b11111_00001_00010_00100_01000_10000_11111;
                "3": glyph_bitmap = 35'b11111_00001_00110_00001_00001_00001_11111;
                "4": glyph_bitmap = 35'b10001_10001_11111_00001_00001_00001_00001;
                ".": glyph_bitmap = 35'b00000_00000_00000_00000_00000_00100_00100;
                " ": glyph_bitmap = 35'b00000_00000_00000_00000_00000_00000_00000;
                default: glyph_bitmap = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction

    function glyph_on;
        input [7:0] ch;
        input [2:0] fx, fy;           // 0..4, 0..6
        reg [34:0] bits;
        integer idx;
        begin
            bits = glyph_bitmap(ch);
            idx  = fy*5 + fx;
            glyph_on = bits[34-idx];
        end
    endfunction

    // character generator for each line
    function [7:0] char_at;
        input [1:0] idx;    // line 0..3
        input [5:0] col;    // character column 0..?
        begin
            case (idx)
                2'd0: begin // "1. CALC"
                    case (col)
                        0: char_at="1"; 1: char_at="."; 3: char_at="C";
                        4: char_at="A"; 5: char_at="L"; 6: char_at="C";
                        default: char_at=" ";
                    endcase
                end
                // 2) "2. GRAPH"
                2'd1: begin
                    case (col)
                        0: char_at = "2";
                        1: char_at = ".";
                        3: char_at = "G";
                        4: char_at = "R";
                        5: char_at = "A";
                        6: char_at = "P";
                        7: char_at = "H";
                        default: char_at = " ";
                    endcase
                end
                
                // 3) "3. DERIVATIVE"
                2'd2: begin
                    case (col)
                        0:  char_at = "3";
                        1:  char_at = ".";
                        3:  char_at = "D";
                        4:  char_at = "E";
                        5:  char_at = "R";
                        6:  char_at = "I";
                        7:  char_at = "V";
                        8:  char_at = "A";
                        9:  char_at = "T";
                        10: char_at = "I";
                        11: char_at = "V";
                        12: char_at = "E";
                        default: char_at = " ";
                    endcase
                end
                
                // 4) "4. INTEGRATE"
                2'd3: begin
                    case (col)
                        0:  char_at = "4";
                        1:  char_at = ".";
                        3:  char_at = "I";
                        4:  char_at = "N";
                        5:  char_at = "T";
                        6:  char_at = "E";
                        7:  char_at = "G";
                        8:  char_at = "R";
                        9:  char_at = "A";
                        10: char_at = "T";
                        11: char_at = "E";
                        default: char_at = " ";
                    endcase
                end

                default: char_at = " ";
            endcase
        end
    endfunction

    // --- text box: from X0 to W-8; characters in 6-pixel cells ---
    wire in_text_box = (x >= X0) && (x < W-8) &&
                       (y_in_item >= Y_INSET) && (y_in_item < Y_INSET + CELL_H);

    // character column and intra-cell coordinates
    wire [5:0] col = (x - X0) / CELL_W;
    wire [2:0] fx  = (x - X0) % CELL_W;       // 0..5
    wire [2:0] fy  = (y_in_item - Y_INSET);   // 0..7

    // only draw inside the 5×7 area
    wire in_font_core = (fx < 5) && (fy < 7);

    // choose the character for this line/column
    reg [7:0] ch;
    always @(*) begin
        if (in_text_box)
            ch = char_at(item_idx, col);
        else
            ch = " ";
    end

    wire pix_txt = in_text_box && in_font_core && glyph_on(ch, fx, fy);

    // final pixel colour
    always @(*) begin
        if (pix_txt)          pixel_data = FG;
        else if (in_highlight)pixel_data = SEL;
        else                  pixel_data = BG;
    end
endmodule
