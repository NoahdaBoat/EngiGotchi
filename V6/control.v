module control (
	clk,
	reset,

	plotDone,
	start,

	frameTick,
	movingComplete,
	ballGiven,
	foodGiven,
	broomGiven,
	pillsGiven,
	firstAidGiven,
	deceased,

	drawStartScreen,
	drawGameBackground,
	drawBall,
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
	hungerEnable,
	boredEnable,
	sickEnable,
	dirtyEnable,
	dyingEnable,
	zzzsEnable,
	moveSprites,
	currentState
);

	input clk, reset;
	input plotDone, start;
	input movingComplete;
	input frameTick;
	input ballGiven, foodGiven, broomGiven, pillsGiven, firstAidGiven, deceased;
	 
	input hungerEnable, boredEnable, sickEnable, dirtyEnable, dyingEnable, zzzsEnable;
	output reg drawStartScreen, drawGameBackground, drawHungerBubble, drawBoredBubble, drawSickBubble, drawDirtyBubble, drawDyingBubble, drawGameOver;
	output reg drawZzzs;
	output reg drawBall, drawFood, drawBroom, drawPills, drawFirstAid;
	output reg moveSprites;

	output reg [4:0] currentState;
	reg [4:0] next_state;

	wire continue = 1;
	 
	wire itemGiven;
	assign itemGiven = ballGiven || foodGiven || broomGiven || pillsGiven || firstAidGiven;

	// States 
	localparam  WAIT_START_STATE				=  0, // Wait before drawing START screen.
					DRAW_SCRN_START_STATE		=  1, // Draw START screen.
					WAIT_GAME_BG_STATE			=  2, // Wait before drawing game background.
					DRAW_GAME_BG_STATE			=  3, // Draw game background.
					WAIT_OBJ_STATE					=  4,
					DRAW_BALL_STATE				=  5,
					MOVE_OBJECTS_STATE			=  6, // Move objects for the next cycle. (One cycle is from state 2 to 5).
					WAIT_FRAME_TICK_STATE		=  7, // Wait for frame tick.
					DRAW_HUNGER_BUBBLE_STATE	=  8,
					WAIT_HUNGER_BUBBLE_STATE	=  9,
					DRAW_BORED_BUBBLE_STATE		= 10,
					WAIT_BORED_BUBBLE_STATE		= 11,
					DRAW_SICK_BUBBLE_STATE		= 12,
					WAIT_SICK_BUBBLE_STATE		= 13,
					DRAW_DIRTY_BUBBLE_STATE		= 14,
					WAIT_DIRTY_BUBBL_STATEE		= 15,
					DRAW_DYING_BUBBLE_STATE		= 16,
					WAIT_DYING_BUBBLE_STATE		= 17,
					DRAW_ZZZS_STATE				= 18,
					WAIT_ZZZS_STATE				= 19,
					DRAW_FOOD_STATE 				= 20,
					DRAW_BROOM_STATE				= 21,
					DRAW_PILLS_STATE				= 22,
					DRAW_FIRSTAID_STATE			= 23,
					GAME_OVER_STATE				= 24;

	// State table
	always @ (*) begin
		case (currentState)
			WAIT_START_STATE:
				next_state = continue ? DRAW_SCRN_START_STATE : WAIT_START_STATE;
			DRAW_SCRN_START_STATE: 
				next_state = start ? WAIT_GAME_BG_STATE : DRAW_SCRN_START_STATE;
			WAIT_GAME_BG_STATE:
				next_state = continue ? DRAW_GAME_BG_STATE : WAIT_GAME_BG_STATE;
			DRAW_GAME_BG_STATE:
				begin
					if (plotDone) begin
						if (deceased) begin
							next_state = GAME_OVER_STATE;
						end
						else if (itemGiven) begin
							next_state = WAIT_OBJ_STATE;
						end
						else if (hungerEnable) begin
							next_state = WAIT_HUNGER_BUBBLE_STATE;	
						end
						else if (boredEnable) begin
							next_state = WAIT_BORED_BUBBLE_STATE;
						end
						else if (sickEnable) begin
							next_state = WAIT_SICK_BUBBLE_STATE;
						end
						else if (dirtyEnable) begin
							next_state = WAIT_DIRTY_BUBBL_STATEE;
						end
						else if (dyingEnable) begin
							next_state = WAIT_DYING_BUBBLE_STATE;
						end
						else if (zzzsEnable) begin
							next_state = WAIT_ZZZS_STATE;
						end
					end
					else begin
						next_state = DRAW_GAME_BG_STATE;
					end
				end
			WAIT_OBJ_STATE:
				begin
					if (ballGiven) begin
						next_state = DRAW_BALL_STATE;
					end
					else if (foodGiven) begin
						next_state = DRAW_FOOD_STATE;
					end
					else if (broomGiven) begin
						next_state = DRAW_BROOM_STATE;
					end
					else if (pillsGiven) begin
						next_state = DRAW_PILLS_STATE;
					end
					else if (firstAidGiven) begin
						next_state = DRAW_FIRSTAID_STATE;
					end
				end
			WAIT_HUNGER_BUBBLE_STATE:
				next_state = continue ? DRAW_HUNGER_BUBBLE_STATE : WAIT_HUNGER_BUBBLE_STATE;
			DRAW_HUNGER_BUBBLE_STATE:
				next_state = plotDone ? (foodGiven ? DRAW_FOOD_STATE : WAIT_FRAME_TICK_STATE) : DRAW_HUNGER_BUBBLE_STATE;
			WAIT_BORED_BUBBLE_STATE:
					next_state = continue ? DRAW_BORED_BUBBLE_STATE : WAIT_BORED_BUBBLE_STATE;
			DRAW_BORED_BUBBLE_STATE: 
				next_state = plotDone ? (ballGiven ? DRAW_BALL_STATE : WAIT_FRAME_TICK_STATE) : DRAW_BORED_BUBBLE_STATE;
			WAIT_SICK_BUBBLE_STATE:
				next_state = continue ? DRAW_SICK_BUBBLE_STATE : WAIT_SICK_BUBBLE_STATE;
			DRAW_SICK_BUBBLE_STATE:
				next_state = plotDone ? (pillsGiven ? DRAW_PILLS_STATE : WAIT_FRAME_TICK_STATE) : DRAW_SICK_BUBBLE_STATE;
			WAIT_DIRTY_BUBBL_STATEE:
				next_state = continue ? DRAW_DIRTY_BUBBLE_STATE : WAIT_DIRTY_BUBBL_STATEE;
			DRAW_DIRTY_BUBBLE_STATE:
				next_state = plotDone ? (broomGiven ? DRAW_BROOM_STATE : WAIT_FRAME_TICK_STATE) : DRAW_DIRTY_BUBBLE_STATE;
			WAIT_DYING_BUBBLE_STATE:
				next_state = continue ? DRAW_DYING_BUBBLE_STATE : WAIT_DYING_BUBBLE_STATE;
			DRAW_DYING_BUBBLE_STATE:
				next_state = plotDone ? (firstAidGiven ? DRAW_FIRSTAID_STATE : WAIT_FRAME_TICK_STATE) : DRAW_DYING_BUBBLE_STATE;
			WAIT_ZZZS_STATE:
				next_state = continue ? DRAW_ZZZS_STATE : WAIT_ZZZS_STATE;
			DRAW_ZZZS_STATE:
				next_state = plotDone ? WAIT_FRAME_TICK_STATE : DRAW_ZZZS_STATE;
			DRAW_BALL_STATE:
				next_state = plotDone ? MOVE_OBJECTS_STATE : DRAW_BALL_STATE;
			DRAW_FOOD_STATE:
				next_state = plotDone ? MOVE_OBJECTS_STATE : DRAW_FOOD_STATE;
			DRAW_BROOM_STATE:
				next_state = plotDone ? MOVE_OBJECTS_STATE : DRAW_BROOM_STATE;
			DRAW_PILLS_STATE:
				next_state = plotDone ? MOVE_OBJECTS_STATE : DRAW_PILLS_STATE;
			DRAW_FIRSTAID_STATE:
				next_state = plotDone ? MOVE_OBJECTS_STATE : DRAW_FIRSTAID_STATE;
			MOVE_OBJECTS_STATE:
				next_state = WAIT_FRAME_TICK_STATE; 
			WAIT_FRAME_TICK_STATE:
				next_state = frameTick ? DRAW_GAME_BG_STATE : WAIT_FRAME_TICK_STATE;	 
			GAME_OVER_STATE:
				next_state = plotDone ? (reset ? WAIT_START_STATE : GAME_OVER_STATE) : GAME_OVER_STATE;
		endcase
	end

	// State switching and reset
	always @ (posedge clk) begin
		if (reset)
			currentState <= WAIT_START_STATE;
		else
			currentState <= next_state;
	end

	// Output logic
	always @ (*) begin
		drawStartScreen = 0;
		drawGameBackground = 0;
		drawHungerBubble = 0;
		drawBoredBubble = 0;
		drawSickBubble = 0;
		drawDirtyBubble = 0;
		drawDyingBubble = 0;
		drawZzzs = 0;
		drawBall = 0;
		drawFood = 0;
		drawBroom = 0;
		drawPills = 0;
		drawFirstAid = 0;
		drawGameOver = 0;
		moveSprites = 0;

		case (currentState)
			DRAW_SCRN_START_STATE: begin
				drawStartScreen = 1;
			end
			DRAW_GAME_BG_STATE: begin
				drawGameBackground = 1;
			end	
			DRAW_HUNGER_BUBBLE_STATE: begin
				drawHungerBubble = 1;
			end
			DRAW_BORED_BUBBLE_STATE: begin
				drawBoredBubble = 1;
			end
			DRAW_SICK_BUBBLE_STATE: begin
				drawSickBubble = 1;
			end
			DRAW_DIRTY_BUBBLE_STATE: begin
				drawDirtyBubble = 1;
			end
			DRAW_DYING_BUBBLE_STATE: begin
				drawDyingBubble = 1;
			end
			DRAW_ZZZS_STATE: begin
				drawZzzs = 1;
			end
			DRAW_BALL_STATE: begin
				drawBall = 1;
			end
			DRAW_FOOD_STATE: begin
				drawFood = 1;
			end
			DRAW_BROOM_STATE: begin
				drawBroom = 1;
			end
			DRAW_PILLS_STATE: begin
				drawPills = 1;
			end
			DRAW_FIRSTAID_STATE: begin
				drawFirstAid = 1;
			end
			GAME_OVER_STATE: begin
				drawGameOver = 1;
			end
			MOVE_OBJECTS_STATE: begin
				moveSprites = 1;
			end
		endcase
	end

endmodule // control