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
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ForwardLogic( 
       input             CLK,
       input             RESET,
       input      [31:0] Instr,
       output reg        forwardFromExe2rs,        // Forward from EXE phase to rs field in EXE
       output reg        forwardFromExe2rt,        // Forward from EXE phase to rt field in EXE
       output reg        forwardFromMem2rs,        // Forward from MEM phase to rs field in EXE
       output reg        forwardFromMem2rt,        // Forward from MEM phase to rt files in EXE

       input             RegWrite,                 //This instruction writes to a register
       input             RegDest                   //This instruction uses the RegDest register (Instr[15:11])

       );

       //Table To hold Destination Registers in [0] = Exe [1] = Mem
       reg  [4:0] PipelineRegHistory [1:0];
       wire [4:0] CurrentDestReg;  
       wire [4:0] CurrentSrcRegrs;  
       wire [4:0] CurrentSrcRegrt;  
     
       wire       forwardFromExe2rs1;        // Forward from EXE phase to rs field in EXE
       wire       forwardFromExe2rt1;        // Forward from EXE phase to rt field in EXE
       wire       forwardFromMem2rs1;        // Forward from MEM phase to rs field in EXE
       wire       forwardFromMem2rt1;        // Forward from MEM phase to rt files in EXE
       //Calculate the destination register for the current instruction
       assign CurrentDestReg = (RegWrite) ?  (RegDest? Instr[15:11]:Instr[20:16]): 5'b0;

       //Calculate the source register for the current instruction 
       assign CurrentSrcRegrs = Instr[25:21]; 
       assign CurrentSrcRegrt = (RegDest)?Instr[20:16]:5'b0; 

       //We treat 'zero' entries as by-pass ignore for when there aren't any reg write
       // If the current destination register matches any value in the Pipeline History the we check the next condition, else we don't by-pass
       // In the case that both exe and mem phase has the same destination register, we pick the most recent, else we select the matching phase value
       assign forwardFromExe2rs1 = (PipelineRegHistory[0] == 0)?1'b0 : ((PipelineRegHistory[0] == CurrentSrcRegrs ) ? ((PipelineRegHistory[0] == PipelineRegHistory[1]) ? 1'b1: 1'b1) : 1'b0);
       assign forwardFromMem2rs1 = (PipelineRegHistory[1] == 0)?1'b0 : (PipelineRegHistory[1] == CurrentSrcRegrs ) ? ((PipelineRegHistory[0] == PipelineRegHistory[1]) ? 1'b0: 1'b1) : 1'b0;
       
       assign forwardFromExe2rt1 = (PipelineRegHistory[0] == 0)?1'b0 : (PipelineRegHistory[0] == CurrentSrcRegrt ) ? ((PipelineRegHistory[0] == PipelineRegHistory[1]) ? 1'b1: 1'b1) : 1'b0;
       assign forwardFromMem2rt1 = (PipelineRegHistory[1] == 0)?1'b0 : (PipelineRegHistory[1] == CurrentSrcRegrt ) ? ((PipelineRegHistory[0] == PipelineRegHistory[1]) ? 1'b0: 1'b1) : 1'b0;
       
       
       always @ (posedge CLK or negedge RESET)
         begin
         if(!RESET)
           begin
           PipelineRegHistory[0] <= 0;
           PipelineRegHistory[1] <= 0;
           end  //reset
         else
           begin
           /*****/
           forwardFromExe2rs   <= forwardFromExe2rs1;     
           forwardFromExe2rt   <= forwardFromExe2rt1;     
           forwardFromMem2rs   <= forwardFromMem2rs1;     
           forwardFromMem2rt   <= forwardFromMem2rt1;     
           /****/
           PipelineRegHistory[0] <= CurrentDestReg;
           PipelineRegHistory[1] <= PipelineRegHistory[0];
           end
         $display("FL:Instruction = %x,RegWrite = %d,CurrentDestReg[%d] = (RegDest[%d])?Instr[15:11][%d] : Instr[20:16][%d],PRH[EXE] = %d,PRH[MEM] = %d",Instr,RegWrite,CurrentDestReg,RegDest,Instr[15:11],Instr[20:16],PipelineRegHistory[0],PipelineRegHistory[1]);  
         $display("FL: Current SrcRegrs = %d  Srcregrt = %d ", CurrentSrcRegrs,CurrentSrcRegrt);
         $display("FL: forward EXE2rs   = %d, EXE2rt   = %d,\nFL: forward MEM2rs   = %d, MEM2rt   = %d",forwardFromExe2rs,forwardFromExe2rt,forwardFromMem2rs,forwardFromMem2rt);
         end //always


endmodule


