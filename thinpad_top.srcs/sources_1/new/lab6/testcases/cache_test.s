# This file tests the inst cache module.
# we'll test the following:
# 1. inst cache entry substitution (there will be no loop and test the cache entry substitution)
# 2. fence.i instruction test
addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6

# 2. fence.i instruction test
fence.i

addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6
addi x1, x0, 7      # Initialize register x1 to 7

addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6
addi x1, x0, 7      # Initialize register x1 to 7

addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6
addi x1, x0, 7      # Initialize register x1 to 7

addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6
addi x1, x0, 7      # Initialize register x1 to 7

addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6
addi x1, x0, 7      # Initialize register x1 to 7

addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6
addi x1, x0, 7      # Initialize register x1 to 7

addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6
addi x1, x0, 7      # Initialize register x1 to 7

addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6
addi x1, x0, 7      # Initialize register x1 to 7

addi x1, x0, 0      # Initialize register x1 to 0
addi x1, x0, 1      # Initialize register x1 to 1
addi x1, x0, 2      # Initialize register x1 to 2
addi x1, x0, 3      # Initialize register x1 to 3
addi x1, x0, 4      # Initialize register x1 to 4
addi x1, x0, 5      # Initialize register x1 to 5
addi x1, x0, 6      # Initialize register x1 to 6
addi x1, x0, 7      # Initialize register x1 to 7