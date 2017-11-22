# To write an Assembler that translates instructions to machine code
# Instructions will be of the form- Opcode Operand1 Operand2 Operand3

import sys
inputfile= sys.argv[1]					# input program in assembly can vary but output will always go to machinecode.txt


# To make a dictionary corresponding to all the opcodes
# Pneumonic keys and 4 bit binary values
opcode= {
		'LOAD': "0001",
		'STORE': "0010",
		'MOV': "0011",
		'LDI': "0100",
		'JUMP': "0101",
		'ADD': "1000",
		'SUB': "1001",
		'AND': "1010",
		'OR': "1011",
		'SL': "1100",
		'SR': "1101",
		'CMP': "1110"
		}


# To make a dictionary for Operand1
# keys are registers of the form R0,R1 etc. or conditions
# Operand1 can be a register, condition
operand1= {
		'R0': "00000",
		'R1': "00001",
		'R2': "00010",
		'R3': "00011",
		'R4': "00100",
		'R5': "00101",
		'R6': "00110",
		'R7': "00111",
		'R8': "01000",
		'R9': "01001",
		'R10': "01010",
		'R11': "01011",
		'R12': "01100",
		'R13': "01101",
		'R14': "01110",
		'R15': "01111",		
		'U': "00000",
		'C': "00001",
		'B': "00010",
		'Z': "00011",
		'G': "00100"
		}



# To make a dictionary for Operand2
# keys are registers of the form R0,R1 etc. or main memory locations- jump handled differently
# Operand2 can be a register, address
operand2= {
		'R0': "00000",
		'R1': "00001",
		'R2': "00010",
		'R3': "00011",
		'R4': "00100",
		'R5': "00101",
		'R6': "00110",
		'R7': "00111",
		'R8': "01000",
		'R9': "01001",
		'R10': "01010",
		'R11': "01011",
		'R12': "01100",
		'R13': "01101",
		'R14': "01110",
		'R15': "01111",
		'M0': "00000",
		'M1': "00001",
		'M2': "00010",
		'M3': "00011",
		'M4': "00100",
		'M5': "00101",
		'M6': "00110",
		'M7': "00111",
		'M8': "01000",
		'M9': "01001",
		'M10': "01010",
		'M11': "01011",
		'M12': "01100",
		'M13': "01101",
		'M14': "01110",
		'M15': "01111",
		'M16': "10000",
		'M17': "10001",
		'M18': "10010",
		'M19': "10011",
		'M20': "10100",
		'M21': "10101",
		'M22': "10110",
		'M23': "10111",
		'M24': "11000",
		'M25': "11001",
		'M26': "11010",
		'M27': "11011",
		'M28': "11100",
		'M29': "11101",
		'M30': "11110",
		'M31': "11111"	
}

# To make a dictionary for Operand3
# keys are registers of the form R0,R1 etc.
# Operand3 can be a register
operand3= {
		'R0': "00000",
		'R1': "00001",
		'R2': "00010",
		'R3': "00011",
		'R4': "00100",
		'R5': "00101",
		'R6': "00110",
		'R7': "00111",
		'R8': "01000",
		'R9': "01001",
		'R10': "01010",
		'R11': "01011",
		'R12': "01100",
		'R13': "01101",
		'R14': "01110",
		'R15': "01111",
		'X'	: "XXXXX"
		}

datafile= open(inputfile, "r")
programfile= open("machinecode.txt", "w")
program= datafile.read()
datafile.close()
program= program.strip().split('\n')
n= len(program)



# jump locatons have to be determined beforehand to jump to future instructions

gotodict={}												# To find the locations of the jump statements
for i in range(0,n):
	array= program[i].strip().split(' ')
	if (':' in array[0]):								# : indicates the presence of a jump to this step in the program 
		tag= array.pop(0)
		tag= tag[0:len(tag)-1]							# removes the : from the tag
		gotodict[tag]= "{0:05b}".format(i)				# associates the tag with the ith instruction


for i in range(0,n):
	array= program[i].strip().split(' ')				# contains the instruction split into opcode and operands
	if (':' in array[0]):								# : indicates the presence of a jump to this step in the program 
		tag= array.pop(0)	
	instruction= ''										# final instruction to be written into the output file
	
	if (len(array)==3 and (array[0]!="LDI" 				# Deal with LOAD, STORE, MOV- all have only three parts as last is redundant
		and array[0]!="JUMP" and array[0]!="CMP" )):
		instruction= opcode[array[0]]+ '_'+ operand1[array[1]]+ '_'+ operand2[array[2]]+ '_'+ operand3['X']+ '\n'


	if (array[0]=='LDI'):
		instruction= opcode[array[0]]+ '_'+ operand1[array[1]]+ '_'+ '{0:08b}'.format(int(array[2]))+ "_"+ "XX"+ "\n"

	if array[0]=='JUMP':
		instruction= opcode[array[0]]+ '_'+ operand1[array[1]]+ '_'+ gotodict[array[2]]+ '_'+ operand3['X']+ "\n"

	if ( len(array)==4):									# All ALU operations other than CMP
		instruction= opcode[array[0]]+ '_'+ operand1[array[1]]+ '_'+ operand2[array[2]]+ '_'+ operand3[array[3]]+ '\n'

	if (array[0]=='CMP'):
		instruction= opcode[array[0]]+ '_'+ operand3["X"]+ '_'+ operand1[array[1]]+ '_'+ operand2[array[2]]+ '\n'

	programfile.write(instruction)

instruction='0000_00000_00000_00000'
programfile.write(instruction)							# 0000 opcode for termination of program						
programfile.close()



