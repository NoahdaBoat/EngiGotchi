module control (
    clk, reset,

    go, plot_done, go_start,

    frame_tick,
	 done_moving,
	 ballGiven,
	 foodGiven,
	 broomGiven,
	 pillsGiven,
	 firstAidGiven,
	 deceased,

    draw_scrn_start, draw_scrn_game_bg,
    draw_ball,
	 draw_hungerbubble,
	 draw_boredbubble,
	draw_sickbubble,
	draw_dirtybubble,
	draw_dyingbubble,
	draw_zzzs,
	draw_ball,
	draw_food,
	draw_broom,
	draw_pills,
	draw_firstAid,
	draw_gameover,
	 hungerenable,
	 boredenable,
	sickenable,
	dirtyenable,
	dyingenable,
	zzzsenable,
    move_objects,
	 current_state
);

    input clk, reset;
    input go, plot_done, go_start;
    input done_moving;
    input frame_tick;
	 input ballGiven, foodGiven, broomGiven, pillsGiven, firstAidGiven, deceased;
	 
	 input hungerenable, boredenable, sickenable, dirtyenable, dyingenable, zzzsenable;
    output reg draw_scrn_start, draw_scrn_game_bg, draw_hungerbubble, draw_boredbubble, draw_sickbubble, draw_dirtybubble, draw_dyingbubble, draw_gameover;
	 output reg draw_zzzs;
    output reg draw_ball, draw_food, draw_broom, draw_pills, draw_firstAid;
    output reg move_objects;

    output reg [4:0] current_state;
    reg [4:0] next_state;

	 reg soundDone = 0;
	 
	 wire itemGiven;
	 assign itemGiven = ballGiven || foodGiven || broomGiven || pillsGiven || firstAidGiven;
	  
    // States.
    localparam  S_WAIT_START            = 0,    // Wait before drawing START screen.
                S_DRAW_SCRN_START       = 1,    // Draw START screen.
                S_WAIT_GAME_BG          = 2,    // Wait before drawing game background.
                S_DRAW_GAME_BG          = 3,    // Draw game background.
                WAIT_OBJ					 = 4,
					 DRAW_BALL					 = 5,
                S_MOVE_OBJECTS          = 6,   // Move objects for the next cycle. (One cycle is from state 2 to 5).
                S_WAIT_FRAME_TICK       = 7,   // Wait for frame tick.
					 DRAW_HUNGER_BUBBLE = 8,
					 WAIT_HUNGER_BUBBLE = 9,
					 DRAW_BORED_BUBBLE = 10,
					 WAIT_BORED_BUBBLE = 11,
		DRAW_SICK_BUBBLE = 12,
		WAIT_SICK_BUBBLE = 13,
			DRAW_DIRTY_BUBBLE = 14,
			WAIT_DIRTY_BUBBLE = 15,
			DRAW_DYING_BUBBLE = 16,
			WAIT_DYING_BUBBLE = 17,
			DRAW_ZZZS = 18,
			WAIT_ZZZS = 19,
			DRAW_FOOD = 20,
			DRAW_BROOM = 21,
			DRAW_PILLS = 22,
			DRAW_FIRSTAID = 23,
			GAME_OVER = 24;
						
    // State table.
    always @ (*) begin
        case (current_state)
            S_WAIT_START:
                next_state = go ? S_DRAW_SCRN_START : S_WAIT_START;
            S_DRAW_SCRN_START: 
                next_state = go_start ? S_WAIT_GAME_BG : S_DRAW_SCRN_START;
            S_WAIT_GAME_BG:
                next_state = go ? S_DRAW_GAME_BG : S_WAIT_GAME_BG;
            S_DRAW_GAME_BG:
				begin
					if (plot_done) begin
						if (deceased) begin
							next_state = GAME_OVER;
						end
						else if (itemGiven) begin
							next_state = WAIT_OBJ;
						end
						else if (hungerenable) begin
							next_state = WAIT_HUNGER_BUBBLE;	
						end
						else if (boredenable) begin
							next_state = WAIT_BORED_BUBBLE;
						end
						else if (sickenable) begin
							next_state = WAIT_SICK_BUBBLE;
						end
						else if (dirtyenable) begin
							next_state = WAIT_DIRTY_BUBBLE;
						end
						else if (dyingenable) begin
							next_state = WAIT_DYING_BUBBLE;
						end
						else if (zzzsenable) begin
							next_state = WAIT_ZZZS;
						end
					end
					else begin
						next_state = S_DRAW_GAME_BG;
					end
				end
				WAIT_OBJ: begin
					if (ballGiven) begin
						next_state = DRAW_BALL;
					end
					else if (foodGiven) begin
						next_state = DRAW_FOOD;
					end
					else if (broomGiven) begin
						next_state = DRAW_BROOM;
					end
					else if (pillsGiven) begin
						next_state = DRAW_PILLS;
					end
					else if (firstAidGiven) begin
						next_state = DRAW_FIRSTAID;
					end
				end
            WAIT_HUNGER_BUBBLE:
					next_state = go ? DRAW_HUNGER_BUBBLE : WAIT_HUNGER_BUBBLE;
				DRAW_HUNGER_BUBBLE:
					next_state = plot_done ? (foodGiven ? DRAW_FOOD : S_WAIT_FRAME_TICK) : DRAW_HUNGER_BUBBLE;
				
				WAIT_BORED_BUBBLE:
					next_state = go ? DRAW_BORED_BUBBLE : WAIT_BORED_BUBBLE;
				DRAW_BORED_BUBBLE: 
					next_state = plot_done ? (ballGiven ? DRAW_BALL : S_WAIT_FRAME_TICK) : DRAW_BORED_BUBBLE;
	
				WAIT_SICK_BUBBLE:
					next_state = go ? DRAW_SICK_BUBBLE : WAIT_SICK_BUBBLE;
				DRAW_SICK_BUBBLE:
					next_state = plot_done ? (pillsGiven ? DRAW_PILLS : S_WAIT_FRAME_TICK) : DRAW_SICK_BUBBLE;
			
				WAIT_DIRTY_BUBBLE:
					next_state = go ? DRAW_DIRTY_BUBBLE : WAIT_DIRTY_BUBBLE;
				DRAW_DIRTY_BUBBLE:
					next_state = plot_done ? (broomGiven ? DRAW_BROOM : S_WAIT_FRAME_TICK) : DRAW_DIRTY_BUBBLE;
				
				WAIT_DYING_BUBBLE:
					next_state = go ? DRAW_DYING_BUBBLE : WAIT_DYING_BUBBLE;
				DRAW_DYING_BUBBLE:
					next_state = plot_done ? (firstAidGiven ? DRAW_FIRSTAID : S_WAIT_FRAME_TICK) : DRAW_DYING_BUBBLE;
				
				WAIT_ZZZS:
					next_state = go ? DRAW_ZZZS : WAIT_ZZZS;
				DRAW_ZZZS:
					next_state = plot_done ? S_WAIT_FRAME_TICK : DRAW_ZZZS;
		 
				DRAW_BALL:
						 next_state = plot_done ? S_MOVE_OBJECTS : DRAW_BALL;
				DRAW_FOOD:
					next_state = plot_done ? S_MOVE_OBJECTS : DRAW_FOOD;
				DRAW_BROOM:
					next_state = plot_done ? S_MOVE_OBJECTS : DRAW_BROOM;
				DRAW_PILLS:
					next_state = plot_done ? S_MOVE_OBJECTS : DRAW_PILLS;
				DRAW_FIRSTAID:
					next_state = plot_done ? S_MOVE_OBJECTS : DRAW_FIRSTAID;
				
            S_MOVE_OBJECTS:
                next_state = S_WAIT_FRAME_TICK; 
            S_WAIT_FRAME_TICK:
                next_state = frame_tick ? S_DRAW_GAME_BG : S_WAIT_FRAME_TICK;
					 
				GAME_OVER:
					next_state = plot_done ? (reset ? S_WAIT_START : GAME_OVER) : GAME_OVER;
				
        endcase
    end

    // State switching and reset.
    always @ (posedge clk) begin
        if (reset)
            current_state <= S_WAIT_START;
        else
            current_state <= next_state;
    end

    // Output logic.
    always @ (*) begin
		
	  draw_scrn_start = 0;
	  draw_scrn_game_bg = 0;
	  draw_hungerbubble = 0;
	  draw_boredbubble = 0;
		draw_sickbubble = 0;
		draw_dirtybubble = 0;
		draw_dyingbubble = 0;
		draw_zzzs = 0;
		draw_ball = 0;
		draw_food = 0;
		draw_broom = 0;
		draw_pills = 0;
		draw_firstAid = 0;
		draw_gameover = 0;
        move_objects = 0;
        
        case (current_state)
            S_DRAW_SCRN_START: begin
                draw_scrn_start = 1;
            end
				S_DRAW_GAME_BG: begin
                draw_scrn_game_bg = 1;
            end
            
				DRAW_HUNGER_BUBBLE: begin
					draw_hungerbubble = 1;
				end
				DRAW_BORED_BUBBLE: begin
					draw_boredbubble = 1;
				end
				DRAW_SICK_BUBBLE: begin
					draw_sickbubble = 1;
				end
				DRAW_DIRTY_BUBBLE: begin
					draw_dirtybubble = 1;
				end
				DRAW_DYING_BUBBLE: begin
					draw_dyingbubble = 1;
				end
				DRAW_ZZZS: begin
					draw_zzzs = 1;
				end
				DRAW_BALL: begin
					draw_ball = 1;
				end
				DRAW_FOOD: begin
					draw_food = 1;
				end
				DRAW_BROOM: begin
					draw_broom = 1;
				end
				DRAW_PILLS: begin
					draw_pills = 1;
				end
				DRAW_FIRSTAID: begin
					draw_firstAid = 1;
				end
				GAME_OVER: begin
					draw_gameover = 1;
				end
				
            S_MOVE_OBJECTS: begin
                move_objects = 1;
            end
        
		  endcase
    end

endmodule // control