    addi x1, zero, 10      # x1 = 10
    addi x2, zero, 20      # x2 = 20
    addi x3, zero, 30      # x3 = 30
    lui t0, 0x80000
    sw x1, 0x100(t0)     # Store x1 at address 0x80000100
    lw x4, 0x100(t0)     # Load from address 0 to x4
    
    or x5, x1, x2        # x5 = x1 | x2
    ori x6, x1, 15       # x6 = x1 | 15
    
    slli x7, x1, 2       # x7 = x1 << 2
    srli x8, x2, 1       # x8 = x2 >> 1
    
    xor x9, x1, x3       # x9 = x1 ^ x3

CHECK:
    bne x1, x2, LABEL    # if x1 != x2, jump to LABEL
    addi x10, zero, 3    # x10 = 3 (this should be skipped if bne is taken)
LOOP:
    auipc x13, 0x0       # x13 = pc + 0, which is 0x80000034
    jal x14, LOOP          # x14 = pc + 4, which is 0x8000003c
LABEL:
    lui x11, 0x80000      # x11 = BaseRAM
    jalr x12, x11, 0x34   # Jump to address in x12

# Verification:
# x4 should be 10 (value loaded from memory)
# x5 should be 30 (10 | 20)
# x6 should be 15 (10 | 15)
# x7 should be 40 (10 << 2)
# x8 should be 10 (20 >> 1)
# x9 should be 20 (10 ^ 30)
# x10 should be 0
# x11 should be the address of the next instruction after jalr
# x12 should be 0x80000044
# x13 should be 0x80000034
# x14 should be 0x8000003c
