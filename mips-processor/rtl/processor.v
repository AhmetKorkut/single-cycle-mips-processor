module processor;

reg clk;
reg [31:0] pc;

// ================= Memories =================
reg [7:0] mem    [0:63];
reg [7:0] datmem [0:63];

// ================= Register File =============
reg [31:0] registerfile [0:15];

// ================= Fetch =====================
wire [31:0] instruc;
assign instruc = { mem[pc[5:0]],
                   mem[pc[5:0]+1],
                   mem[pc[5:0]+2],
                   mem[pc[5:0]+3] };

// ================= Instruction Fields =========
wire [7:0]  op     = instruc[31:24];
wire [3:0]  rs4    = instruc[23:20];
wire [3:0]  rt4    = instruc[19:16];
wire [3:0]  rd4    = instruc[15:12];
wire [5:0]  shamt6 = instruc[11:6];
wire [5:0]  funct  = instruc[5:0];

wire [15:0] imm16  = instruc[15:0];
wire [7:0]  imm8   = instruc[15:8];
wire [7:0]  addr8  = instruc[7:0];

// ================= Sign Extend ================
wire [31:0] sext_imm16 = {{16{imm16[15]}}, imm16};
wire [31:0] sext_imm8  = {{24{imm8[7]}}, imm8};
wire [31:0] sext_addr8 = {{24{addr8[7]}}, addr8};

// ================= Register Read ===============
wire [31:0] dataa = registerfile[rs4];
wire [31:0] datab = registerfile[rt4];

// ================= Control ====================
wire regdest, alusrc, memtoreg, regwrite, memread, memwrite, branch, jump, jal;
control CU(op, regdest, alusrc, memtoreg, regwrite, memread, memwrite, branch, jump, jal);

// ================= ISA Params =================
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

localparam [5:0]
    F_SLL  = 6'd1,
    F_MOVE = 6'd2,
    F_NAND = 6'd3,
    F_OR   = 6'd4;

// ================= ALU Control =================
reg [3:0] alu_ctrl;

always @(*) begin
    alu_ctrl = 4'b0010;
    if (op == OP_R) begin
        case (funct)
            F_SLL:  alu_ctrl = 4'b1000;
            F_MOVE: alu_ctrl = 4'b1001;
            F_NAND: alu_ctrl = 4'b0100;
            F_OR:   alu_ctrl = 4'b0001;
        endcase
    end else if (op == OP_SUBI || op == OP_BEQ || op == OP_BEQI)
        alu_ctrl = 4'b0110;
    else if (op == OP_BLT)
        alu_ctrl = 4'b0111;
end

wire [31:0] alu_b =
    (op == OP_R && funct == F_SLL) ? {27'd0, shamt6[4:0]} :
    (op == OP_BEQI)                ? sext_imm8 :
    (alusrc ? sext_imm16 : datab);

wire [31:0] alu_out;
wire zout;

alu32 ALU(alu_out, dataa, alu_b, zout, alu_ctrl);

// ================= Data Memory =================
wire [31:0] readdata = { datmem[alu_out[5:0]],
                         datmem[alu_out[5:0]+1],
                         datmem[alu_out[5:0]+2],
                         datmem[alu_out[5:0]+3] };

// ================= PC Logic ====================
wire [31:0] pc_plus4 = pc + 4;

wire beq_taken  = (op == OP_BEQ)  && zout;
wire blt_taken  = (op == OP_BLT)  && (alu_out == 32'd1);
wire beqi_taken = (op == OP_BEQI) && zout;

wire [31:0] branch_target =
    (op == OP_BEQI) ? (pc_plus4 + (sext_addr8 << 2))
                    : (pc_plus4 + (sext_imm16 << 2));

wire branch_taken = beq_taken | blt_taken | beqi_taken;

// jump target
wire [31:0] jump_target = {22'd0, addr8, 2'b00};

wire [31:0] next_pc =
    jump         ? jump_target   :
    branch_taken ? branch_target :
                   pc_plus4;

// ================= Write Back ==================
wire [3:0] writereg =
    jal     ? 4'd15 :
    regdest ? rd4   : rt4;

wire [31:0] writedata =
    jal      ? pc_plus4 :
    memtoreg ? readdata :
               alu_out;

// ================= Stack Protection =============
wire signed [31:0] spba = registerfile[12];
wire signed [31:0] spl  = registerfile[13];
wire signed [31:0] sp   = registerfile[14];

wire uses_sp_as_base = ((op == OP_LW) || (op == OP_SW)) && (rs4 == 4'd14);

wire signed [31:0] base_addr =
    uses_sp_as_base ? (spba + sp) : dataa;

wire signed [31:0] ea = base_addr + $signed(sext_imm16);

wire modifies_sp =
    ((op == OP_ADDI) || (op == OP_SUBI)) && (rs4 == 4'd14) && (rt4 == 4'd14);

wire signed [31:0] sp_next =
    (op == OP_SUBI) ? (sp - $signed(sext_imm16)) :
                      (sp + $signed(sext_imm16));

wire signed [31:0] sp_min = -(spl <<< 2);
wire signed [31:0] sp_max = 0;

wire overflow  = (modifies_sp && (sp_next < sp_min)) ||
                 (uses_sp_as_base && (ea < 32 || ea > 39));

wire underflow = modifies_sp && (sp_next > sp_max);

wire safe_regwrite = regwrite & ~overflow & ~underflow;
wire safe_memwrite = memwrite & ~overflow & ~underflow;

// ================= Sequential ==================
initial begin
    clk = 0;
    pc  = 0;
    $readmemh("initIM.dat",  mem);
    $readmemh("initDM.dat",  datmem);
    $readmemh("initReg.dat", registerfile);
    forever #20 clk = ~clk;
end

always @(posedge clk) begin
    pc <= next_pc;

    if (safe_memwrite) begin
        datmem[alu_out[5:0]]   <= datab[31:24];
        datmem[alu_out[5:0]+1] <= datab[23:16];
        datmem[alu_out[5:0]+2] <= datab[15:8];
        datmem[alu_out[5:0]+3] <= datab[7:0];
    end

    if (safe_regwrite)
        registerfile[writereg] <= writedata;
end

// ================= OUTPUT FORMAT =================
initial
$monitor("%0d PC=%h INSTR=%h opcode=%0d rs=%0d rt=%0d rd=%0d shamt=%0d funct=%0d ALU=%h WBdst=%0d WBdata=%h overflow=%b underflow=%b sp_error=%b", "REGISTER %p DATA MEMORY %p", initReg, initDM,
         $time, pc, instruc, op, rs4, rt4, rd4, shamt6, funct,
         alu_out, writereg, writedata, overflow, underflow, (overflow | underflow));

endmodule
