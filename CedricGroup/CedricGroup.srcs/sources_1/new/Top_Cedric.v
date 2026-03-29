`timescale 1ns / 1ps


module Top_Cedric (
    input  wire        CLK_100MHZ,
    input  wire        clk_6p25mhz,
    input  wire        BTNU, BTND, BTNL, BTNR, BTNC,
    input  wire [15:0]  SW,
    input  wire [12:0] pixel_index_left,
    input  wire [12:0] pixel_index_right,
    output wire [15:0] pixel_data_left,
    output wire [15:0] pixel_data_right,
    output wire [15:0] LED,
    output wire [6:0]  SEG,
    output wire [3:0]  AN
);

    // COORDINATES
    wire [6:0] x_left; wire [5:0] y_left;
    // can use alt_coordinates to u
    alt_coordinates coord_left(.pixel_index(pixel_index_left), .x(x_left), .y(y_left));


    // ----------------------
    // Clocks
    // ----------------------
    wire clk_200hz;
    wire clk_10hz;

    clock_divider_generic #(.DIV(250_000)) div200hz (
        .clk_in (CLK_100MHZ),
        .clk_out(clk_200hz)
    );

    clock_divider_generic #(.DIV(10_000_000)) div10hz (
        .clk_in (CLK_100MHZ),
        .clk_out(clk_10hz)
    );

    // ----------------------
    // Button edge detect (one-shot)
    // ----------------------
    reg u_s, d_s, l_s, r_s, c_s;
    reg u_z, d_z, l_z, r_z, c_z;
    reg u_re, d_re, l_re, r_re, c_re;

    always @(posedge clk_200hz) begin
        u_s <= BTNU; d_s <= BTND; l_s <= BTNL; r_s <= BTNR; c_s <= BTNC;

        u_re <=  u_s & ~u_z;
        d_re <=  d_s & ~d_z;
        l_re <=  l_s & ~l_z;
        r_re <=  r_s & ~r_z;
        c_re <=  c_s & ~c_z;

        u_z <= u_s; d_z <= d_s; l_z <= l_s; r_z <= r_s; c_z <= c_s;
    end

    // ----------------------
    // Modes
    // ----------------------
    localparam MODE_MENU = 3'd0,
               MODE_CALC = 3'd1,
               MODE_GRAPH = 3'd2,
               MODE_DERIVATIVE = 3'd3,
               MODE_INTEGRATE = 3'd4;

    reg [2:0] mode = MODE_MENU;
    reg [1:0] menu_index = 2'd0;

    // ----------------------
    // Cursor + Calculator State
    // ----------------------
    wire [2:0] cur_row;
    wire [2:0] cur_col;
    reg [7:0]  in_buf [0:31];
    reg [5:0]  in_len = 6'd0;
    reg [31:0] result_val = 32'd0;
    reg        have_result = 1'b0;
    reg        busy = 1'b0;
    reg [7:0]  sel_key;
    reg        res_has_frac   = 1'b0;
    reg [3:0]  res_frac_digit = 4'd0;
    
    reg [3:0] graph_input_digit = 4'd0;
    reg       graph_input_neg   = 1'b0;
    wire graph_mode;
    
    // -------- Derivative mode state --------
    reg signed [15:0] deriv_cursor_x = 16'sd0;
    reg signed [15:0] x_offset_diff = 16'sd0;
    reg signed [15:0] y_offset_diff = 16'sd0;
    reg [2:0]         zoom_diff     = 3'd2;
    
    // -------- Screen state --------
    reg [3:0]  compute_wait = 4'd0;
    integer i;

    // ----------------------
    // Helper tasks
    // ----------------------
    task clear_input;
        begin
            for (i=0; i<32; i=i+1) in_buf[i] <= 8'h20;
            in_len <= 6'd0;
        end
    endtask

    initial begin
        clear_input();
    end

    // ----------------------
    // Keypad character map
    // ----------------------

    wire [7:0] cur_key;
    
    keypad_controller kc (
            .clk_200hz(clk_200hz),
            .u_re(u_re), .d_re(d_re), .l_re(l_re), .r_re(r_re), .c_re(c_re),
            .mode(mode),
            .graph_mode(graph_mode),
            .cur_row(cur_row),
            .cur_col(cur_col),
            .key_pressed(cur_key)
        );
    
    // ===================================================================
    // SINGLE UNIFIED CONTROL BLOCK - All button/switch logic here
    // This prevents multiple drivers
    // ===================================================================
    always @(posedge clk_200hz) begin
        case (mode)
            // ============================ MODE MENU ============================ //
            MODE_MENU : begin
                if (u_re) menu_index <= menu_index - 1;
                else if (d_re) menu_index <= menu_index + 1;
                
                if (c_re) begin
                    case (menu_index)
                        0 : mode <= MODE_CALC;
                        1 : mode <= MODE_GRAPH;
                        2 : mode <= MODE_DERIVATIVE;
                        3 : mode <= MODE_INTEGRATE;
                        default : mode <= MODE_MENU;
                    endcase
                end
            end

            // ============================ MODE CALC ============================ //
            MODE_CALC: begin
                if (c_re && !SW[0]) begin
                    sel_key <= cur_key;
                    case (cur_key)
                        "C" : begin
                            clear_input();
                            have_result <= 1'b0;
                        end
                        "B" : begin
                            mode        <= MODE_MENU;
                            clear_input();
                            have_result <= 1'b0;
                            busy        <= 1'b0;
                        end
                        "=" : begin
                            busy        <= 1'b1;
                            have_result <= 1'b0;
                            compute_wait <= 8;
                        end
                        default: if (in_len < 32 && cur_key != 8'h20) begin
                            in_buf[in_len] <= cur_key;
                            in_len <= in_len + 1;
                            have_result <= 1'b0;
                        end
                    endcase
                end

                if (c_re && SW[0]) begin
                    mode <= MODE_MENU;
                    in_len <= 0;
                end
            end

            // ============================ MODE GRAPH =========================== //
            MODE_GRAPH: begin 
                if (!graph_mode && c_re) begin
                    case (cur_key)
                        "0","1","2","3","4","5","6","7","8","9": begin
                            graph_input_digit <= cur_key - "0";
                        end 
                        "-" : graph_input_neg <= 1'b1;
                        "+" : graph_input_neg <= 1'b0;
                        "C" : begin
                            graph_input_digit <= 4'd0;
                            graph_input_neg   <= 1'b0; 
                        end
                        "B" : begin 
                            mode <= MODE_MENU;
                        end
                    endcase
                end
            end
            
            // ============================ MODE DERIVATIVE =========================== //
            MODE_DERIVATIVE: begin
                
                // SW[0] = 0: Cursor navigation
                // SW[0] = 1: Pan/zoom mode
                if (!SW[0]) begin
                    // CURSOR MODE
                    if (l_re) deriv_cursor_x <= deriv_cursor_x - 16'sd2;
                    else if (r_re) deriv_cursor_x <= deriv_cursor_x + 16'sd2;
                end else begin
                    // PAN/ZOOM MODE
                    if (l_re) x_offset_diff <= x_offset_diff - (16'sd4 <<< zoom_diff);
                    else if (r_re) x_offset_diff <= x_offset_diff + (16'sd4 <<< zoom_diff);
                    else if (u_re) y_offset_diff <= y_offset_diff + (16'sd4 <<< zoom_diff);
                    else if (d_re) y_offset_diff <= y_offset_diff - (16'sd4 <<< zoom_diff);
                    
                    // Zoom with center button
                    if (c_re) begin
                        if (SW[1]) begin
                            // Zoom in
                            if (zoom_diff > 3'd0) zoom_diff <= zoom_diff - 3'd1;
                        end else begin
                            // Zoom out
                            if (zoom_diff < 3'd6) zoom_diff <= zoom_diff + 3'd1;
                        end
                    end
                end
                
                // Keypad controls (work in both modes)
                if (c_re) begin
                    case (cur_key)
                        "B": begin
                            mode <= MODE_MENU;
                            deriv_cursor_x <= 16'sd0;
                            x_offset_diff <= 16'sd0;
                            y_offset_diff <= 16'sd0;
                            zoom_diff <= 3'd2;
                        end
                        "C": begin
                            // Reset everything
                            deriv_cursor_x <= 16'sd0;
                            x_offset_diff <= 16'sd0;
                            y_offset_diff <= 16'sd0;
                            zoom_diff <= 3'd2;
                        end
                        default: begin end
                    endcase
                end
            end
            MODE_INTEGRATE : begin
                if (!graph_mode && c_re) begin
                    case (cur_key)
                        "0","1","2","3","4","5","6","7","8","9": begin
                            graph_input_digit <= cur_key - "0";  // store single digit
                        end 
                                    
                        "-" : graph_input_neg <= 1'b1; // negative
                        "+" : graph_input_neg <= 1'b0;
                        "C" : begin
                            graph_input_digit <= 4'd0;
                            graph_input_neg <= 1'b0; 
                        end
                                    
                        "B" : mode <= MODE_MENU;
                    endcase
                end                  
            end
            default: begin end
        endcase

        // ========= compute complete - leave this here ========= //
        if (busy) begin
            if (compute_wait != 4'd0)
                compute_wait <= compute_wait - 4'd1;
            else begin
                busy <= 1'b0;
                eval_expr();
                have_result <= 1'b1;
            end
        end
    end
// ============================================================================================//


    // ----------------------
    // LED indicator
    // ----------------------
    wire [15:0] led_calc, led_gp;
    assign LED = (mode == MODE_CALC) ? led_calc :
                 (mode == MODE_GRAPH) ? led_gp : 
                 16'b1111111111111111;
    
    reg [3:0] led_pos = 4'd0;
    always @(posedge clk_10hz) begin
        if (busy) led_pos <= (led_pos == 4'd15) ? 4'd0 : (led_pos + 4'd1);
        else      led_pos <= 4'd0;
    end
    assign led_calc = busy ? (16'h0001 << led_pos) : 16'h0000;

    // ----------------------
    // 7-Segment
    // ----------------------
    wire [6:0] seg_calc, seg_gp, seg_deriv; 
    wire [3:0] an_calc, an_gp, an_deriv; 
    assign SEG = (mode == MODE_CALC) ? seg_calc :
                 (mode == MODE_GRAPH || mode == MODE_INTEGRATE) ? seg_gp :
                 (mode == MODE_DERIVATIVE) ? seg_deriv :
                 7'b1111111;
    assign AN = (mode == MODE_CALC) ? an_calc : 
                (mode == MODE_GRAPH || mode == MODE_INTEGRATE) ? an_gp :
                (mode == MODE_DERIVATIVE) ? an_deriv :
                4'b1111;
    
    sevenseg_text4 segdisp (
        .clk  (CLK_100MHZ),
        .text3("C"), .text2("A"), .text1("L"), .text0("C"),
        .seg(seg_calc),
        .an(an_calc)
    );

    // ----------------------
    // OLED Displays
    // ----------------------
    wire [15:0] jc_menu_px;
    wire [15:0] jc_calc_px;
    wire [15:0] jc_deriv_px;

    oled_main_menu jc_menu (
        .clk(clk_6p25mhz),
//        .pixel_index(pixel_index_left),
        .x(x_left), .y(y_left),
        .sel_index(menu_index),
        .pixel_data(jc_menu_px)
    );

    // ============================= GRAPH =================================
    wire [15:0] jc_graph_px;
    wire signed [31:0] graph_input_int = graph_input_neg ? -graph_input_digit : graph_input_digit;
    
    wire signed [15:0] x_offset_graph, y_offset_graph;
    wire [2:0] zoom_graph;

    wire [15:0] a_raw, b_raw, c_raw, d_raw;

    Top_Student jc_graph (
        .basys_clock(CLK_100MHZ), .clk_6p25m(clk_6p25mhz),
        .btnL(BTNL), .btnR(BTNR), .btnU(BTNU), .btnD(BTND), .btnC(BTNC),
        .sw(SW), .x_raw(x_left), .y_raw(y_left), .buffer(graph_input_int), .graph_mode(graph_mode),
        .oled_data(jc_graph_px), .an(an_gp), .seg(seg_gp), .led(led_gp), 
        // derivative outputs
        .a_val_out(a_raw), .b_val_out(b_raw), .c_val_out(c_raw), .d_val_out(d_raw),
        // integral inputs
        .enable_integral(mode == MODE_INTEGRATE)
    );

    // ---------------------- BCD/Result text pipeline ----------------------
    wire [127:0] res_txt_flat;
    wire [7:0]   res_txt [0:15];

    genvar k;
    generate
        for (k = 0; k < 16; k = k + 1) begin : unpack_loop
            assign res_txt[k] = res_txt_flat[(127 - k*8) -: 8];
        end
    endgenerate

    oled_result_seq u_res_seq (
        .clk(clk_6p25mhz),
        .result_val(result_val),
        .show_result(have_result),
        .res_txt_flat(res_txt_flat)
    );

    oled_calc_display_text jc_calc ( 
        .clk(clk_6p25mhz),
        .x(x_left), .y(y_left),
        .in_buf0(in_buf[0]),  .in_buf1(in_buf[1]),  .in_buf2(in_buf[2]),  .in_buf3(in_buf[3]),
        .in_buf4(in_buf[4]),  .in_buf5(in_buf[5]),  .in_buf6(in_buf[6]),  .in_buf7(in_buf[7]),
        .in_buf8(in_buf[8]),  .in_buf9(in_buf[9]),  .in_buf10(in_buf[10]),.in_buf11(in_buf[11]),
        .in_buf12(in_buf[12]),.in_buf13(in_buf[13]),.in_buf14(in_buf[14]),.in_buf15(in_buf[15]),
        .res0(res_txt[0]),  .res1(res_txt[1]),  .res2(res_txt[2]),  .res3(res_txt[3]),
        .res4(res_txt[4]),  .res5(res_txt[5]),  .res6(res_txt[6]),  .res7(res_txt[7]),
        .res8(res_txt[8]),  .res9(res_txt[9]),  .res10(res_txt[10]),.res11(res_txt[11]),
        .res12(res_txt[12]),.res13(res_txt[13]),.res14(res_txt[14]),.res15(res_txt[15]),
        .show_result(have_result),
        .pixel_data(jc_calc_px)
    );

    wire bcd_busy, bcd_done;
    wire [39:0] bcd_bus;
    reg  bcd_start;
    wire [31:0] abs_res = result_val[31] ? (~result_val + 1) : result_val;

    reg have_result_q;
    always @(posedge CLK_100MHZ)
        have_result_q <= have_result;
    
    wire kick_bcd = (have_result && !have_result_q);

    localparam BCD_IDLE  = 2'd0,
               BCD_START = 2'd1,
               BCD_WAIT  = 2'd2;
    
    reg [1:0] bcd_state;
    
    always @(posedge CLK_100MHZ) begin
        case (bcd_state)
            BCD_IDLE: begin
                bcd_start <= 1'b0;
                if (kick_bcd) bcd_state <= BCD_START;
            end
            BCD_START: begin
                bcd_start <= 1'b1;
                bcd_state <= BCD_WAIT;
            end
            BCD_WAIT: begin
                bcd_start <= 1'b0;
                if (bcd_done) bcd_state <= BCD_IDLE;
            end
            default: begin
                bcd_state <= BCD_IDLE;
                bcd_start <= 1'b0;
            end
        endcase
    end
    
    bin32_to_bcd10 u_b2b (
        .clk(CLK_100MHZ), .start(bcd_start), .bin(abs_res),
        .busy(bcd_busy), .done(bcd_done), .bcd(bcd_bus)
    );

    // Final left OLED mux
    assign pixel_data_left =
        (mode == MODE_MENU)       ? jc_menu_px  :
        (mode == MODE_CALC)       ? jc_calc_px  :
        (mode == MODE_GRAPH || mode == MODE_INTEGRATE) ? jc_graph_px :
        (mode == MODE_DERIVATIVE) ? jc_deriv_px :
                                    16'h0000;

    // Right OLED: keypad UI
    oled_keypad_ui right_d (
        .clk(clk_6p25mhz),
        .pixel_index(pixel_index_right),
        .cur_row(cur_row),
        .cur_col(cur_col),
        .pixel_data(pixel_data_right)
    );

    // ----------------------
    // Calculator core
    // ----------------------
//    task eval_expr; 
//        integer j;
//        integer a, b;
//        reg [7:0] op;
//        integer p, acc;
//        localparam integer MAX_POW = 16;
//    begin
//        res_has_frac   <= 1'b0;
//        res_frac_digit <= 4'd0;
    
//        a = 0; b = 0; op = 8'h00;
//        for (j = 0; j < 32; j = j + 1) begin
//            if (j < in_len) begin
//                if (in_buf[j] >= "0" && in_buf[j] <= "9") begin
//                    if (op == 8'h00) a = a*10 + (in_buf[j]-"0");
//                    else             b = b*10 + (in_buf[j]-"0");
//                end else if (in_buf[j]=="+" || in_buf[j]=="-" || in_buf[j]=="*" ||
//                             in_buf[j]=="/" || in_buf[j]=="^") begin
//                    if (op == 8'h00) op = in_buf[j];
//                end
//            end
//        end
    
//        case (op)
//            "+": result_val <= a + b;
//            "-": result_val <= a - b;
//            "*": result_val <= a * b;
//            "/": result_val <= (b == 0) ? 32'd0 : (a / b);
//            "^": begin
//                    acc = 1;
//                    for (p = 0; p < MAX_POW; p = p + 1)
//                        if (p < b) acc = acc * a;
//                    result_val <= acc;
//                 end
//            default: result_val <= a;
//        endcase
//    end
//    endtask

    task eval_expr; 
        integer j;
        integer a, b;
        reg [7:0] op;
        begin
            res_has_frac   <= 1'b0;
            res_frac_digit <= 4'd0;

            // parse "a op b" from in_buf
            a = 0; b = 0; op = 8'h00;
            for (j = 0; j < 32; j = j + 1) begin
                if (j < in_len) begin
                    if (in_buf[j] >= "0" && in_buf[j] <= "9") begin
                        if (op == 8'h00) a = a*10 + (in_buf[j]-"0");
                        else             b = b*10 + (in_buf[j]-"0");
                end else if (in_buf[j]=="+" || in_buf[j]=="-" || in_buf[j]=="*" ||
                             in_buf[j]=="/" || in_buf[j]=="^") begin
                    if (op == 8'h00) op = in_buf[j];
                end
            end
        end

        // OPTIMIZED: evaluate (integer)
        case (op)
            "+": result_val <= a + b;
            "-": result_val <= a - b;
            "*": begin
                // Limit multiplication to 16-bit operands to save LUTs
                if (a[31:16] == 0 && b[31:16] == 0)
                    result_val <= a * b;
                else
                   result_val <= 32'hFFFFFFFF;  // Overflow indicator
            end
            "/": begin
                // Use shift-based division for powers of 2, otherwise just divide
                // Limit to avoid large dividers
                if (b == 0)
                    result_val <= 32'd0;
                else if (b == 1)
                    result_val <= a;
                else if (b == 2)
                    result_val <= a >> 1;
                else if (b == 4)
                    result_val <= a >> 2;
                else if (b == 8)
                    result_val <= a >> 3;
                else if (b == 16)
                    result_val <= a >> 4;
                else
                    result_val <= a / b;  // General division (still expensive but less common)
            end
            "^": begin
                // SIMPLIFIED POWER: Only handle small exponents (0-8)
                // This is much more LUT-efficient
                case (b)
                    0: result_val <= 1;
                    1: result_val <= a;
                    2: result_val <= a * a;
                    3: result_val <= (a * a) * a;
                    4: begin
                        result_val <= (a * a) * (a * a);
                    end
                    default: result_val <= 32'hFFFFFFFF;  // Error/overflow
                endcase
            end
            default: result_val <= a;  // if just a number typed
        endcase
    end
    endtask

    // ======================
    // Derivative renderer
    // ======================
    // Evaluate function at cursor position for tangent
    wire signed [31:0] deriv_func_y, deriv_deriv_y;
    
    function_evaluator func_eval_deriv (
        .clk(CLK_100MHZ),
        .x_coord(deriv_cursor_x),
        .coef_a(a_raw),
        .coef_b(b_raw),
        .coef_c(c_raw),
        .coef_d(d_raw),
        .y_original(deriv_func_y),
        .y_derivative(deriv_deriv_y)
    );

    derivative_renderer_fixed u_deriv (
        .clk(CLK_100MHZ),
        .pixel_x(x_left), .pixel_y(y_left),
        .x_offset(x_offset_diff),
        .y_offset(y_offset_diff),
        .zoom_level(zoom_diff),
        .tangent_x0(deriv_cursor_x),
        .tangent_y0(deriv_func_y[15:0]),
        .tangent_slope(deriv_deriv_y[15:0]),
        .tangent_active(1'b1),
        .cursor_visible(1'b1),
        .coef_a(a_raw),
        .coef_b(b_raw),
        .coef_c(c_raw),
        .coef_d(d_raw),
        .pixel_color(jc_deriv_px)
    );
    
    // Derivative 7-segment display
    seven_seg_display deriv_seg (
        .clk(CLK_100MHZ),
        .tangent_active(1'b1),
        .tangent_x0(deriv_cursor_x),
        .tangent_y0(deriv_func_y[15:0]),
        .tangent_slope(deriv_deriv_y[15:0]),
        .seg(seg_deriv),
        .an(an_deriv)
    );

endmodule