// Clock speed 1 cycle = 2 time units
// Features to add - Indirect addressing, Input program instructions, memory delays for main memory, cache, pipelining 

module microprocessor(input clk);

wire [7:0] Flag;						// output of the ALU and input to CU, hence wire 
										// flag[7:0] XXX-greaterthan-zero-shift-borrow-carry
wire [4:0] address;						// common address lines for registers and main memory
wire [7:0] databus11;					// to connect databus of system to the Control unit
wire [7:0] databus1;					// datain of mainmemory and dataout of registers- basically for STORE
wire [7:0] databus2;					// datain of registers and dataout of mainmemory- basically for LOAD
wire read, write, store, load;			// common lines- they're obvious
wire [2:0] controllines;
reg  [7:0] databus;						// to connect the output of either the main memory or the CU databus to EU
wire ldi;								// To tell which - mm or the CU has access to the registers

							 
  
mainmemory mainmemory1(clk, address, databus1, read, write, load, store, databus2);		
CU controlunit(clk, Flag, write, read, address, store, load, controllines, ldi, databus11);
EU executionunit(clk, read, write, store, load, ldi, address, controllines, databus, Flag, databus1);

always @(*) begin
databus=(ldi)?databus11:databus2;
end


endmodule



//**************************************************

module mainmemory(
		input clk,
		input [4:0] address,
		input [7:0] data_in,
		input read,
		input write,
		input load,
		input store, 
		output reg [7:0] data_out
    );

reg [7:0] RAM [31:0];
/*initial begin 
RAM[5'd0]=8'd0;
RAM[5'd1]=8'd1;
RAM[5'd2]=8'd2;
RAM[5'd3]=8'd5;
end*/
//*************
//must hardcode some constants to be loaded into the registers and also the program instructions here
	 
always @(*)
	begin 
	if(store && write) 
		RAM[address]=data_in;
	if(read && load)
		data_out=RAM[address];
	end 
	 
endmodule

//*****************************************************
	
module CU      (
		input clk,
		input [7:0] flag,		
		output reg write,				// will use two more signals load and store 
		output reg read,                // to diffrentiate between the main memory and register memory
		output reg [4:0]address,
		output reg store,
		output reg load,		
		output reg [2:0] control,		//control lines for the ALU		
		output reg ldi,
		output reg [7:0] databus
		);

reg [18:0] instruction=0; 				// to store single instruction for 
reg [3:0] opcode=0;						// these four registers are to store the parts of the instructions
reg [4:0] operand1=0;
reg [4:0] operand2=0;
reg [4:0] operand3=0;
reg [3:0] state=0;						// state machines for the different CU processes


initial begin 							//intialising ldi
ldi=0;
end


//********************
//Program memory with hard coded instructions
// MAKE VERY CAREFUL NOTE OF PROGRAM SIZE
// ALSO NOTE THAT I REGISTER HAS TO BE CHANGED IF SIZE OF PROGRAMMEMORY IS CHANGED
// NOT SCALABLE!!
reg [18:0] program [31:0];							// 32 words of program memory 
integer datafile, scanfile;							// file descriptors
reg [4:0] i=0;

initial begin
	datafile= $fopen("machinecode.txt","r");
	if(datafile==0) begin
		$display("Input program not available!");
		$finish;
	end
	else begin
		while(!$feof(datafile)) begin
			scanfile= $fscanf(datafile,"%b\n", program[i]);
			i=i+5'd1;
		end
	end
	$fclose(datafile);
end

/*initial begin 
program[4'd0]=19'b0001_00011_00000_11111;			// load 4 from mm to register 3
program[4'd1]=19'b0001_00100_00001_11111;			// load 4 from mm to register 4
program[4'd2]=19'b0100_00101_00100000_11;			// ldi 32 into r5
program[4'd3]=19'b1000_00011_00011_00100;			// add register 3 to 4 and store in 3
program[4'd4]=19'b0010_00011_00011_11111;			// store result in mm(3)
program[4'd5]=19'b1110_XXXXX_00101_00011;			// compare r5 and r3
program[4'd6]=19'b0101_00100_00011_11011;			// jump to step 3 if greater than is set
program[4'd7]=19'b0000_00000_00000_00000;
end 
*/
//Hardcode instructions here
//********************

