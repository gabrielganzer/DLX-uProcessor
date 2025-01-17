----------------------------------------------------------------------------------
-- Engineer: GANZER Gabriel
-- Company: Politecnico di Torino
-- Design units: DLX_DP
-- Function: DLX data-path
-- Input:
-- Output:
-- Architecture: structural
-- Library/package: ieee.std_logic_ll64, work.globals
-- Date: 12/08/2020
----------------------------------------------------------------------------------
library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.globals.all;

entity DLX_DP is
  generic (WIDTH     : integer := word_size;
           LENGTH    : integer := addr_size;
           RADIX     : integer := radix_size;
           OPCODE    : integer:= op_size
  );
  port (CLK              : in  std_logic;  -- Clock
        RST              : in  std_logic;  -- Synchronous reset, active-low
        -- Control signals
        IF_EN            : in std_logic;
        ID_EN            : in std_logic;
        RF_LATCH_EN      : in std_logic;
        RF_RD1           : in std_logic;
        RF_RD2           : in std_logic;
        SIGN_EN          : in std_logic;
        IMM_SEL          : in std_logic;
        RegImm_LATCH_EN  : in std_logic;
        RegRD1_LATCH_EN  : in std_logic;
        EX_EN            : in std_logic;
        MuxA_SEL         : in std_logic;
        MuxB_SEL         : in std_logic;
        ALU_OPCODE       : in aluOp;
        JUMP_EN          : in std_logic;
        JUMP_EQ          : in std_logic;
        JUMP_REG         : in std_logic;
        JUMP_LINK        : in std_logic;
        RegME_LATCH_EN   : in std_logic;
        RegRD2_LATCH_EN  : in std_logic;
        RF_WE_EX         : in std_logic;
        MEM_EN           : in std_logic;
        STORE_SIZE       : in std_logic_vector(2 downto 0);
        SIGN_LD          : in std_logic;
        LOAD_SIZE        : in std_logic_vector(2 downto 0);
        RegALU2_LATCH_EN : in std_logic;
        RegLMD_LATCH_EN  : in std_logic;
        RegRD3_LATCH_EN  : in std_logic;
        RF_WE_MEM        : in std_logic;
        WB_EN            : in std_logic;
        MuxWB_SEL        : in std_logic;
        RF_WE            : in std_logic;
        FLUSH            : in std_logic;
        -- Data bus
        PC_OUT           : in std_logic_vector(WIDTH-1 downto 0);
        IR_OUT           : in std_logic_vector(WIDTH-1 downto 0);
        DRAM_OUT         : in std_logic_vector(WIDTH-1 downto 0);
        PC_IN            : out std_logic_vector(WIDTH-1 downto 0);
        DRAM_ADDR        : out std_logic_vector(dram_addr_size-1 downto 0);
        DRAM_IN          : out std_logic_vector(WIDTH-1 downto 0)
  );
end entity;

