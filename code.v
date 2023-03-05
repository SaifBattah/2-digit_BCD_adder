module FA_1bit(A,B,Cin,Sum,Cout);
	
	input A,B,Cin;
	output Sum,Cout;
	wire w1,w2,w3;
	
	and #(8ns) (w1,A,B);
	xor	#(12ns) (w2,A,B);
	and #(8ns) (w3,w2,Cin);
	xor #(12ns) (Sum,w2,Cin);
	or  #(8ns) (Cout,w1,w3);

endmodule

////////////////////////////////////////////////

module BinaryAdder_4bit(A,B,Cin,Sum,Cout);
	
	input [3:0] A,B;
	input Cin;
	output [3:0] Sum;
	output Cout;
	wire C1,C2,C3;
    
    FA_1bit F1(A[0],B[0],Cin,Sum[0],C1);
    FA_1bit F2(A[1],B[1],C1,Sum[1],C2);
    FA_1bit F3(A[2],B[2],C2,Sum[2],C3);
    FA_1bit F4(A[3],B[3],C3,Sum[3],Cout);
    
    
endmodule


////////////////////////////////////////////////

module BCD_Adder1bit(A,B,Cin,F,OutputCarry);
    input [3:0] A,B;
    input Cin;
    output [3:0] F;
    output OutputCarry;
	wire [3:0] Z,S;
	wire k,w1,w2,w3;
    
    BinaryAdder_4bit BA1(A,B,Cin,Z,k);
    
	and #(8ns) (w1,Z[2],Z[3]);
    and #(8ns) (w2,Z[1],Z[3]);
    or  #(8ns) (OutputCarry,k,w1,w2);
	
	assign S = {1'b0,OutputCarry,OutputCarry,1'b0};
	BinaryAdder_4bit BA2(Z,S,0,F,w3);
endmodule

////////////////////////////////////////////////

module dff(Q,D,clk);
	input D,clk;
	output reg Q;
	
	always @(posedge clk)
		begin
			Q <= D;
		end
endmodule

////////////////////////////////////////////////

module Register_input(out,in,clk);
	output reg [7:0] out;
	input [7:0] in;
	input clk;
	wire [7:0] temp_out;
	
	dff d0(temp_out[0],in[0],clk); 
	dff d1(temp_out[1],in[1],clk);
	dff d2(temp_out[2],in[2],clk);
	dff d3(temp_out[3],in[3],clk);
	dff d4(temp_out[4],in[4],clk);
	dff d5(temp_out[5],in[5],clk);
	dff d6(temp_out[6],in[6],clk);
	dff d7(temp_out[7],in[7],clk);
	
	always @ (posedge clk) 
		begin
			out = temp_out;
		end	
endmodule

////////////////////////////////////////////////

module Register_output(out,in,clk);
	output reg [8:0] out;
	input [8:0] in;
	input clk;
	wire [8:0] temp_out;
	
	dff d0(temp_out[0],in[0],clk); 
	dff d1(temp_out[1],in[1],clk);
	dff d2(temp_out[2],in[2],clk);
	dff d3(temp_out[3],in[3],clk);
	dff d4(temp_out[4],in[4],clk);
	dff d5(temp_out[5],in[5],clk);
	dff d6(temp_out[6],in[6],clk);
	dff d7(temp_out[7],in[7],clk);
	dff d8(temp_out[8],in[8],clk);
	
	always @ (posedge clk) 
		begin
			out = temp_out;
		end	
endmodule

////////////////////////////////////////////////

