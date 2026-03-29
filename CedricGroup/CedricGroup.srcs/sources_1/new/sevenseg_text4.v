// Basys3 7-seg driver (active-LOW segments & anodes), ~1 kHz per digit
module sevenseg_text4 (
    input  wire       clk,                   // 100 MHz
    input  wire [7:0] text3, text2, text1, text0,
    output reg  [6:0] seg,                   // {a,b,c,d,e,f,g} active-LOW
    output reg  [3:0] an                     // an[3:0] active-LOW
);
    // -------- slow refresh (~1 kHz per digit) --------
    // 100e6 / 4000 ? 25 kHz scan ? each of 4 digits ? 6.25 kHz ; nice and stable
    reg [15:0] div = 0;
    reg [1:0]  mux = 0;
    always @(posedge clk) begin
        div <= div + 16'd1;
        if (div == 16'd39999) begin
            div <= 16'd0;
            mux <= mux + 2'd1;
        end
    end

    // -------- glyphs: active-LOW (0 = segment ON) --------
    function [6:0] glyph;
        input [7:0] ch;
        begin
            case (ch)
                "0": glyph = 7'b1000000;
                "1": glyph = 7'b1111001;
                "2": glyph = 7'b0100100;
                "3": glyph = 7'b0110000;
                "4": glyph = 7'b0011001;
                "5": glyph = 7'b0010010;
                "6": glyph = 7'b0000010;
                "7": glyph = 7'b1111000;
                "8": glyph = 7'b0000000;
                "9": glyph = 7'b0010000;
                "A": glyph = 7'b0001000;
                "C": glyph = 7'b1000110;
                "E": glyph = 7'b0000110;
                "L": glyph = 7'b1000111;
                "-": glyph = 7'b0111111;
                default: glyph = 7'b1111111; // blank
            endcase
        end
    endfunction

    // -------- multiplex one digit at a time (active-LOW anodes) --------
    always @(posedge clk) if (div == 16'd39999) begin
        case (mux)
            2'd0: begin an <= 4'b1110; seg <= glyph(text0); end // rightmost
            2'd1: begin an <= 4'b1101; seg <= glyph(text1); end
            2'd2: begin an <= 4'b1011; seg <= glyph(text2); end
            2'd3: begin an <= 4'b0111; seg <= glyph(text3); end // leftmost
        endcase
    end
endmodule