architecture STRUCTURAL of DLX_DP is
  
  --------------------------------------------------------------------
  -- Components
  --------------------------------------------------------------------
  component MUX21_GENERIC
    generic(NBIT: integer:= 4);
    port (S0:	in	std_logic_vector(NBIT-1 downto 0);
          S1:	in 	std_logic_vector(NBIT-1 downto 0);
          SEL:	in	std_logic;
          Y:	out	std_logic_vector(NBIT-1 downto 0));
  end component;

  
  -- Multiplexer 3x1
  component MUX31_GENERIC
    generic(NBIT: integer:= 4);
    port (S0:	in 	std_logic_vector(NBIT-1 downto 0);
          S1:	in 	std_logic_vector(NBIT-1 downto 0);
          S2:	in	std_logic_vector(NBIT-1 downto 0);
          SEL:	in	std_logic_vector(2 downto 0);
          Y:	out	std_logic_vector(NBIT-1 downto 0));
  end component;

  -- Register
  component REGISTER_GENERIC
    generic (WIDTH: integer := 32);
    port (CLK  : in std_logic;
          RST  : in std_logic;
          EN   : in std_logic;
          DIN  : in std_logic_vector(WIDTH-1 downto 0);    
          DOUT : out std_logic_vector(WIDTH-1 downto 0));
  end component;
  
  -- D-Type Flip-Flop
  component FFD
    port (CLK : in std_logic;
          RST : in std_logic;  -- Synchronous reset, active-low
          EN  : in std_logic;  -- Active-high enable
          D   : in std_logic;    
          Q   : out std_logic);
  end component;
  
  -- Register file
  component REGISTER_FILE
    generic (
      WIDTH: integer:= word_size;
      LENGTH: integer:= addr_size);
    port (CLK     :IN std_logic;
          RST     :IN std_logic;
          EN      :IN std_logic;
          RD1     :IN std_logic;
          RD2     :IN std_logic;
          WR      :IN std_logic;
          DATAIN  :IN std_logic_vector(WIDTH-1 downto 0);
          OUT1    :OUT std_logic_vector(WIDTH-1 downto 0);
          OUT2    :OUT std_logic_vector(WIDTH-1 downto 0);
          ADD_WR  :IN std_logic_vector(LENGTH-1 downto 0);
          ADD_RD1 :IN std_logic_vector(LENGTH-1 downto 0);
          ADD_RD2 :IN std_logic_vector(LENGTH-1 downto 0));
  end component;
  
  -- Sign Extend
  component SIGN_EXTEND
    generic (WIDTH_IN: integer := word_size/2;
             WIDTH_OUT: integer := word_size);
    port (A: in std_logic_vector(WIDTH_IN-1 downto 0);
          S: in std_logic;
          Y: out std_logic_vector (WIDTH_OUT-1 downto 0));
  end component;

  -- Arithmetic Logic Unit
  component ALU
    generic (WIDTH: integer:= word_size;
             RADIX: integer:= radix_size;
             OPCODE: integer:= op_size);
    port (A  :  in	std_logic_vector(WIDTH-1 downto 0);
          B  :  in	std_logic_vector(WIDTH-1 downto 0);
          OP :  in	aluOp;                             
          Y  :  out	std_logic_vector(WIDTH-1 downto 0));
  end component;
  
  -- Zero Detector
  component ZERO_DETECTOR
    generic (WIDTH : integer:= word_size);
    port (A : in  std_logic_vector(WIDTH-1 downto 0);
          Y : out std_logic);
  end component;
  
  -- Branch Condition
  component BRANCH_UNIT
    port(ENABLE	   : in std_logic;
	 Z         : in std_logic;
         JUMP_EN   : in std_logic;
         JUMP_EQ   : in std_logic;
         JUMP_REG  : in std_logic;
         JUMP_LINK : in std_logic;
         BRANCH    : out std_logic);
  end component;
  
  -- Forwarding Control Unit
  component FORWARDING_UNIT
    generic (LENGTH : integer := 5);
    port (RS1       : in std_logic_vector(LENGTH - 1 downto 0);
          RS2       : in std_logic_vector(LENGTH - 1 downto 0);
          RD_EX     : in std_logic_vector(LENGTH - 1 downto 0);
          RD_MEM    : in std_logic_vector(LENGTH - 1 downto 0);
          RF_WE_EX  : in std_logic;
          RF_WE_MEM : in std_logic;
          ForwardA  : out std_logic_vector (2 downto 0);
          ForwardB  : out std_logic_vector (2 downto 0);
          ForwardC  : out std_logic_vector (2 downto 0);
          ForwardD  : out std_logic);
  end component;
  
  --------------------------------------------------------------------
  -- Signals
  --------------------------------------------------------------------
  signal OUTCOME     : std_logic;
  signal COND        : std_logic;
  signal LINK_EN     : std_logic;
  signal REG_EN      : std_logic;
  signal BRANCH_EN   : std_logic;
  signal JL1         : std_logic;
  signal JL2         : std_logic;
  signal JREG        : std_logic;
  signal RF_EN       : std_logic;
  signal FwdD        : std_logic;
  signal RegFwdD     : std_logic;
  signal Z_out       : std_logic;
  signal FWD_EN      : std_logic;
  signal WORD        : std_logic_vector(1 downto 0);
  signal FwdA        : std_logic_vector(2 downto 0);
  signal FwdB        : std_logic_vector(2 downto 0);
  signal FwdC        : std_logic_vector(2 downto 0);
  signal RegFWDA     : std_logic_vector(2 downto 0);
  signal RegFWDB     : std_logic_vector(2 downto 0);
  signal RegFWDC     : std_logic_vector(2 downto 0);
  signal NPC         : std_logic_vector(WIDTH-1 downto 0);
  signal MuxNPC_out  : std_logic_vector(WIDTH-1 downto 0);
  signal NPC1        : std_logic_vector(WIDTH-1 downto 0);
  signal NPC2        : std_logic_vector(WIDTH-1 downto 0);
  signal NPC3        : std_logic_vector(WIDTH-1 downto 0);
  signal NPC_out     : std_logic_vector(WIDTH-1 downto 0);
  signal MuxWB_out   : std_logic_vector(WIDTH-1 downto 0);
  signal RetADDR     : std_logic_vector(WIDTH-1 downto 0);
  signal RF_DATA     : std_logic_vector(WIDTH-1 downto 0);
  signal RegA_in     : std_logic_vector(WIDTH-1 downto 0);
  signal RegB_in     : std_logic_vector(WIDTH-1 downto 0);
  signal RegA_out    : std_logic_vector(WIDTH-1 downto 0);
  signal RegB_out    : std_logic_vector(WIDTH-1 downto 0);
  signal IMM16ext    : std_logic_vector(WIDTH-1 downto 0);
  signal IMM26ext    : std_logic_vector(WIDTH-1 downto 0);
  signal RegIMM_in   : std_logic_vector(WIDTH-1 downto 0);
  signal RegIMM_out  : std_logic_vector(WIDTH-1 downto 0);
  signal MuxA_out    : std_logic_vector(WIDTH-1 downto 0);
  signal MuxB_out    : std_logic_vector(WIDTH-1 downto 0);
  signal A           : std_logic_vector(WIDTH-1 downto 0);
  signal B           : std_logic_vector(WIDTH-1 downto 0);
  signal RES         : std_logic_vector(WIDTH-1 downto 0);
  signal Z_in        : std_logic_vector(WIDTH-1 downto 0);
  signal RegALU1_out : std_logic_vector(WIDTH-1 downto 0);
  signal RegME_out   : std_logic_vector(WIDTH-1 downto 0);
  signal RegA1_out   : std_logic_vector(WIDTH-1 downto 0);
  signal MuxJR_out   : std_logic_vector(WIDTH-1 downto 0);
  signal STORE8      : std_logic_vector(WIDTH-1 downto 0);
  signal STORE16     : std_logic_vector(WIDTH-1 downto 0);
  signal STORE32     : std_logic_vector(WIDTH-1 downto 0);
  signal LOAD8       : std_logic_vector(WIDTH-1 downto 0);
  signal LOAD16      : std_logic_vector(WIDTH-1 downto 0);
  signal LOAD32      : std_logic_vector(WIDTH-1 downto 0);
  signal MuxLOAD_out : std_logic_vector(WIDTH-1 downto 0);
  signal RegLMD_out  : std_logic_vector(WIDTH-1 downto 0);
  signal RegALU2_out : std_logic_vector(WIDTH-1 downto 0);
  signal RF_ADDR     : std_logic_vector(LENGTH-1 downto 0);
  signal RD          : std_logic_vector(LENGTH-1 downto 0);
  signal RD1         : std_logic_vector(LENGTH-1 downto 0);
  signal RD2         : std_logic_vector(LENGTH-1 downto 0);
  signal RD3         : std_logic_vector(LENGTH-1 downto 0);
  signal RS1         : std_logic_vector(LENGTH-1 downto 0);
  signal RS2         : std_logic_vector(LENGTH-1 downto 0);
  signal IMM16       : std_logic_vector((WIDTH/2)-1 downto 0);
  signal DATAST16    : std_logic_vector((WIDTH/2)-1 downto 0);
  signal DATAST8     : std_logic_vector((WIDTH/4)-1 downto 0);
  signal DATALD16    : std_logic_vector((WIDTH/2)-1 downto 0);
  signal DATALD8     : std_logic_vector((WIDTH/4)-1 downto 0);
  signal IMM26       : std_logic_vector(WIDTH-OPCODE-1 downto 0);
  
