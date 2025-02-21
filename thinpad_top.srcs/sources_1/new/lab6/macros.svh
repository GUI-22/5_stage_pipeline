`default_nettype none
`define PC_ENTER_ADDR 32'h80000000
`define PC_NOP_ADDR 32'h80000000
`define INSTR_NOP 32'h00000013

`define DATA_WIDTH 32                    // width of data bus in bits (8, 16, 32, or 64)
`define ADDR_WIDTH 32                    // width of address bus in bits
`define INSTR_WIDTH 32
`define INSTR_REPR_WIDTH 6
`define ALU_OPERATOR_WIDTH 5
`define SELECT_WIDTH 4
`define REG_NUM_WIDTH 5
`define SELECT_WIDTH 4

`define ZERO_EXT 0
`define SIGN_EXT 1

`define MUX_A_CHOICE_RF_DATA_A 0
`define MUX_A_CHOICE_PC 1

`define MUX_B_CHOICE_RF_DATA_B 0
`define MUX_B_CHOICE_IMM 1

`define INSTR_ADD 0
`define INSTR_ADDI 1
`define INSTR_ANDI 2
`define INSTR_LB 3
`define INSTR_SB 4
`define INSTR_SW 5
`define INSTR_LUI 6
`define INSTR_BEQ 7
`define INSTR_AND 8
`define INSTR_AUIPC 9
`define INSTR_BNE 10
`define INSTR_JAL 11
`define INSTR_JALR 12
`define INSTR_OR 13
`define INSTR_ORI 14
`define INSTR_SLLI 15
`define INSTR_SRLI 16
`define INSTR_XOR 17
`define INSTR_LW 18

// our custom instructions
`define INSTR_MIN 18
`define INSTR_SBSET 19
`define INSTR_ANDN 20

`define ALU_ADD 0
`define ALU_SUB 1
`define ALU_AND 2
`define ALU_OR 3
`define ALU_XOR 4
`define ALU_NOT 5
`define ALU_SLL 6
`define ALU_SRL 7
`define ALU_JAL 8
`define ALU_MIN 9
`define ALU_SBSET 10
`define ALU_ANDN 11

`define MUX_MEM_CHOICE_DM 0
`define MUX_MEM_CHOICE_ALU_SRT 1