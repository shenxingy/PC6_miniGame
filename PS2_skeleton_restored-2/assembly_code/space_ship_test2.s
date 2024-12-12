nop

#initialization
addi $6, $0, 624           # r6 is upper limit for spaceshipx
addi $7, $0, 5000000    # r7 is upper limit for move counter 
addi $4, $0, 320           # r4 = 320 (r4 is spaceshipx)
addi $5, $0, 0               # r5 = 0 (r5 is movecouter)
nop
blt $5, $7, 3                 # don't move and skip to normal routine if r5<r7
addi $5, $0, 0
add $4, $4, $2             # Attempt move right
sub $4, $4, $1             # Attempt move left

# normal routine
addi $5, $5, 1    #increment counter
j 5    # go back to the second nop


