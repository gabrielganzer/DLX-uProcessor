----------------------------------------------------------------------------------
-- Engineer: GANZER Gabriel
-- Company: Politecnico di Torino
-- Descriptions: set of constants, subtypes, and functions
-- Date: 28/07/2020
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package GLOBALS is
  
  -- Functions
 	-- Division between the two parameters, the result is an integer rounded by excess	
	function divide (n:integer; m:integer) return integer;
	-- Log base 2 of the number n, the result is an integer rounded by excess
	function log2 (n:integer) return integer;

  -- Datapath constants
  constant instruction_size  : integer := 32;
  constant word_size         : integer := 32;
  constant addr_size         : integer := 5;
  constant radix_size        : integer := 4;
  constant dram_addr_size    : integer := 12;
  constant iram_addr_size    : integer := 12;
  
  -- Control Unit constants
  constant op_size           : integer := 6;
  constant function_size     : integer := 11;
  constant control_word_size : integer := 32;
  constant opcode_up         : integer := 31;
  constant opcode_down       : integer := 26;
  constant r1_up             : integer := 25;
  constant r1_down           : integer := 21;
  constant r2_up             : integer := 20;
  constant r2_down           : integer := 16;
  constant r3_up             : integer := 15;
  constant r3_down           : integer := 11;
  constant inp2_up           : integer := 15;
  constant inp2_down         : integer := 0;
  constant func_up           : integer := 10;
  constant func_down         : integer := 0;
  
  -- Instruction set
  constant RTYPE   : std_logic_vector(op_size - 1 downto 0) :=  "000000";  -- (0x00)
  constant	J	      : std_logic_vector(op_size - 1 downto 0) :=  "000010";		-- (0x02)
  constant	J_JAL	  : std_logic_vector(op_size - 1 downto 0) :=  "000011";		-- (0x03)
  constant	J_BEQZ	 : std_logic_vector(op_size - 1 downto 0) :=  "000100";		-- (0x04)
  constant	J_BNEZ	 : std_logic_vector(op_size - 1 downto 0) :=  "000101";		-- (0x05) 
  constant	I_ADDI		: std_logic_vector(op_size - 1 downto 0) :=  "001000";		-- (0x08)
  constant	I_ADDUI : std_logic_vector(op_size - 1 downto 0) :=  "001001";		-- (0x09)
  constant	I_SUBI		: std_logic_vector(op_size - 1 downto 0) :=  "001010";		-- (0x0A)
  constant	I_SUBUI	: std_logic_vector(op_size - 1 downto 0) :=  "001011";		-- (0x0B)
  constant	I_ANDI		: std_logic_vector(op_size - 1 downto 0) :=  "001100";		-- (0x0C)
  constant	I_ORI		 : std_logic_vector(op_size - 1 downto 0) :=  "001101";		-- (0x0D)
  constant	I_XORI		: std_logic_vector(op_size - 1 downto 0) :=  "001110";		-- (0x0E)
  constant	I_LHI	 	: std_logic_vector(op_size - 1 downto 0) :=  "001111";		-- (0x0F)
  constant	J_JR    : std_logic_vector(op_size - 1 downto 0) :=  "010010";		-- (0x12)
  constant	J_JALR	 : std_logic_vector(op_size - 1 downto 0) :=  "010011";		-- (0x13)
  constant	I_SLLI		: std_logic_vector(op_size - 1 downto 0) :=  "010100";		-- (0x14)
  constant	NOP	    : std_logic_vector(op_size - 1 downto 0) :=  "010101";		-- (0x15)
  constant	I_SRLI		: std_logic_vector(op_size - 1 downto 0) :=  "010110";		-- (0x16)
  constant	I_SRAI		: std_logic_vector(op_size - 1 downto 0) :=  "010111";		-- (0x17)
  constant	I_SEQI		: std_logic_vector(op_size - 1 downto 0) :=  "011000";		-- (0x18)
  constant	I_SNEI		: std_logic_vector(op_size - 1 downto 0) :=  "011001";		-- (0x19)
  constant	I_SLTI		: std_logic_vector(op_size - 1 downto 0) :=  "011010";		-- (0x1A)
  constant	I_SGTI		: std_logic_vector(op_size - 1 downto 0) :=  "011011";		-- (0x1B)
  constant	I_SLEI		: std_logic_vector(op_size - 1 downto 0) :=  "011100";		-- (0x1C)
  constant	I_SGEI		: std_logic_vector(op_size - 1 downto 0) :=  "011101";		-- (0x1D)
  constant	I_LB    : std_logic_vector(op_size - 1 downto 0) :=  "100000";		-- (0x20)
  constant	I_LH    : std_logic_vector(op_size - 1 downto 0) :=  "100001";		-- (0x21)
  constant	I_LW    : std_logic_vector(op_size - 1 downto 0) :=  "100011";		-- (0x23)
  constant	I_LBU   : std_logic_vector(op_size - 1 downto 0) :=  "100100";		-- (0x24)
  constant	I_LHU   : std_logic_vector(op_size - 1 downto 0) :=  "100101";		-- (0x25)
  constant	I_SB    : std_logic_vector(op_size - 1 downto 0) :=  "101000";		-- (0x28)
  constant	I_SH    : std_logic_vector(op_size - 1 downto 0) :=  "101001";		-- (0x29)
  constant	I_SW    : std_logic_vector(op_size - 1 downto 0) :=  "101011";		-- (0x2B)
  constant	I_SLTUI	: std_logic_vector(op_size - 1 downto 0) :=  "111010";		-- (0x3A)
  constant	I_SGTUI	: std_logic_vector(op_size - 1 downto 0) :=  "111011";		-- (0x3B)
  constant	I_SLEUI	: std_logic_vector(op_size - 1 downto 0) :=  "111100";		-- (0x3C)
  constant	I_SGEUI	: std_logic_vector(op_size - 1 downto 0) :=  "111101";		-- (0x3D)

  -- R-Type instruction -> FUNC field
  constant	R_SLL   : std_logic_vector(function_size - 1 downto 0) :=  "00000000100";	-- (0x04) 
  constant	R_SRL   : std_logic_vector(function_size - 1 downto 0) :=  "00000000110";	-- (0x06) 
  constant	R_SRA   : std_logic_vector(function_size - 1 downto 0) :=  "00000000111";	-- (0x07)
  constant	R_MULT  : std_logic_vector(function_size - 1 downto 0) :=  "00000001110";	-- (0x0E) 
  constant	R_ADD   : std_logic_vector(function_size - 1 downto 0) :=  "00000100000";	-- (0x20) 
  constant	R_ADDU  : std_logic_vector(function_size - 1 downto 0) :=  "00000100001";	-- (0x21) 
  constant	R_SUB   : std_logic_vector(function_size - 1 downto 0) :=  "00000100010";	-- (0x22) 
  constant	R_SUBU  : std_logic_vector(function_size - 1 downto 0) :=  "00000100011";	-- (0x23)
  constant	R_AND   : std_logic_vector(function_size - 1 downto 0) :=  "00000100100";	-- (0x24)
  constant	R_OR    : std_logic_vector(function_size - 1 downto 0) :=  "00000100101";	-- (0x25)
  constant	R_XOR   : std_logic_vector(function_size - 1 downto 0) :=  "00000100110";	-- (0x26)
  constant	R_SEQ   : std_logic_vector(function_size - 1 downto 0) :=  "00000101000";	-- (0x28)
  constant	R_SNE   : std_logic_vector(function_size - 1 downto 0) :=  "00000101001";	-- (0x29)
  constant	R_SLT   : std_logic_vector(function_size - 1 downto 0) :=  "00000101010";	-- (0x2A)
  constant	R_SGT   : std_logic_vector(function_size - 1 downto 0) :=  "00000101011";	-- (0x2B)
  constant	R_SLE   : std_logic_vector(function_size - 1 downto 0) :=  "00000101100";	-- (0x2C)
  constant	R_SGE   : std_logic_vector(function_size - 1 downto 0) :=  "00000101101";	-- (0x2D)
  constant	R_SLTU  : std_logic_vector(function_size - 1 downto 0) :=  "00000111010";	-- (0x3A)
  constant	R_SGTU  : std_logic_vector(function_size - 1 downto 0) :=  "00000111011";	-- (0x3B)
  constant	R_SLEU  : std_logic_vector(function_size - 1 downto 0) :=  "00000111100";	-- (0x3C)
  constant	R_SGEU  : std_logic_vector(function_size - 1 downto 0) :=  "00000111101";	-- (0x3D)

  -- Types
  type aluOp is (nopOp, addOp, subOp, andOp, orOp, xorOp, sllOp, srlOp, sraOp, multOp, lhiOp,
                 gtOp,  geOp,  ltOp,  leOp,  eqOp, neOp,  gtUOp, geUOp, ltUOp, leUOp);
  
end package;

package body GLOBALS is
	function divide (n:integer; m:integer) return integer is
	begin
		if (n mod m) = 0 then
			return n/m;
		else
			return (n/m) + 1;
		end if;
	end divide;
	function log2 (n:integer) return integer is
	begin
		if n <=2 then
			return 1;
		else
			return 1 + log2(divide(n,2));
		end if;
	end log2;	
end package body;
