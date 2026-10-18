// full_adder.v
// 1-bit combinational full adder, written purely with assign statements.
// sum = a XOR b XOR cin
// cout = majority(a, b, cin)
module full_adder (
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);

    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);

endmodule
