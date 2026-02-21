module control(in,f, regdest, alusrc, memtoreg, regwrite, 
	       memread, memwrite, branch, aluop1, aluop2, jal, jump,jr);

input [5:0] in;
input [3:0] f;
output regdest, alusrc, memtoreg, regwrite, memread, memwrite, branch, aluop1, aluop2, jal, jump,jr;

wire rformat,lw,sw,beq,jall,j,jump_reg;

assign rformat =~| in;
assign jump_reg = (~|in) & f[3]&(~f[2])&(~f[1])&(~f[0]); // 001000 = 8

assign jump_reg = (in == 6'd32) & (f == 6'b001000);

// 40 = 101000
assign j = in[5] & ~in[4] &  in[3] & ~in[2] & ~in[1] & ~in[0];

// 41 = 101001
assign jall = in[5] & ~in[4] &  in[3] & ~in[2] & ~in[1] &  in[0];
assign lw = in[5] & ~in[4] & ~in[3] &  in[2] & ~in[1] &  in[0]; // 37 = 100101
assign sw = in[5] & ~in[4] & ~in[3] &  in[2] &  in[1] & ~in[0]; // 38 = 100110
assign beq = in[5] & ~in[4] & ~in[3] &  in[2] &  in[1] &  in[0]; // 39 = 100111


assign regdest = rformat;

assign alusrc = lw|sw;
assign memtoreg = lw;
assign regwrite = (rformat|lw|jall) & (~jump_reg);
assign memread = lw;
assign memwrite = sw;
assign branch = beq;
assign aluop1 = rformat;
assign aluop2 = beq;
assign jal = jall;
assign jump = jall|j;
assign jr = jump_reg;


endmodule

module control(
    input  [7:0] op,
    output       regdest,
    output       alusrc,
    output       memtoreg,
    output       regwrite,
    output       memread,
    output       memwrite,
    output       branch,
    output       jump,
    output       jal
);

    // Student: 300201032 -> base opcode 32
    localparam [7:0]
        OP_R    = 8'd32,
        OP_ADDI = 8'd33,
        OP_SUBI = 8'd34,
        OP_BLT  = 8'd35,
        OP_BEQI = 8'd36,
        OP_LW   = 8'd37,
        OP_SW   = 8'd38,
        OP_BEQ  = 8'd39,
        OP_J    = 8'd40,
        OP_JAL  = 8'd41;

    wire is_r    = (op == OP_R);
    wire is_addi = (op == OP_ADDI);
    wire is_subi = (op == OP_SUBI);
    wire is_blt  = (op == OP_BLT);
    wire is_beqi = (op == OP_BEQI);
    wire is_lw   = (op == OP_LW);
    wire is_sw   = (op == OP_SW);
    wire is_beq  = (op == OP_BEQ);
    wire is_j    = (op == OP_J);
    wire is_jal  = (op == OP_JAL);

    assign regdest  = is_r;                       // R-type: rd
    assign alusrc   = is_lw | is_sw | is_addi | is_subi; // I-type: immediate
    assign memtoreg = is_lw;
    assign regwrite = is_r | is_lw | is_addi | is_subi | is_jal;
    assign memread  = is_lw;
    assign memwrite = is_sw;
    assign branch   = is_beq | is_blt | is_beqi;
    assign jump     = is_j | is_jal;
    assign jal      = is_jal;

endmodule
