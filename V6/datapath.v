module datapath (
	clk,
	reset,
	foodGiven,
	ballGiven,
	broomGiven,
	pillsGiven,
	firstAidGiven,
	hungry,
	bored,
	sick,
	dirty,
	dying,
	deceased,
	sleeping,
	age,
	drawStartScreen,
	drawGameBackground,
	drawHungerBubble,
	drawBoredBubble,
	drawSickBubble,
	drawDirtyBubble,
	drawDyingBubble,
	drawZzzs,
	drawBall,
	drawFood,
	drawBroom,
	drawPills,
	drawFirstAid,
	drawGameOver,
	moveSprites,
	nextFrame,
	lifeCounter,
	plotDone,
	plot,
	x,
	y,
	colour,
	movingComplete
);
	
	//CONTROLS
	/*
	SW[0] --> give food
	SW[1] --> give ball
	SW[2] --> give pills
	SW[3] --> give broom
	SW[4] --> give first aid
	KEY[2] --> exectute move
	*/
	
	// ### Parameters ## \\\
	localparam	maxLifeSpan =			9'd330,
					clockCycles =			26'h2FAF07F,
					//testClockCycles =	16'b1100001101010000, //for model sim testing
					hungerFreq =			5'd16,
					boredFreq =				5'd20,
					dirtyFreq =				5'd25,
					sickFreq =				5'd30,
					objStartX =				8'd50,
					objStartY =				7'd100,
					broomStartX =			8'd50, //change broom position later
					broomStartY =			7'd100, 
					sleepingFreq =			8'd45,
					sleepingTime =			3'd5,
					dyingToDeadFreq =		3'd4,
					stateToDyingFreq =	3'd4,
					xScreenPixels =		9'd320,
					yScreenPixels =		9'd240;

	// IO + reg \\

	input clk, reset;

	input drawStartScreen, drawGameBackground, drawHungerBubble, drawBoredBubble, drawSickBubble, drawDirtyBubble, drawDyingBubble, drawGameOver;
	input drawZzzs;
	input drawBall, drawFood, drawBroom, drawPills, drawFirstAid;

	input moveSprites;
	
	input foodGiven, ballGiven, broomGiven, pillsGiven, firstAidGiven;
	
	output reg hungry, bored, sick, dirty, dying, deceased, sleeping;
	output reg [3:0] age;

	output plotDone;
	wire plotDone_scrn, plotDone_ball, plotDone_bubble, plotDone_sleepZ, plotDoneObj;
	assign plotDone = plotDone_scrn || plotDone_ball || plotDone_bubble || plotDone_sleepZ || plotDoneObj;

	wire objGiven;
	assign objGiven = foodGiven || broomGiven || pillsGiven || firstAidGiven;

	wire [8:0] nextXScreen, ballXNext;
	wire [8:0] nextYScreen, ballYNext;
	wire [8:0] nextXBubble, nextYBubble;
	wire [8:0] nextXZzzs, nextYZzzs;
	wire [8:0] objectXNext, objectYNext;
	output reg [2:0] colour;

	output plot;
	output reg [8:0] x;
	output reg [8:0] y;

	output reg movingComplete;

	reg [6:0] rate;

	output reg [8:0] lifeCounter;

	reg [25:0] everyCycleCtr; // counts up to 49.999999M
	
	reg [8:0] objectX;
	reg [8:0] objecyY;
	
	reg [8:0] ballX;
	reg [8:0] ballY;

	reg localHungry, localBored, localDirty, localSick, localDying, localSleeping, localDeceased;
	
	//counters
	reg [2:0] hungrytoDyingCtr;
	reg [2:0] boredtoDyingCtr;
	reg [2:0] dirtytoDyingCtr;
	reg [2:0] sicktoDyingCtr;
	reg [2:0] dyingtoDeadCtr;
	reg [3:0] sleepCtr;

	reg prePlot;
	wire transparency;
	assign plot = prePlot && !transparency && !plotDone;

	reg [8:0] bubbleX;
	reg [8:0] bubbleY;
	reg [8:0] zzzsX;
	reg [8:0] zzzzY;
	 
	wire draw, drawScreen, drawBubble, drawSleepZ, drawBallZ, drawObject;
	assign draw = drawScreen || drawBubble || drawSleepZ || drawBallZ || drawObject;
	assign drawScreen = drawStartScreen || drawGameBackground || drawGameOver;
	assign drawBubble = drawHungerBubble || drawBoredBubble || drawSickBubble || drawDirtyBubble || drawDyingBubble;
	assign drawSleepZ = drawZzzs;
	assign drawBallZ = drawBall;
	assign drawObject = drawFood || drawBroom || drawPills || drawFirstAid;

	wire movingObject;
	assign movingObject = moveSprites || ballGiven || foodGiven || broomGiven || pillsGiven || firstAidGiven; 

	wire [20:0] frameCounter;
	output nextFrame;
	assign nextFrame = frameCounter == 834168;

	counter counter0 (
		.clk(clk),
		.en(1),
		.rst(reset),
		.out(frameCounter)
	);
 
	always@(posedge clk) begin	
		if (reset) begin
			localDeceased <= 0;
			lifeCounter <= 0;
			everyCycleCtr <= 0;
			hungrytoDyingCtr <= 0;
			boredtoDyingCtr <= 0;
			dirtytoDyingCtr <= 0;
			sicktoDyingCtr <= 0;
			dyingtoDeadCtr <= 0;
			age <= 0;
			sleepCtr <= 0;
			localHungry <= 0;
			localBored <= 0;
			localDirty <= 0;
			localSick <= 0;
			localDying <= 0;
			localSleeping <= 0;
		end
		else begin
			// Life Counters
			if (lifeCounter == maxLifeSpan) begin // this is the death condition
				localDeceased <= 1;
			end
			else if (everyCycleCtr < clockCycles) begin // increment this on every clock cycle
				everyCycleCtr <= everyCycleCtr + 1;
			end
			else if (everyCycleCtr == clockCycles) begin // increment this once per second
				everyCycleCtr <= 0;
				lifeCounter <= lifeCounter + 1;
			end
			if (localDeceased || drawStartScreen || drawGameOver) begin
				localDying <= 0;
				localHungry <= 0;
				localBored <= 0;
				localDirty <= 0;
				localSick <= 0;
				localSleeping <= 0;
				dying <= 0;
				hungry <= 0;
				bored <= 0;
				dirty <= 0;
				sick <= 0;
				sleeping <= 0;
				lifeCounter <= 0;
			end
			if (movingObject) begin
				localDying <= 0;
				localHungry <= 0;
				localBored <= 0;
				localDirty <= 0;
				localSick <= 0;
			end
			else if (firstAidGiven) begin
				localDying <= 0;
				hungrytoDyingCtr <= 0;
				boredtoDyingCtr <= 0;
				dirtytoDyingCtr <= 0;
				sicktoDyingCtr <= 0;
			end
			else if (localDying && !firstAidGiven) begin
				localDying <= 1;
				if (dyingtoDeadCtr == 3'b111) begin
					localDeceased <= 1;
				end
				else if (lifeCounter[4:0] == 5'b11100 && lifeCounter != 9'b000000000) begin
					dyingtoDeadCtr <= dyingtoDeadCtr + 1;
				end
				
				localHungry <= 0;
				localBored <= 0;
				localDirty <= 0;
				localSick <= 0;
				localSleeping <= 0;
			end
			
			if (!localDying && !movingObject && !deceased) begin
				if (!localSleeping) begin	
					
					if (foodGiven) begin
						localHungry <= 0;
						hungrytoDyingCtr <= 0;
					end
					else if (localHungry && !foodGiven) begin
						localHungry <= 1;
						if (hungrytoDyingCtr == 3'b111) begin
							localDying <= 1;
						end
						else if (lifeCounter[1:0] == 2'b10 && lifeCounter != 9'b000000000) begin
							hungrytoDyingCtr <= hungrytoDyingCtr + 1;
						end
					end
					else if ((lifeCounter[3:0] == 4'b1111) && (lifeCounter != 9'b000000000)) begin
						localHungry <= 1;
					end
					else begin
						localHungry <= 0;
					end
					
					
					if (ballGiven) begin
						localBored <= 0;
						boredtoDyingCtr <= 0;
					end
					else if (localBored && !ballGiven) begin
						localBored <= 1;
						if (boredtoDyingCtr == 3'b111) begin
							localDying <= 1;
						end
						else if (lifeCounter[1:0] == 2'b10 && lifeCounter != 9'b000000000) begin
							boredtoDyingCtr <= boredtoDyingCtr + 1;
						end
					end
					else if ((lifeCounter[4:0] == 5'b10011) && (lifeCounter != 9'b000000000)) begin
						localBored <= 1;
					end
					else begin
						localBored <= 0;
					end
					
					if (broomGiven) begin
						localDirty <= 0;
						dirtytoDyingCtr <= 0;
					end
					else if (localDirty && !broomGiven) begin
						localDirty <= 1;
						if (dirtytoDyingCtr == 3'b111) begin
							localDying <= 1;
						end
						else if (lifeCounter[1:0] == 2'b10 && lifeCounter != 9'b000000000) begin
							dirtytoDyingCtr <= dirtytoDyingCtr + 1;
						end
					end
					else if ((lifeCounter[4:0] == 5'b11000) && (lifeCounter != 9'b000000000)) begin
						localDirty <= 1;
					end
					else begin
						localDirty <= 0;
					end
					
					if (pillsGiven) begin
						localSick <= 0;
						sicktoDyingCtr <= 0;
					end
					else if (localSick && !pillsGiven) begin
						localSick <= 1;
						if (sicktoDyingCtr == 3'b111) begin
							localDying <= 1;
						end
						else if (lifeCounter[1:0] == 2'b11 && lifeCounter != 9'b000000000) begin
							sicktoDyingCtr <= sicktoDyingCtr + 1;
						end
					end
					else if ((lifeCounter[4:0] == 5'b11101) && (lifeCounter != 9'b000000000)) begin
						localSick <= 1;
					end
					else begin
						localSick <= 0;
					end
					
					if (lifeCounter[5:0] == 6'b101100 && lifeCounter != 9'b000000000) begin
						localSleeping <= 1;
					end
					else begin
						localSleeping <= 0;
					end
					
				end // localSleeping
				else begin
					if (sleepCtr == 4'b1100) begin
						localSleeping <= 0;
						sleepCtr <= 0;
						age <= age + 1;
					end
					else begin
						if (lifeCounter[2:0] == 3'b100 && lifeCounter != 9'b000000000) begin
							sleepCtr <= sleepCtr + 1;
						end
						else begin
							sleepCtr <= sleepCtr;
						end
						localSleeping <= 1;
					end
				end
				
			end // localDying
			else begin
				localHungry <= 0;
				localBored <= 0;
				localDirty <= 0;
				localSick <= 0;
				localSleeping <= 0;
			end
		end
		
		deceased <= localDeceased;
		dying <= localDying;
		hungry <= localHungry;
		bored <= localBored;
		dirty <= localDirty;
		sick <= localSick;
		sleeping <= localSleeping;
		
	end
	
	// movement block
	always @ (posedge clk) begin

		prePlot <= draw;

		if (reset) begin

			ballX <= 105;
			ballY <= 50;
			bubbleX <= 175;
			bubbleY <= 70;
			zzzsX <= 105;
			zzzzY <= 70;
				
			//position of food, pills, first aid
			objectX <= 105;
			objecyY <= 50;
			
			// reset the data
			movingComplete <= 0;
		end 
		else if (drawBall) begin
			x <= ballXNext + ballX;
			y <= ballYNext + ballY;
		end
		else if (drawObject) begin
			x <= objectXNext + objectX;
			y <= objectYNext + objecyY;
		end
		else if (moveSprites && ballGiven) begin
			if (ballY <= 145) begin
				ballY <= ballY + 1;
				ballX <= ballX;
			end
			else begin
				ballY <= ballY;
				ballX <= ballX;
			end
		end
		else if (moveSprites && objGiven) begin
			if (objecyY <= 145) begin
				objecyY <= objecyY + 1;
				objectX <= objectX;
			end
			else begin
				objecyY <= objecyY;
				objectX <= objectX;
			end
		end	
		else if (drawHungerBubble || drawBoredBubble || drawSickBubble || drawDirtyBubble || drawDyingBubble) begin
			x <= bubbleX + nextXBubble;
			y <= bubbleY + nextYBubble;
		end 
		else if (drawZzzs) begin
			x <= zzzsX + nextXZzzs;
			y <= zzzzY + nextYZzzs;
		end
		else if (drawStartScreen || drawGameBackground || drawGameOver) begin
			x <= nextXScreen;
			y <= nextYScreen;
		end
			
		if (!ballGiven) begin
			ballY <= 50;
			ballX <= 105;
		end
		if (!foodGiven && !broomGiven && !pillsGiven && !firstAidGiven) begin
			objecyY <= 50;
			objectX <= 105;
		end
	end

	// ### Plotters ### \\

	plotter #(
		.WIDTH_X(9),
		.WIDTH_Y(8),
		.MAX_X(320),
		.MAX_Y(240)
	) plt_scrn (
		.clk(clk), .en(drawScreen && !plotDone),
		.x(nextXScreen), .y(nextYScreen),
		.done(plotDone_scrn)
	);

	plotter #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.MAX_X(32),
		.MAX_Y(32)
	) plt_bubble (
		.clk(clk), .en(drawBubble && !plotDone),
		.x(nextXBubble), .y(nextYBubble),
		.done(plotDone_bubble)
	);
	 
	plotter #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.MAX_X(32),
		.MAX_Y(32)
	) plt_zzzs (
		.clk(clk), .en(drawSleepZ && !plotDone),
		.x(nextXZzzs), .y(nextYZzzs),
		.done(plotDone_sleepZ)
	);

	plotter #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.MAX_X(32),
		.MAX_Y(32)
	) plot_ball (
		.clk(clk), .en(drawBallZ && !plotDone),
		.x(ballXNext), .y(ballYNext),
		.done(plotDone_ball)
	);
	 
	plotter #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.MAX_X(32),
		.MAX_Y(32)
	) plt_obj (
		.clk(clk), .en(drawObject && !plotDone),
		.x(objectXNext), .y(objectYNext),
		.done(plotDoneObj)
	);

	// ### Start screen ### \\

	wire [2:0] screenStartColour;

	sprite_ram_module #(
		.WIDTH_X(9),
		.WIDTH_Y(8),
		.RESOLUTION_X(320),
		.RESOLUTION_Y(240),
		.MIF_FILE("graphics/newstartscreen.mif")
	) srm_scrn_start (
		.clk(clk),
		.x(nextXScreen), .y(nextYScreen),
		.color_out(screenStartColour)
	);


	wire [2:0] ball_colour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/basketball.colour.mif")
	) srm_ball (
		.clk(clk),
		.x(ballXNext), .y(ballYNext),
		.color_out(ball_colour)
	); 

	wire [2:0] gameBackgroundColour;

	sprite_ram_module #(
		.WIDTH_X(9),
		.WIDTH_Y(8),
		.RESOLUTION_X(320),
		.RESOLUTION_Y(240),
		.MIF_FILE("graphics/pet320x240.mif")
	) srm_scrn_game_bg (
		.clk(clk),
		.x(nextXScreen), .y(nextYScreen),
		.color_out(gameBackgroundColour)
	);

	wire [2:0] gameOverColour;

	sprite_ram_module #(
		.WIDTH_X(9),
		.WIDTH_Y(8),
		.RESOLUTION_X(320),
		.RESOLUTION_Y(240),
		.MIF_FILE("graphics/death-screen.mif")
	) gameover_screen (
		.clk(clk),
		.x(nextXScreen), .y(nextYScreen),
		.color_out(gameOverColour)
	);

	wire [2:0] hungerBubbleColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/hungerbubble.mif")
	) srm_hungerbubble (
		.clk(clk),
		.x(nextXBubble), .y(nextYBubble),
		.color_out(hungerBubbleColour)
	);

	wire [2:0] boredBubbleColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/boredbubble.mif")
	) srm_boredbubble (
		.clk(clk),
		.x(nextXBubble), .y(nextYBubble),
		.color_out(boredBubbleColour)
	);

	wire [2:0] sickBubbleColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/sickbubble.mif")
	) srm_sickbubble (
		.clk(clk),
		.x(nextXBubble), .y(nextYBubble),
		.color_out(sickBubbleColour)
	);

	wire [2:0] dirtyBubbleColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/dirtybubble.mif")
	) srm_dirtybubble (
		.clk(clk),
		.x(nextXBubble), .y(nextYBubble),
		.color_out(dirtyBubbleColour)
	);

	wire [2:0] dyingBubbleColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/dyingbubble.mif")
	) srm_dyingbubble (
		.clk(clk),
		.x(nextXBubble), .y(nextYBubble),
		.color_out(dyingBubbleColour)
	);

	wire [2:0] sleepZColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/zzzs.mif")
	) srm_zzzs (
		.clk(clk),
		.x(nextXZzzs), .y(nextYZzzs),
		.color_out(sleepZColour)
	);

	wire [2:0] foodColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/chicken-leg.mif")
	) food (
		.clk(clk),
		.x(objectXNext), .y(objectYNext),
		.color_out(foodColour)
	);

	wire [2:0] broomColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/broom.mif")
	) broom (
		.clk(clk),
		.x(objectXNext), .y(objectYNext),
		.color_out(broomColour)
	);

	wire [2:0] pillsColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/pills.mif")
	) pills (
		.clk(clk),
		.x(objectXNext), .y(objectYNext),
		.color_out(pillsColour)
	);

	wire [2:0] firstAirColour;

	sprite_ram_module #(
		.WIDTH_X(6),
		.WIDTH_Y(6),
		.RESOLUTION_X(32),
		.RESOLUTION_Y(32),
		.MIF_FILE("graphics/medkit.mif")
	) firstAid (
		.clk(clk),
		.x(objectXNext), .y(objectYNext),
		.color_out(firstAirColour)
	);

	assign transparency =	(drawHungerBubble && hungerBubbleColour == 3) ||
									(drawBoredBubble && boredBubbleColour == 3) || 
									(drawSickBubble && sickBubbleColour == 3) || 
									(drawDirtyBubble && dirtyBubbleColour == 3) || 
									(drawDyingBubble && dyingBubbleColour == 3) || 
									(drawZzzs && sleepZColour == 3) || 
									(drawBall && ball_colour == 3) || 
									(drawFood && foodColour == 3) || 
									(drawBroom && broomColour == 3) || 
									(drawPills && pillsColour == 3) || 
									(drawFirstAid && firstAirColour == 3);
	 
	always @ (*) begin
		if (drawStartScreen)
			colour = screenStartColour;
		else if (drawGameBackground)
			colour = gameBackgroundColour;
		else if (drawGameOver)
			colour = gameOverColour;
		else if (drawHungerBubble)
			colour = hungerBubbleColour;
		else if (drawBoredBubble)
			colour = boredBubbleColour;
		else if (drawSickBubble)
			colour = sickBubbleColour;
		else if (drawDirtyBubble)
			colour = dirtyBubbleColour;
		else if (drawDyingBubble)
			colour = dyingBubbleColour;
		else if (drawZzzs)
			colour = sleepZColour;
		else if (drawBall)
			colour = ball_colour;
		else if (drawFood)
			colour = foodColour;
		else if (drawBroom)
			colour = broomColour;
		else if (drawPills)
			colour = pillsColour;
		else if (drawFirstAid)
			colour = firstAirColour;
		else
			colour = 7;
		end

endmodule // datapath