module System(A,B,clk,Result);
	input [7:0] A,B;
	reg Carryout;
	output reg [8:0] Result;
	reg [7:0] Aout,Bout;
	reg tempCout,tempCin; 
	input clk;
	reg [3:0]SL,SM,AL,BL,AM,BM;
	reg [8:0] tempResult;
	
	Register_input IA(Aout,A,clk); 
	Register_input IB(Bout,B,clk); 
	
	assign AL = Aout[3:0];
	assign BL = Bout[3:0];
	assign AM = Aout[7:4];
	assign BM = Bout[7:4];													  
	
	BCD_Adder1bit D1(AL,BL,1'b0,SL,tempCout);
	
	assign tempCin = tempCout;
	
	BCD_Adder1bit D2(AM,BM,tempCin,SM,Carryout);  
	
	always @ (posedge clk)	
		begin
			assign tempResult = {Carryout,SM,SL} ; 
	 	end
	 
	Register_output O(Result,tempResult,clk);

endmodule	   

////////////////////////////////////////////////

module BCD_Tester(A,B,Result);
	
	input [7:0] A,B;	
	output reg [8:0] Result;
	reg [7:0] Sum;
	reg Cout;
	
	reg [3:0] AL,AM,BL,BM,SL,SM;
	reg temp_carry;
	reg [4:0] temp_SL,temp_SM;
	
	assign AL = A[3:0];
	assign BL = B[3:0];
	assign AM = A[7:4];
	assign BM = B[7:4];
	
	always @ (*)
		
		begin
			temp_SL = AL + BL + 0;
			
			if(temp_SL > 9)
				
				begin
				
					temp_SL = temp_SL + 6;
					temp_carry = 1;
					SL = temp_SL[3:0];
			
				end
		
			else 
				
				begin
			
					temp_carry = 0;
					SL = temp_SL[3:0];
			
				end	 
			
			temp_SM = AM + BM + temp_carry;
			
			if(temp_SM > 9)
				
				begin
					
					temp_SM = temp_SM + 6;
					Cout = 1;
					SM = temp_SM[3:0];
					
				end
				
			else
				
				begin
					
					Cout = 0;
					SM = temp_SM[3:0];
				
				end	
					
				Sum = {SM,SL};	
		#700ns 	Result = {Cout,Sum};
				
			end
			
endmodule

////////////////////////////////////////////////

module Stage_1();
	reg [7:0] A,B;
	reg clk;
	wire [8:0] True_Result,Exp_Result; 
	  
	System S1(A,B,clk,Exp_Result); //Experimental Sum
	BCD_Tester T1(A,B,True_Result);//True Sum

	always  #(100ns) clk = ~clk;
	
		initial
		
			begin 
				
				clk = 0;
				{B,A} = 16'b0000000000000000;
				#700ns 	{B,A} = 16'b0000000000000000;
				
				repeat(65535)
			
				#(900ns) {B,A} = {B,A} + 16'b0000000000000001;
				
				if(Exp_Result != True_Result)
					
					begin 
						
						$display ("Error! at %b",True_Result); 
						
					end	
					
		end	
	
endmodule
 												
////////////////////////////////////////////////

module carry_lookahead_adder_4_bit(i_add1, i_add2, o_result);
 
  input [3:0] i_add1, i_add2;
  output [4:0] o_result;    
  wire [4:0]    w_C;
  wire [3:0]    w_G, w_P, w_SUM;
   
  FA_1bit F1(.A(i_add1[0]), .B(i_add2[0]), .Cin(w_C[0]), .Sum(w_SUM[0]), .Cout());
 
  FA_1bit F2(.A(i_add1[1]), .B(i_add2[1]), .Cin(w_C[1]), .Sum(w_SUM[1]), .Cout());
 
  FA_1bit F3(.A(i_add1[2]), .B(i_add2[2]), .Cin(w_C[2]), .Sum(w_SUM[2]), .Cout());
   
  FA_1bit F4(.A(i_add1[3]), .B(i_add2[3]), .Cin(w_C[3]), .Sum(w_SUM[3]), .Cout());
   
  assign w_G[0] = i_add1[0] & i_add2[0];
  assign w_G[1] = i_add1[1] & i_add2[1];
  assign w_G[2] = i_add1[2] & i_add2[2];
  assign w_G[3] = i_add1[3] & i_add2[3];
 
  assign w_P[0] = i_add1[0] | i_add2[0];
  assign w_P[1] = i_add1[1] | i_add2[1];
  assign w_P[2] = i_add1[2] | i_add2[2];
  assign w_P[3] = i_add1[3] | i_add2[3];
 
  assign w_C[0] = 1'b0;
  assign w_C[1] = w_G[0] | (w_P[0] & w_C[0]);
  assign w_C[2] = w_G[1] | (w_P[1] & w_C[1]);
  assign w_C[3] = w_G[2] | (w_P[2] & w_C[2]);
  assign w_C[4] = w_G[3] | (w_P[3] & w_C[3]);
   
  assign o_result = {w_C[4], w_SUM};
 
endmodule

////////////////////////////////////////////////

module BCD_Adder_LA_1bit(A,B,F);
    input [3:0] A,B;
    output [4:0] F;
	reg [3:0] tempF;
	reg [3:0] Z,S;
	reg tempc;
    
    carry_lookahead_adder_4_bit BA1(A,B,S);
	
	always @(*)
	if( S > 4'b1001)
		begin
		 	assign Z = 4'b0110;
			assign tempc = 1'b1;
		end
	else
		begin
			assign Z = 4'b0000;
			assign tempc = 1'b0;
		end
	
	
	carry_lookahead_adder_4_bit BA2(S,Z,tempF);
	
	assign F={tempc,tempF};
	
endmodule

////////////////////////////////////////////////

module BCD_Adder_LA_2bit(A,B,Result);
	
	input [7:0] A,B;
	output [8:0] Result;
	reg [4:0] SL,SM;
	reg tens,hunds;
	
	BCD_Adder_LA_1bit B1(A[3:0],B[3:0],SL);	
	
	assign tens = SL[4];
		
	BCD_Adder_LA_1bit B2({A[7:4]+tens},B[7:4],SM);
	
	assign hunds = SM[4];		
	
	assign Result = {hunds,SM[3:0],SL[3:0]};
	
	
endmodule

////////////////////////////////////////////////

module Stage_2();
	reg [7:0] A,B;
	reg clk;
	wire [8:0] True_Result,Exp_Result; 
	  
	System S1(A,B,clk,Exp_Result); //Experimental Sum
	BCD_Adder_LA_2bit T1(A,B,True_Result);//True Sum  

	always  #(100ns) clk = ~clk;
	
		initial
		
			begin 
				
				clk = 0;
				{B,A} = 16'b0000000000000000;
				#700ns 	{B,A} = 16'b0000000000000000;
				
				repeat(65535)
			
				#(900ns) {B,A} = {B,A} + 16'b0000000000000001;
				
				if(Exp_Result != True_Result)
					
					begin 
						
						$monitor ("Error! at %b",True_Result); 
						
					end	
					
		end	
	
endmodule

////////////////////////////////////////////////