begin
  
  -------------------------------------------------------------------------------
  --                                  Stage 1                                  --
  -------------------------------------------------------------------------------
  
  -- Nex Program Counter Increment
  NPC <= std_logic_vector(unsigned(PC_OUT) + 1);
  
  -- Mux NPC
  MuxNPC: MUX21_GENERIC
    generic map(WIDTH)
    port map(NPC, MuxJR_out, OUTCOME, MuxNPC_out);
  
  PC_IN <= MuxNPC_out;
  
  -- Next Program Counter
  RegNPC: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, IF_EN, MuxNPC_out, NPC1);

  -------------------------------------------------------------------------------
  --                                  Stage 2                                  --
  -------------------------------------------------------------------------------
  
  RD      <= IR_OUT(r3_up downto r3_down) when (IR_OUT(opcode_up downto opcode_down) = RTYPE)   else
             IR_OUT(r2_up downto r2_down);            
  RS1     <= IR_OUT(r1_up downto r1_down); 
  RS2     <= IR_OUT(r2_up downto r2_down);
  IMM16   <= IR_OUT(inp2_up downto inp2_down);
  IMM26   <= IR_OUT(opcode_down-1 downto 0);
  
  RF_EN   <= RF_LATCH_EN or WB_EN;
  
  -- Mux Register File Data-in
  MuxRFDATA: MUX21_GENERIC
    generic map(WIDTH)
    port map(MuxWB_out, NPC_out, JL2, RF_DATA);
  
  -- Mux Register File Address-write
  MuxRFADDR: MUX21_GENERIC
    generic map(LENGTH)
    port map(RD3, (others => '1'), JL2, RF_ADDR);
  
  -- Register file
  RF0: REGISTER_FILE
    generic map(WIDTH, LENGTH)
    port map(CLK, RST, RF_EN, RF_RD1, RF_RD2, RF_WE, RF_DATA, RegA_in, RegB_in, RF_ADDR, RS1, RS2);
      
  -- Sign Extend IMM16
  SignExtIMM16: SIGN_EXTEND
    generic map (word_size/2, word_size)
    port map (IMM16, SIGN_EN, IMM16ext);

  -- Sign Extend IMM26
  SignExtIMM26: SIGN_EXTEND
    generic map (word_size-op_size, word_size)
    port map (IMM26, '1', IMM26ext);
      
  -- Mux Immediate
  MuxIMM: MUX21_GENERIC
    generic map(WIDTH)
    port map(IMM16ext, IMM26ext, IMM_SEL, RegIMM_in);
  
  -- Pipeline Register NPC
  RegNPC1: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, ID_EN, NPC1, NPC2);
  
  -- Pipeline Register A
  RegA: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, RF_RD1, RegA_in, RegA_out);
      
  -- Pipeline Register B
  RegB: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, RF_RD2, RegB_in, RegB_out);
      
  -- Pipeline Register IMM
  RegIMM: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, RegIMM_LATCH_EN, RegIMM_in, RegIMM_out);
      
  -- Pipeline Register RD1
  RegRD1: REGISTER_GENERIC
    generic map(LENGTH)
    port map(CLK, RST, RegRD1_LATCH_EN, RD, RD1);
  
  -------------------------------------------------------------------------------
  --                                  Stage 3                                  --
  ------------------------------------------------------------------------------- 
  
  LINK_EN   <= JUMP_LINK or FLUSH;
  BRANCH_EN <= JUMP_EN or FLUSH;
  REG_EN    <= JUMP_REG or FLUSH; 
  
  -- Mux Operand A
  MuxA: MUX21_GENERIC
    generic map(WIDTH)
    port map(NPC2, RegA_out, MuxA_SEL, MuxA_out);
  
  -- Mux Operand B
  MuxB: MUX21_GENERIC
    generic map(WIDTH)
    port map(RegB_out, RegIMM_out, MuxB_SEL, MuxB_out);
      
  -- Mux Forwarding A
  MuxFWDA: MUX31_GENERIC
    generic map(WIDTH)
    port map(MuxA_out, MuxWB_out, RegALU1_out, FwdA, A);
  
  -- Mux Forwarding B
  MuxFWDB: MUX31_GENERIC
    generic map(WIDTH)
    port map(MuxB_out, MuxWB_out, RegALU1_out, FwdB, B);
      
  -- Mux Forwarding C
  MuxFWDC: MUX31_GENERIC
    generic map(WIDTH)
    port map(RegA_out, MuxWB_out, RegALU1_out, FwdC, Z_in);
      
  -- Arithmetic Logic Unit
  ALU0: ALU
    generic map(WIDTH, RADIX, OPCODE)
    port map(A, B, ALU_OPCODE, RES);
  
  -- Zero?
  ZERO: ZERO_DETECTOR
    generic map(WIDTH)
    port map(Z_in, Z_out);
  
  -- Branch Condition
  BU0: BRANCH_UNIT
    port map(FLUSH, Z_out, JUMP_EN, JUMP_EQ, JUMP_REG, JUMP_LINK, COND);
      
  -- Pipeline Register Operand A
  RegA1: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, REG_EN, Z_in, RegA1_out);
  
  -- Pipeline Outcome
  FFDBRANCH: FFD
    port map(CLK, RST, BRANCH_EN, COND, OUTCOME);
      
  -- Pipeline Jump&Link
  FFDJL1: FFD
    port map(CLK, RST, LINK_EN, JUMP_LINK, JL1);
  
  -- Pipeline Jump&Link
  FFDJREG: FFD
    port map(CLK, RST, REG_EN, JUMP_REG, JREG);
      
  -- Pipeline Register NPC
  RegNPC2: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, JUMP_LINK, NPC2, NPC3);
      
  -- Pipeline Register ALU1
  RegALU1: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, EX_EN, RES, RegALU1_out);
      
  -- Pipeline Register ME
  RegME: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, RegME_LATCH_EN, RegB_out, RegME_out);
      
  -- Pipeline Register RD2
  RegRD2: REGISTER_GENERIC
    generic map(LENGTH)
    port map(CLK, RST, RegRD2_LATCH_EN, RD1, RD2);
      
  -------------------------------------------------------------------------------
  --                                  Stage 4                                  --
  -------------------------------------------------------------------------------

  -- Mux Jump Register
  MuxJR: MUX21_GENERIC
    generic map(WIDTH)
    port map(RegALU1_out, RegA1_out, JREG, MuxJR_out);
      
  -- Mux Cache Source
  MuxMEM: MUX21_GENERIC
    generic map(WIDTH)
    port map(RegME_out, MuxWB_out, FwdD, STORE32);
      
  DATAST16 <= STORE32((word_size/2)-1 downto 0);
  
  DATAST8 <= STORE32((word_size/4)-1 downto 0);
  
  SignExtSH: SIGN_EXTEND
    generic map (word_size/2, word_size)
    port map (DATAST16, '1', STORE16);
  
  -- Sign Extend Store
  SignExtSB: SIGN_EXTEND
    generic map (word_size/4, word_size)
    port map (DATAST8, '1', STORE8);
      
  -- Mux Store
  MuxSTORE: MUX31_GENERIC
    generic map(WIDTH)
    port map(STORE32, STORE16, STORE8, STORE_SIZE, DRAM_IN);
  
  DRAM_ADDR <= RegALU1_out(dram_addr_size-1 downto 0);
  
  DATALD16 <= DRAM_OUT((word_size/2)-1 downto 0);
  
  DATALD8 <= DRAM_OUT((word_size/4)-1 downto 0);
  
  -- Sign Extend Load
  SignExtLH: SIGN_EXTEND
    generic map (word_size/2, word_size)
    port map (DATALD16, SIGN_LD, LOAD16);
  
  -- Sign Extend Load
  SignExtLB: SIGN_EXTEND
    generic map (word_size/4, word_size)
    port map (DATALD8, SIGN_LD, LOAD8);
      
  -- Mux Load
  MuxLOAD: MUX31_GENERIC
    generic map(WIDTH)
    port map(DRAM_OUT, LOAD16, LOAD8, LOAD_SIZE, MuxLOAD_out);
  
  -- Pipeline Register LMD
  RegALU2: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, RegALU2_LATCH_EN, RegALU1_out, RegALU2_out); 
    
  -- Pipeline Register LMD
  RegLMD: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, RegLMD_LATCH_EN, MuxLOAD_out, RegLMD_out);   
      
  -- Pipeline Register RD3
  RegRD3: REGISTER_GENERIC
    generic map(LENGTH)
    port map(CLK, RST, RegRD3_LATCH_EN, RD2, RD3);
      
  -- Pipeline Jump&Link
  FFDJL2: FFD
    port map(CLK, RST, LINK_EN, JL1, JL2);
  
  -- Pipeline Register NPC
  RegNPC3: REGISTER_GENERIC
    generic map(WIDTH)
    port map(CLK, RST, JL1, NPC3, NPC_out);
      
  -------------------------------------------------------------------------------
  --                                  Stage 5                                  --
  -------------------------------------------------------------------------------
  
  -- Mux Write-Back
  MuxWB: MUX21_GENERIC
    generic map(WIDTH)
    port map(RegALU2_out, RegLMD_out, MuxWB_SEL, MuxWB_out);
  
  -- Forwarding Control Unit
  FU0: FORWARDING_UNIT
    generic map(LENGTH)
    port map(RS1, RS2, RD1, RD2, RF_WE_EX, RF_WE_MEM, regFWDA, regFWDB, regFWDC, regFWDD);  
      
  -- Pipeline Register NPC
  RegFA: REGISTER_GENERIC
    generic map(3)
    port map(CLK, RST, ID_EN, RegFWDA, FwdA);
      
  -- Pipeline Register NPC
  RegFB: REGISTER_GENERIC
    generic map(3)
    port map(CLK, RST, ID_EN, RegFWDB, FwdB);
      
  -- Pipeline Register NPC
  RegFC: REGISTER_GENERIC
    generic map(3)
    port map(CLK, RST, ID_EN, RegFWDC, FwdC);
  
  -- Pipeline Jump&Link
  FFDFD: FFD
    port map(CLK, RST, ID_EN, RegFWDD, FwdD);

end architecture;


