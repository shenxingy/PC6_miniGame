module control(opcode, Rwe, Rdst, ALUinB, ALUop_ctl, DMWe, Rwd, JP, BR, is_R, is_addi, is_sw, is_lw, is_j, is_bne, is_jal, is_jr, is_blt, is_bex, is_setx);
    input [4:0] opcode;
    output Rwe, Rdst, ALUinB, ALUop_ctl, DMWe, Rwd, JP, BR, is_R, is_addi, is_sw, is_lw, is_j, is_bne, is_jal, is_jr, is_blt, is_bex, is_setx;
    
    // R: 00000
    assign is_R = (~opcode[4]) & (~opcode[3]) & (~opcode[2]) & (~opcode[1]) & (~opcode[0]);
    // addi: 00101
    assign is_addi = (~opcode[4]) & (~opcode[3]) & (opcode[2]) & (~opcode[1]) & (opcode[0]);
    // sw: 00111
    assign is_sw = (~opcode[4]) & (~opcode[3]) & (opcode[2]) & (opcode[1]) & (opcode[0]);
    // lw: 01000
    assign is_lw = (~opcode[4]) & (opcode[3]) & (~opcode[2]) & (~opcode[1]) & (~opcode[0]);

    // j: 00001
    assign is_j = (~opcode[4]) & (~opcode[3]) & (~opcode[2]) & (~opcode[1]) & (opcode[0]);
    // bne: 00010
    assign is_bne = (~opcode[4]) & (~opcode[3]) & (~opcode[2]) & (opcode[1]) & (~opcode[0]);
    // jal: 00011
    assign is_jal = (~opcode[4]) & (~opcode[3]) & (~opcode[2]) & (opcode[1]) & (opcode[0]);
    // jr: 00100
    assign is_jr = (~opcode[4]) & (~opcode[3]) & (opcode[2]) & (~opcode[1]) & (~opcode[0]);
    // blt: 00110
    assign is_blt = (~opcode[4]) & (~opcode[3]) & (opcode[2]) & (opcode[1]) & (~opcode[0]);
    // bex: 10110
    assign is_bex = (opcode[4]) & (~opcode[3]) & (opcode[2]) & (opcode[1]) & (~opcode[0]);
    // setx: 10101
    assign is_setx = (opcode[4]) & (~opcode[3]) & (opcode[2]) & (~opcode[1]) & (opcode[0]);


    // Control signals
    assign JP = is_j | is_jal | is_jr | is_bex;
    assign BR = is_bne | is_blt; // Branching is not used for J-type instructions
    assign Rwe = is_R | is_addi | is_lw | is_jal | is_setx; // Include jal and setx
    assign Rdst = is_R | is_jal; // Write to $ra for jal
    assign ALUinB = is_addi | is_lw | is_sw;
    assign ALUop_ctl = 1'b0; // Not used for J-type
    assign DMWe = is_sw;
    assign Rwd = is_lw;
    
endmodule
