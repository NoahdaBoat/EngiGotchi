module datapath(input clk, resetn, plotEn, go, erase, update, reset,
					 input [2:0] clr,
					 output reg [7:0] X,
					 output reg [6:0] Y,
					 output reg [2:0] CLR,
					 output reg [5:0] plotCounter,
					 output reg [7:0] xCounter,
					 output reg [6:0] yCounter, 
					 output reg [25:0] freq );
	reg [7:0] xTemp;
	reg [6:0] yTemp;
	reg opX, opY;
	always @(posedge clk) 
	begin
		if (reset || !resetn) begin
			X <= 8'd156;
			Y <= 7'b0;
			xTemp <= 8'd156;
			yTemp <= 7'b0;
			plotCounter<= 6'b0;
			xCounter<= 8'b0;
			yCounter <= 7'b0;
			CLR <= 3'b0;
			freq <= 25'd0;
			opX <= 1'b0;
			opY <= 1'b1;
		end
		else begin
			if (erase & !plotEn) begin
				if (xCounter == 8'd160 && yCounter != 7'd120) begin
					xCounter <= 8'b0;
					yCounter <= yCounter + 1;
				end
				else begin
					xCounter <= xCounter + 1;
					X <= xCounter;
					Y <= yCounter;
					CLR <= 3'b0; 
				end
			end
			if (!erase) CLR <= clr;
			
			if (freq == 26'd12499999) freq <= 26'd0;
			else freq <= freq + 1;
			
			if (plotEn) begin
				if (erase) CLR <= 0;
				else CLR <= clr;
				if (plotCounter == 6'b10000) plotCounter<= 6'b0;
				else plotCounter <= plotCounter+1;
				X <= xTemp + plotCounter[1:0];
				Y <= yTemp + plotCounter[3:2];
			end
			if (update) begin
				if (X == 8'b0) opX = 1;
				if (X == 8'd156) opX = 0;
				if (Y == 7'b0) opY = 1;
				if (Y == 7'd116) opY = 0;
				
				if (opX == 1'b1) begin	
					X <= X + 1;
					xTemp <= xTemp + 1;
				end
				if (opX == 1'b0) begin
					X <= X - 1;
					xTemp <= xTemp - 1;
				end
				if (opY == 1'b1) begin
					Y <= Y + 1;
					yTemp <= yTemp + 1;
				end
				if (opY == 1'b0) begin
					Y <= Y - 1;
					yTemp <= yTemp - 1;
				end
			end
		end
	end
endmodule