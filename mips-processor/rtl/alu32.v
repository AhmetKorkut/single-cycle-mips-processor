module alu32(
    output reg [31:0] alu_out,
    input      [31:0] a,
    input      [31:0] b,
    output reg        zout,
    input      [3:0]  alu_control
);

always @(*) begin
    case (alu_control)
        4'b0000: alu_out = a & b;            // AND
        4'b0001: alu_out = a | b;            // OR
        4'b0010: alu_out = a + b;            // ADD
        4'b0011: alu_out = a ^ b;            // XOR
        4'b0100: alu_out = ~(a & b);         // NAND (NEW)
        4'b0110: alu_out = a - b;            // SUB
        4'b0111: alu_out = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT signed
        4'b1000: alu_out = a << b[4:0];      // SLL (NEW) shift amount in b[4:0]
        4'b1001: alu_out = a;                // MOVE/PASS A (NEW)
        default: alu_out = 32'hXXXXXXXX;
    endcase

    zout = (alu_out == 32'd0);
end

endmodule