reg [4:0] counter=0;							//program counter - 5 bits since program size is only 21 lines

//**********************
initial begin
instruction=program[counter];					//notice the use of blocking assignment for the opcode part
opcode=instruction[18:15];
write=0;
read=0;
load=0;
store=0;
ldi=0;
end
 


always @(posedge clk) begin 
if(opcode!= 4'b0000) begin
	instruction= program[counter];			
	opcode= instruction[18:15];
	operand1= instruction[14:10];
	operand2= instruction[9:5];
	operand3= instruction[4:0]; 
	
	casex(opcode)								//determining state transitions
	
		4'd1:	begin							// Load destination-register mainmemory redundant
				if(state==4'd0)
					state=4'd1;
				else if(state==4'd1)
					state=4'd2;
				else if(state==4'd2)
					state=4'd0;
				end
		
		4'd2: begin								// Store from-register mainmemory redundant
				if(state==4'd0)
					state=4'd3;
				else if(state==4'd3)
					state=4'd4;
				else if(state==4'd4)
					state=4'd0;
				end
			
		4'd3: begin								// MOV destination-register source-register redundant
				if(state==4'd0)
					state=4'd5;	
				else if(state==4'd5)
					state=4'd6;
				else if(state==4'd6)
					state=4'd0;
				end
			
		4'd4: begin 							// Load-direct destination-register 8bit number redundant
				if(state==4'd0)
					state=4'd7;
				else if(state==4'd7)
					state=4'd8;
				else if(state==4'd8)
					state=4'd0;
				end
		
		4'd5: begin 										// Jump condition(4:0) instruction-number(4:0) redundant 
				if(operand1==5'd0)							// Unconditional jump
					counter= operand2[3:0]-5'd1;			// all operations return to state0 which does counter++
				if(operand1==5'd1)	begin					// jump if carry is set
					if(flag[0]==1)
						counter= operand2[3:0]-5'd1;
				end	
				if(operand1==5'd2)	begin					// jump if borrow is set
					if(flag[1]==1)
						counter= operand2[3:0]-5'd1;
				end
				if(operand1==5'd3)	begin					// jump if zero is set
					if(flag[3]==1)
						counter= operand2[3:0]-5'd1;
				end
				if(operand1==5'd4)	begin					// jump if greater-than is set
					if(flag[4]==1)
						counter= operand2[3:0]-5'd1;			
				end
				end


		4'b1XXX: begin 									// ALU operations
				if(state==4'd0)
					state=4'd9;							//opcode destination-register source-register1 source-register2 	
				else if(state==4'd9)
					state=4'd10;
				else if(state==4'd10)
					state=4'd11;
				else if(state==4'd11)
					state=4'd12;
				else if(state==4'd12)
					state=4'd13;
				else if(state==4'd13)
					state=4'd14;		
				else if(state==4'd14)
					state=4'd15;
				else if(state==4'd15)
					state=4'd0;				
				end
			
			
			//	ADD	- 000		
			//	SUB	- 001
			//	AND	- 010
			//	OR	- 011
			//	Shift left- 100
			//	Shift right- 101
			//  CMP - 110
		endcase


		
	casex (state)								// 4'd0 is default state- sets everything to zero- gotta remove it
//**************
		4'd0: begin 							// sets everything to zero- nothing working for one clock cycle
			store=1'b0;
			load=1'b0;
			read=1'b0;
			write=1'b0;			
			ldi=1'b0;
			counter= counter+ 5'd1;				//increment program counter
		end
		
		4'd1: begin 							// Load step1
			store=1'b0;
			address= operand2;					// address location in main memory
			load= 1'b1; 					   	// load is gonna be on throughout the operation 
			read= 1'b1;							// put data on databus
			
		end
			
		4'd2: begin								// Load step2
			read=1'b0;
			address= operand1;					// set address lines to the register address
			write= 1'b1;						// write data into the register
			
		end
		
		4'd3: begin								// Store step1
			load= 1'b0;							
			address= operand1;
			store= 1'b1;
			read= 1'b1;							// read data from register onto databus
			
		end
		
		4'd4: begin								// Store step2
			read= 1'b0;
			address= operand2;
			write= 1'b1;
			
		end
		
		4'd5: begin 							//MOV step1
			load= 1'b0;
			store= 1'b0;
			address= operand2;
			read= 1'b1;
		end
		
		4'd6: begin 							// MOV step2
			read= 1'b0;
			address= operand1;
			write= 1'b1;
		end
		
		4'd7: begin 							// LDI step1
			load= 1'b0;
			store= 1'b0;
			read= 1'b0;
			databus= instruction[9:2];			// set the content of the (databus to EU) to the given data
			ldi=1'b1;							// enable ldi signal
		end
		
		4'd8: begin								// LDI step2
			address= operand1;			
			write= 1'b1;
		end
	
		4'd9: begin								// ALU operations step1
			load= 1'b0;							// Implementing the first move step1
			store= 1'b0;
			address= operand2;
			read= 1'b1;
		end			
	
		4'd10: begin 
			read= 1'b0;							// ALU step2
			address= 5'b00000;					// Move from operand 2 to R0 		 
			write= 1'b1;
		end
	
		4'd11: begin 							//ALU step3
			write= 1'b0;
			address= operand3;					// Implementing the second move
			read= 1'b1;					
		end
		
		4'd12: begin							// ALU step4
			read= 1'b0;
			address= 5'b00001;					// Move from operand 3 to R1	
			write= 1'b1;
		end
		
		4'd13: begin							// ALU step5
			write= 1'b0;
			control= opcode[2:0];				// Perform ALU operation
		end
		
		4'd14: begin 							// ALU step6
			address= 5'b00010;					// Initiate third move
			read= 1'b1;
		end
		
		4'd15: begin 
			read= 1'b0;
			address= operand1;					// Move from output register R2 to operand 1	
			write= 1'b1;
		end
				
		endcase
	end
end

endmodule


//******************************************************


module EU	(
		input clk,
		input read,
		input write,
		input store,
		input load,
		input ldi,
		input [4:0] address,
		input [2:0] controllines,
		input [7:0] datain,
		output [7:0] flag,				// this is the output of ALU module- sufficient for it to be wire-  
		output reg [7:0] dataout
		);
reg [7:0] internalbus;					// internal bus
reg [7:0] registers [15:0];				// register memory 
wire [7:0] register2;
always @(*)								// telling the registers what to do
	begin 
	if (read && !store && !load)
		begin 
			internalbus= registers[address];
		end
	if (read && store)
		begin 
			dataout=registers[address];
		end
	if (write && !load && !store && !ldi)
		begin 
			registers[address]=internalbus;		
		end
	if (write && (load || ldi))
		begin 
			registers[address]= datain;
		end			
	end

ALU alu(clk, controllines, registers[0], registers[1], flag, register2);	// ALU instantiation with mapped registers

always @(*) begin															// need to connect wire to output driven by reg as
registers[2]=register2;														// reg can't be connected to output of ALU- connect  
end																			// wire then assign in an always block

endmodule


//******************************************************

module ALU	(
		input clk,
		input [2:0] controllines,
		input [7:0] A,
		input [7:0] B,
		output reg [7:0] flag,
		output reg [7:0] C
		);
		initial begin
			flag=7'b0;													// initialising flags to zero
		end
//Clock to be added
       always @(*)     
        case (controllines)
            3'd0 : begin 
            			{flag[0], C}= A+B;	
            			flag[3]=((flag[0]==0) && (C==0))?1:0;			// setting zero flag for zero output	
            		 end
            3'd1 : begin 
            			{flag[1], C}= A-B; 
            			flag[3]=(A==B)?1:0;								// setting zero flag for zero output
            		end
            3'd2 : begin 
            			C=A&B;
            			flag[3]=(C==0)?1:0; 
            		end
            3'd3 : begin
            			C=A|B;
            			flag[3]=(C==0)?1:0; 
            		end
			3'd4 : begin 
						{flag[2],C}=A<<B; 
					end			
			3'd5 : begin
						{C,flag[2]}=A>>B; 
					end			
			3'd6 : begin 
						flag[4]=(A>B)?1:0;								// Note that errors may arise if C 
					end		 											// register is not chosen carefully
        endcase 
        
endmodule		

//******************************************************
