module microclock_tb();
reg clk=0;
integer i=0,j=0;
microprocessor uut(
		.clk(clk)
		);
initial begin
repeat(1000) #2 clk=~clk;
end

initial begin 
	$dumpfile("my_dumpfile.vcd");
	$dumpvars(0,uut);
	for(i=0; i<32; i=i+1)
		$dumpvars(1, uut.mainmemory1.RAM[i]);				// NOTE!!! IF SIZE OF REGISTER BANK 
	for(j=0; j<16; j=j+1)									// OR SIZE OF MAIN MEMORY CHANGES
		$dumpvars(2, uut.executionunit.registers[j]); 		// RANGE OF i and j MUST BE CHANGED ACCORDINGLY
end



endmodule
