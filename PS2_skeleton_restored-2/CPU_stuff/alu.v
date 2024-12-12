module alu(
    input signed [31:0] data_operandA, data_operandB,
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt,
    output reg [31:0] data_result,
    output reg isNotEqual, isLessThan, overflow
);

    always @(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt) begin
        // Default values to prevent latches
        data_result = 32'b0;
        isNotEqual = 1'b0;
        isLessThan = 1'b0;
        overflow = 1'b0;

        case (ctrl_ALUopcode)
            5'b00000: begin
                data_result = data_operandA + data_operandB;
                overflow = (data_operandA[31] && data_operandB[31] && !data_result[31]) ||
                           (!data_operandA[31] && !data_operandB[31] && data_result[31]);
            end
            5'b00001: begin
                data_result = data_operandA - data_operandB;
                overflow = (data_operandA[31] != data_operandB[31]) && (data_operandA[31] != data_result[31]);
            end
            5'b00010: data_result = data_operandA & data_operandB;
            5'b00011: data_result = data_operandA | data_operandB;
            5'b00100: data_result = data_operandA << ctrl_shiftamt;
            5'b00101: data_result = data_operandA >>> ctrl_shiftamt;
            default: data_result = 32'b0;  // Default case
        endcase
        
        isNotEqual = (data_operandA != data_operandB);
        isLessThan = (data_operandA < data_operandB);
    end
endmodule
