// tb_mult.v
// Exhaustive, self-checking testbench for mult_array.
//
// - 10 ns period clock, rst_n held low for the first 2 clock cycles.
// - Applies all 256 combinations of a (0..15) and b (0..15).
// - Inputs change on a falling edge. For each combination, waits the
//   2-cycle latency (input captured at rising edge 1, product captured at
//   rising edge 2), then at the next falling edge compares p
//   against the expected value computed with the `*` operator, which is
//   allowed here in the testbench only (the DUT itself never uses `*`).
// - Prints a line for every mismatch and one final PASS/FAIL summary line.
// - Dumps all signals to mult.vcd for waveform viewing.

`timescale 1ns / 1ps

module tb_mult;

    reg        clk;
    reg        rst_n;
    reg  [3:0] a, b;
    wire [7:0] p;

    integer    i, j;
    integer    vectors;
    integer    errors;
    reg  [7:0] expected;

    // Device under test
    mult_array dut (
        .clk   (clk),
        .rst_n (rst_n),
        .a     (a),
        .b     (b),
        .p     (p)
    );

    // 10 ns period clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("mult.vcd");
        $dumpvars(0, tb_mult);

        vectors = 0;
        errors  = 0;

        // Hold rst_n low for the first 2 clock cycles.
        rst_n = 1'b0;
        a     = 4'd0;
        b     = 4'd0;
        @(negedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // Exhaustive sweep: all 256 (a, b) combinations.
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                a        = i[3:0];
                b        = j[3:0];
                expected = a * b; // `*` allowed only in the testbench

                // 2-cycle latency: edge 1 captures a,b into the input
                // registers; edge 2 captures the product into p.
                @(posedge clk);
                @(posedge clk);
                // Compare mid-cycle: gate-level flip-flop models update Q
                // 1 time unit after the edge, so sampling at the falling
                // edge avoids a race with the clk-to-q delay.
                @(negedge clk);

                vectors = vectors + 1;
                if (p !== expected) begin
                    errors = errors + 1;
                    $display("MISMATCH: a=%0d b=%0d expected=%0d got=%0d",
                              a, b, expected, p);
                end
            end
        end

        if (errors == 0)
            $display("PASS: %0d vectors checked, 0 errors", vectors);
        else
            $display("FAIL: %0d vectors checked, %0d errors", vectors, errors);

        $finish;
    end

endmodule
