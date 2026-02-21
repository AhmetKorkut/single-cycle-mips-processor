module alucont(aluop1,aluop0,f3,f2,f1,f0,gout);
input aluop1,aluop0,f3,f2,f1,f0;
output [2:0] gout;
reg [2:0] gout;

always @(aluop1 or aluop0 or f3 or f2 or f1 or f0)
begin
	if(~(aluop1|aluop0))
		gout=3'b010; //add
	if(aluop0)
		gout=3'b110; //sub
	if(aluop1)
	begin
		if (~(f3|f2|f1|f0))
			gout=3'b010; //add
		if (f1 & f3)
			gout=3'b111; //set less than
		if (f1 &~(f3))
			gout=3'b110; //subtract
		if (f2 & f0)
			gout=3'b001; //or
		if (f2 &~(f0))
			gout=3'b000; //and
		if (f2 & f1 & f3 & f0)
			gout = 3'b011; //xor
	end
end
endmodule

