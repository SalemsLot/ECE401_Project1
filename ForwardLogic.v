`include "config.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:49:08 10/16/2013 
// Design Name: 
// Module Name:     ForwardLogic
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: //
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ForwardLogic( 
       input             CLK,
       input             RESET,
       input      [31:0] Instr,
       output reg [ 2:0] Fwd2ALU_opA_ctl,          //Forward to ALU operand A
       output reg [ 2:0] Fwd2ALU_opB_ctl,          //Forward to ALU operand B
       output reg [ 2:0] Fwd2ALU_MemWrite_ctl,     //Forward to ALU MemWriteData
       output reg [ 2:0] Fwd2Cmp_opA_ctl,          //Forward to branch compare opA or jump register
       output reg [ 2:0] Fwd2Cmp_opB_ctl,          //Forward to branch compare opB

       input             RegWrite,                 //This instruction writes to a register
       input             RegDest,                  //This instruction uses the RegDest register (Instr[15:11])
       input             MemWrite,                 //This instruction writes to memory
       input             Link

       );

       //Table To hold Destination Registers in [0] = PC-1Instr, [1] = PC-2Instr, [2] = PC-3Instr
       reg  [4:0] PipelineRegHistory [2:0];
       wire [4:0] CurrentDestReg;  
       wire [4:0] CurrentSrcRegrs;  
       wire [4:0] CurrentSrcRegrt;  
       wire [4:0] CurrentSrcRegMem;
     
       wire [2:0] Fwd2ALU_opA_ctl1;        // Forward to ALU operand A - First bit: Forward from MEM, Second bit: Forward from EXE
       wire [2:0] Fwd2ALU_opB_ctl1;        // Forward to ALU operand B - First bit: Forward from MEM, Second bit: Forward from EXE
       wire [2:0] Fwd2ALU_MemWrite_ctl1;   // Forward to ALU MemWriteData - First bit: Forward from MEM, Second bit: Forward from EXE
       //Calculate the destination register for the current instruction
       assign CurrentDestReg = (RegWrite) ?  (RegDest? Instr[15:11]:Instr[20:16]): 5'b0;

       //Calculate the source register for the current instruction 
       assign CurrentSrcRegrs = Instr[25:21]; 
       assign CurrentSrcRegrt = (RegDest)?Instr[20:16]:5'b0; 
       assign CurrentSrcRegMem = (MemWrite)?Instr[20:16]:5'b0;
       //assign CurrentSrcRegMem = (MemWrite || (RegWrite && !RegDest))?Instr[20:16]:5'b0;

       //We treat 'zero' entries as by-pass ignore for when there aren't any reg write
       // If the current destination register matches any value in the Pipeline History the we check the next condition, else we don't by-pass
       // In the case that both exe and mem phase has the same destination register, we pick the most recent, else we select the matching phase value
       assign Fwd2ALU_opA_ctl1[0] = (PipelineRegHistory[0] == 0 || Link) ? 1'b0 : (PipelineRegHistory[0] == CurrentSrcRegrs ) ? 1'b1 : 1'b0;
       assign Fwd2ALU_opA_ctl1[1] = (PipelineRegHistory[1] == 0 || Link) ? 1'b0 : (PipelineRegHistory[1] == CurrentSrcRegrs ) ? 1'b1 : 1'b0;
       assign Fwd2ALU_opA_ctl1[2] = (PipelineRegHistory[2] == 0 || Link) ? 1'b0 : (PipelineRegHistory[2] == CurrentSrcRegrs ) ? 1'b1 : 1'b0;
       
       assign Fwd2ALU_opB_ctl1[0] = (PipelineRegHistory[0] == 0) ? 1'b0 : (PipelineRegHistory[0] == CurrentSrcRegrt ) ? 1'b1 : 1'b0;
       assign Fwd2ALU_opB_ctl1[1] = (PipelineRegHistory[1] == 0) ? 1'b0 : (PipelineRegHistory[1] == CurrentSrcRegrt ) ? 1'b1 : 1'b0;
       assign Fwd2ALU_opB_ctl1[2] = (PipelineRegHistory[2] == 0) ? 1'b0 : (PipelineRegHistory[2] == CurrentSrcRegrt ) ? 1'b1 : 1'b0;
       
       assign Fwd2ALU_MemWrite_ctl1[0] = (PipelineRegHistory[0] == 0) ? 1'b0 : (PipelineRegHistory[0] == CurrentSrcRegMem ) ? 1'b1 : 1'b0;
       assign Fwd2ALU_MemWrite_ctl1[1] = (PipelineRegHistory[1] == 0) ? 1'b0 : (PipelineRegHistory[1] == CurrentSrcRegMem ) ? 1'b1 : 1'b0;
       assign Fwd2ALU_MemWrite_ctl1[2] = (PipelineRegHistory[2] == 0) ? 1'b0 : (PipelineRegHistory[2] == CurrentSrcRegMem ) ? 1'b1 : 1'b0;
       
       //Forwarding to the branch compare unit
       assign Fwd2Cmp_opA_ctl[0] = (PipelineRegHistory[0] == 0) ? 1'b0 : (PipelineRegHistory[0] == CurrentSrcRegrs ) ? 1'b1 : 1'b0;
       assign Fwd2Cmp_opA_ctl[1] = (PipelineRegHistory[1] == 0) ? 1'b0 : (PipelineRegHistory[1] == CurrentSrcRegrs ) ? 1'b1 : 1'b0;
       assign Fwd2Cmp_opA_ctl[2] = (PipelineRegHistory[2] == 0) ? 1'b0 : (PipelineRegHistory[2] == CurrentSrcRegrs ) ? 1'b1 : 1'b0;

       assign Fwd2Cmp_opB_ctl[0] = (PipelineRegHistory[0] == 0) ? 1'b0 : (PipelineRegHistory[0] == CurrentSrcRegrt ) ? 1'b1 : 1'b0;
       assign Fwd2Cmp_opB_ctl[1] = (PipelineRegHistory[1] == 0) ? 1'b0 : (PipelineRegHistory[1] == CurrentSrcRegrt ) ? 1'b1 : 1'b0;
       assign Fwd2Cmp_opB_ctl[2] = (PipelineRegHistory[2] == 0) ? 1'b0 : (PipelineRegHistory[2] == CurrentSrcRegrt ) ? 1'b1 : 1'b0;

       //TODO: Add forwarding for LWL/LWR case

       always @ (posedge CLK or negedge RESET)
         begin
         if(!RESET)
           begin
           PipelineRegHistory[0] <= 0;
           PipelineRegHistory[1] <= 0;
           PipelineRegHistory[2] <= 0;
           end  //reset
         else
           begin
           /*****/
           Fwd2ALU_opA_ctl <= Fwd2ALU_opA_ctl1;
           Fwd2ALU_opB_ctl <= Fwd2ALU_opB_ctl1;
           Fwd2ALU_MemWrite_ctl <= Fwd2ALU_MemWrite_ctl1;
           /****/
           PipelineRegHistory[0] <= CurrentDestReg;
           PipelineRegHistory[1] <= PipelineRegHistory[0];
           PipelineRegHistory[2] <= PipelineRegHistory[1];
           end
         $display("FL:Instruction = %x,RegWrite = %d, MemWrite = %d,CurrentDestReg[%d] = (RegDest[%d])?Instr[15:11][%d] : Instr[20:16][%d],PRH[0] = %d,PRH[1] = %d,PRH[2] = %d",Instr,RegWrite,MemWrite,CurrentDestReg,RegDest,Instr[15:11],Instr[20:16],PipelineRegHistory[0],PipelineRegHistory[1],PipelineRegHistory[2]);  
         $display("FL: Current SrcRegrs = %d  Srcregrt = %d ", CurrentSrcRegrs,CurrentSrcRegrt);
         $display("FL: forward EXE2rs   = %d, EXE2rt   = %d,\nFL: forward MEM2rs   = %d, MEM2rt   = %d",Fwd2ALU_opA_ctl[0],Fwd2ALU_opB_ctl[0],Fwd2ALU_opA_ctl[1],Fwd2ALU_opB_ctl[1]);
         $display("FL: forward EXE2cmpA = %d, EXE2cmpB = %d,\nFL: forward MEM2cmpA = %d, MEM2cmpB = %d",Fwd2Cmp_opA_ctl[0],Fwd2Cmp_opB_ctl[0],Fwd2Cmp_opA_ctl[1],Fwd2Cmp_opB_ctl[1]);
         end //always


endmodule


