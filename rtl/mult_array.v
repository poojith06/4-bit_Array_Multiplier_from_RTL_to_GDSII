module mult_array (
    input        clk,
    input        rst_n,
    input  [3:0] a,
    input  [3:0] b,
    output [7:0] p
);

    // Input registers: 4 + 4 = 8 flip-flops
    reg [3:0] a_reg, b_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 4'b0;
            b_reg <= 4'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
        end
    end

    // Partial products: 16 AND gates, ppi[j] = a_reg[j] AND b_reg[i]
    wire [3:0] pp0, pp1, pp2, pp3;

    assign pp0 = a_reg & {4{b_reg[0]}};
    assign pp1 = a_reg & {4{b_reg[1]}};
    assign pp2 = a_reg & {4{b_reg[2]}};
    assign pp3 = a_reg & {4{b_reg[3]}};

    // Combinational product bits (registered into p below)
    wire [7:0] p_comb;

    // Row 0: no adders. p_comb[0] is the final bit; pp0[3:1] pass down.
    wire [3:0] r0;
    assign p_comb[0] = pp0[0];
    assign r0        = {1'b0, pp0[3], pp0[2], pp0[1]};

    // Row 1: 4-bit ripple-carry adder, pp1 + r0
    wire [3:0] s1;
    wire [4:0] c1;
    assign c1[0] = 1'b0;

    full_adder fa_r1_0 (.a(pp1[0]), .b(r0[0]), .cin(c1[0]), .sum(s1[0]), .cout(c1[1]));
    full_adder fa_r1_1 (.a(pp1[1]), .b(r0[1]), .cin(c1[1]), .sum(s1[1]), .cout(c1[2]));
    full_adder fa_r1_2 (.a(pp1[2]), .b(r0[2]), .cin(c1[2]), .sum(s1[2]), .cout(c1[3]));
    full_adder fa_r1_3 (.a(pp1[3]), .b(r0[3]), .cin(c1[3]), .sum(s1[3]), .cout(c1[4]));

    assign p_comb[1] = s1[0];
    wire [3:0] r1 = {c1[4], s1[3], s1[2], s1[1]};

    // Row 2: 4-bit ripple-carry adder, pp2 + r1
    wire [3:0] s2;
    wire [4:0] c2;
    assign c2[0] = 1'b0;

    full_adder fa_r2_0 (.a(pp2[0]), .b(r1[0]), .cin(c2[0]), .sum(s2[0]), .cout(c2[1]));
    full_adder fa_r2_1 (.a(pp2[1]), .b(r1[1]), .cin(c2[1]), .sum(s2[1]), .cout(c2[2]));
    full_adder fa_r2_2 (.a(pp2[2]), .b(r1[2]), .cin(c2[2]), .sum(s2[2]), .cout(c2[3]));
    full_adder fa_r2_3 (.a(pp2[3]), .b(r1[3]), .cin(c2[3]), .sum(s2[3]), .cout(c2[4]));

    assign p_comb[2] = s2[0];
    wire [3:0] r2 = {c2[4], s2[3], s2[2], s2[1]};

    // Row 3: 4-bit ripple-carry adder, pp3 + r2. Also produces p_comb[7:4].
    wire [3:0] s3;
    wire [4:0] c3;
    assign c3[0] = 1'b0;

    full_adder fa_r3_0 (.a(pp3[0]), .b(r2[0]), .cin(c3[0]), .sum(s3[0]), .cout(c3[1]));
    full_adder fa_r3_1 (.a(pp3[1]), .b(r2[1]), .cin(c3[1]), .sum(s3[1]), .cout(c3[2]));
    full_adder fa_r3_2 (.a(pp3[2]), .b(r2[2]), .cin(c3[2]), .sum(s3[2]), .cout(c3[3]));
    full_adder fa_r3_3 (.a(pp3[3]), .b(r2[3]), .cin(c3[3]), .sum(s3[3]), .cout(c3[4]));

    assign p_comb[3]   = s3[0];
    assign p_comb[7:4] = {c3[4], s3[3], s3[2], s3[1]};

    // Output register: 8 flip-flops
    reg [7:0] p_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            p_reg <= 8'b0;
        else
            p_reg <= p_comb;
    end

    assign p = p_reg;

endmodule