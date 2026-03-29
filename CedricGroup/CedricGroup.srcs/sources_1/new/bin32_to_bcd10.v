// Converts 32-bit unsigned 'bin' to 10 BCD digits using double-dabble.
// Run-time: 32 clk cycles after 'start'.
module bin32_to_bcd10 (
    input  wire        clk,
    input  wire        start,
    input  wire [31:0] bin,
    output reg         busy,
    output reg         done,
    output reg  [39:0] bcd    // 10 nibbles: {d9,...,d0} (MSD at [39:36])
);
    reg [31:0] sh;
    reg [3:0]  d[0:9];
    reg [5:0]  cnt;
    integer i;

    always @(posedge clk) begin
        if (start && !busy) begin
            busy <= 1; done <= 0; cnt <= 6'd32; sh <= bin;
            for (i=0;i<10;i=i+1) d[i] <= 4'd0;
        end else if (busy) begin
            // add-3 where needed
            for (i=0;i<10;i=i+1) if (d[i] >= 5) d[i] <= d[i] + 4'd3;
            // shift left one
            {d[9],d[8],d[7],d[6],d[5],d[4],d[3],d[2],d[1],d[0],sh} <=
            {d[9],d[8],d[7],d[6],d[5],d[4],d[3],d[2],d[1],d[0],sh} << 1;
            d[0][0] <= sh[31];
            cnt <= cnt - 1;
            if (cnt == 0) begin
                busy <= 0; done <= 1;
                bcd  <= {d[9],d[8],d[7],d[6],d[5],d[4],d[3],d[2],d[1],d[0]};
            end
        end else begin
            done <= 0;
        end
    end
endmodule
