`timescale 1ns / 1ps

module Top_Student(
    input basys_clock, clk_6p25m,
    input btnL, btnR, btnU, btnD, btnC, 
    input [15:0] sw,
    input [6:0] x_raw, input [5:0] y_raw,
    input [31:0] buffer,
    input enable_integral, // for integral
    
    output graph_mode,
    output [15:0] oled_data, 
    output [3:0] an, 
    output [6:0] seg, 
    output [3:0] led,
    output [15:0] a_val_out, // for derivative
    output [15:0] b_val_out,
    output [15:0] c_val_out,
    output [15:0] d_val_out
);
    
    // Clocks
    wire clk_25m, clk_1khz;
    clock_divider_generic #(.DIV(2)) unit_25m (.clk_in(basys_clock), .clk_out(clk_25m));
    clock_divider_generic #(.DIV(50_000)) unit_1khz (.clk_in(basys_clock), .clk_out(clk_1khz));
    
    // Mode management
    parameter MENU = 0; 
    parameter GRAPH = 1;
    wire [15:0] graph_oled; 
    wire [15:0] menu_oled;
    assign oled_data = (graph_mode == GRAPH) ? graph_oled : menu_oled;
    
    // Coordinates
    wire signed [15:0] x, y, scale;
    
    graph_coord unit_gpcoord(.x_raw(x_raw), .y_raw(y_raw), .scale(scale), .x_out(x), .y_out(y));
    
    // Zoom
    zoom_scale unit_zoom(.clk(clk_1khz), .mode(graph_mode), .pan_toggle(sw[0]), 
                         .btnU(btnU), .btnD(btnD), .scale(scale));
    led_controller unit_led(.mode(graph_mode), .scale(scale), .led(led));
    
    // Panning
    wire signed [15:0] pan_x, pan_y;
    pan_controller unit_pan(.clk(clk_1khz), .mode(graph_mode), .pan_toggle(sw[0]), 
                            .btnL(btnL), .btnR(btnR), .btnU(btnU), .btnD(btnD), .btnC(btnC),
                            .scale(scale), .pan_x(pan_x), .pan_y(pan_y));
    
    wire [15:0] graph_x = x + pan_x;
    wire [15:0] graph_y = y + pan_y;

    // Cursor
    wire signed [15:0] cursor_x; 
    wire signed [31:0] cursor_y;
    wire on_cursor;    
    wire signed [15:0] x_max; 
    wire signed [31:0] y_max; 
    wire max_done;
    wire signed [15:0] x_min; 
    wire signed [31:0] y_min; 
    wire min_done;
    wire signed [15:0] a, b, c, d;
        
    compute_function func_cur(.x(cursor_x), .a(a), .b(b), .c(c), .d(d), .y_func(cursor_y));
    cursor unit_cur(.clk(clk_25m), .mode(graph_mode), 
        .btnL(btnL), .btnR(btnR), .btnU(btnU), .btnD(btnD), .pan_toggle(sw[0]),
        .x(graph_x), .y(graph_y),
        .cursor_y(cursor_y),
        .x_max(x_max), .max_done(max_done),
        .x_min(x_min), .min_done(min_done),
        .cursor_x(cursor_x),
        .on_cursor(on_cursor)); 
    
    // Graph menu
    wire signed [31:0] a_val, b_val, c_val, d_val; 
    
    graph_inputs graph_inp(.clk(clk_1khz), .buffer(buffer), .sw(sw[15:11]), .mode(graph_mode), 
                            .a(a_val), .b(b_val), .c(c_val), .d(d_val));
    
    graph_menu menu_inst(
        .clk(clk_25m),
        .x(x_raw), .y(y_raw),
        .sw(sw[15:11]),
        .a_val(a_val), .b_val(b_val), .c_val(c_val), .d_val(d_val),
        .pixel_data(menu_oled)
    );
    
    // Input scaler
    input_scaler unit_inp_scl(.a(a_val), .b(b_val), .c(c_val), .d(d_val), 
                              .out_a(a), .out_b(b), .out_c(c), .out_d(d));
    
    // Max/Min finder
    wire signed [15:0] x_line, x_left, x_right; 
    wire show_line_left, show_line_right; 
    wire normal_cursor_on, find_enable;
    wire integral_selecting;  // NEW: indicates selecting limits
    wire [1:0] selection_state;  // NEW: which limit being selected
    
    max_select_controller max_ctrl (
        .clk(clk_25m), .mode(graph_mode), .sw(sw[2:1]),
        .enable_integral(enable_integral),
        .btnC(btnC), .cursor_x(cursor_x),
        .x_left(x_left), .x_right(x_right),
        .show_line_left(show_line_left), .show_line_right(show_line_right),
        .find_enable(find_enable), .cursor_active(normal_cursor_on),
        .selecting(integral_selecting),  // NEW output
        .selection_state(selection_state)  // NEW output
    );
    
    max_finder unit_max(
        .clk(clk_25m),
        .a(a), .b(b), .c(c), .d(d),
        .x_left(x_left), .x_right(x_right),
        .find_enable(find_enable & sw[1]),
        .x_max(x_max), .y_max(y_max), .done(max_done)
    );

    min_finder unit_min(
        .clk(clk_1khz),
        .a(a), .b(b), .c(c), .d(d),
        .x_left(x_left), .x_right(x_right),
        .find_enable(find_enable & sw[2]), 
        .x_min(x_min), .y_min(y_min), .done(min_done)
    );
    
    // Main graph drawing
    graph unit_graph(
        .clk(clk_25m), .x(graph_x), .y(graph_y), 
        .a(a), .b(b), .c(c), .d(d), .scale(scale),
        .show_line_left(show_line_left), .show_line_right(show_line_right),
        .x_left(x_left), .x_right(x_right), .find_enable(find_enable),
        .enable_integral(enable_integral),
        .on_cursor(on_cursor & normal_cursor_on), .oled_data(graph_oled)
    );
    
    wire int_calc_done; 
    wire [31:0] int_result;
    
    // integral stuff
    calc_integral int_calc (
        .clk(basys_clock),
        .start(find_enable && enable_integral),
        .lower_bound(x_left),
        .upper_bound(x_right),
        .coeff_a(a), .coeff_b(b), .coeff_c(c), .coeff_d(d),  
        .done(int_calc_done),
        .integral_result(int_result)
    );
    
    // 7-segment display
    gp_seg_controller seg_disp(
        .clk(clk_1khz), .mode(graph_mode), 
        .cursor_x(cursor_x), .cursor_y(cursor_y), 
        .integral_value(int_result), 
        .integral_done(find_enable && enable_integral),  // Show result only when calculation complete
        .integral_selecting(integral_selecting),  // NEW input
        .selection_state(selection_state),        // NEW input
        .enable_integral_mode(enable_integral),   // NEW input - tells if in integral mode
        .an(an), .seg(seg)
    );
    
    // Output assignments for derivative mode
    assign a_val_out = a_val[15:0];
    assign b_val_out = b_val[15:0];
    assign c_val_out = c_val[15:0];
    assign d_val_out = d_val[15:0];
    
endmodule