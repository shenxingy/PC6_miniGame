nop

#initialization
addi $6, $0, 624           # r6 is upper limit for spaceshipx
addi $7, $0, 100000    # r7 is upper limit for move counter 
addi $4, $0, 320           # r4 = 320 (r4 is spaceshipx)
addi $5, $0, 0               # r5 = 0 (r5 is movecouter)
bne $3, $0, -3              # reset spaceshipx and movecouter and don't do anything else if gamestatus is 1
blt $5, $7, 5                 # don't move and skip to normal routine if r5<r7
addi $5, $0, 0              # r5 = 0 if r5 reached upperlimit
blt $4, $0, 1                 # skip leftward move attempt if r4 < 0
sub $4, $4, $1             # Attempt move left by: spaceshipx=spaceshipx-moveleft
blt $6, $4, 1                 # skip rightward move attempt if r4 > r6
add $4, $4, $2             # Attempt move right by: spaceshipx=spaceshipx+moveright

# normal routine
addi $5, $5, 1    #increment counter
j 5    # go back to the gamestatus check line


