module control (
    clk, reset,

    go, plot_done, go_start,

    dne_signal_1, dne_signal_2,

    frame_tick,


    draw_scrn_start, draw_scrn_game_bg,
    draw_river_obj_1,
	 draw_hungerbubble,
	 draw_boredbubble,
	draw_sickbubble,
	draw_dirtybubble,
	draw_dyingbubble,
	draw_zzzs,
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
    input dne_signal_1, dne_signal_2;
    input frame_tick;
	 input hungerenable, boredenable, sickenable, dirtyenable, dyingenable, zzzsenable;

    output reg draw_scrn_start, draw_scrn_game_bg, draw_hungerbubble, draw_boredbubble, draw_sickbubble, draw_dirtybubble, draw_dyingbubble;
	 output reg draw_zzzs;
    output reg draw_river_obj_1;
    output reg move_objects;

    output reg [4:0] current_state;
    reg [4:0] next_state;

	 reg soundDone = 0;
	  
    // States.
    localparam  S_WAIT_START            = 0,    // Wait before drawing START screen.
                S_DRAW_SCRN_START       = 1,    // Draw START screen.
                S_WAIT_GAME_BG          = 2,    // Wait before drawing game background.
                S_DRAW_GAME_BG          = 3,    // Draw game background.
                S_WAIT_RIVER_OBJ        = 4,    // Wait before drawing river objects.
                S_DRAW_RIVER_OBJ_1      = 5,    // Draw river object 1.
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
			PLAY_HUNGRY_AUDIO = 20;
						
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
						if (hungerenable) begin
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
            WAIT_HUNGER_BUBBLE:
					next_state = go ? DRAW_HUNGER_BUBBLE : WAIT_HUNGER_BUBBLE;
				DRAW_HUNGER_BUBBLE:
				//next_state = plot_done ? PLAY_AUDIO : DRAW_HUNGER_BUBBLE;///
					next_state = plot_done ? S_WAIT_FRAME_TICK : DRAW_HUNGER_BUBBLE;///

				//PLAY_HUNGRY_AUDIO: 
				//	next_state = soundDone ? S_WAIT_FRAME_TICK : PLAY_HUNGRY_AUDIO; // if soundDone is high, play audio, else go to the frame tick
				
				WAIT_BORED_BUBBLE:
					next_state = go ? DRAW_BORED_BUBBLE : WAIT_BORED_BUBBLE;
				DRAW_BORED_BUBBLE: 
					next_state = plot_done ? S_WAIT_FRAME_TICK : DRAW_BORED_BUBBLE;
	
	WAIT_SICK_BUBBLE:
		next_state = go ? DRAW_SICK_BUBBLE : WAIT_SICK_BUBBLE;
	DRAW_SICK_BUBBLE:
		next_state = plot_done? S_WAIT_FRAME_TICK : DRAW_SICK_BUBBLE;
			
			WAIT_DIRTY_BUBBLE:
				next_state = go ? DRAW_DIRTY_BUBBLE : WAIT_DIRTY_BUBBLE;
			DRAW_DIRTY_BUBBLE:
				next_state = plot_done ? S_WAIT_FRAME_TICK : DRAW_DIRTY_BUBBLE;
				
			WAIT_DYING_BUBBLE:
				next_state = go ? DRAW_DYING_BUBBLE : WAIT_DYING_BUBBLE;
			DRAW_DYING_BUBBLE:
				next_state = plot_done ? S_WAIT_FRAME_TICK : DRAW_DYING_BUBBLE;
				
			WAIT_ZZZS:
				next_state = go ? DRAW_ZZZS : WAIT_ZZZS;
			DRAW_ZZZS:
				next_state = plot_done ? S_WAIT_FRAME_TICK : DRAW_ZZZS;
	    
		// PLAY_AUDIO: 
		//	next_state = soundDone ? S_WAIT_FRAME_TICK : PLAY_AUDIO; // if soundDone is high, play audio, else go to the frame tick
		 
		 S_WAIT_RIVER_OBJ:
                next_state = go ? S_DRAW_RIVER_OBJ_1 : S_WAIT_RIVER_OBJ;
            S_DRAW_RIVER_OBJ_1:
                next_state = plot_done ? S_MOVE_OBJECTS : S_DRAW_RIVER_OBJ_1;
            S_MOVE_OBJECTS:
                next_state = S_WAIT_FRAME_TICK;
            S_WAIT_FRAME_TICK:
                next_state = frame_tick ? S_DRAW_GAME_BG : S_WAIT_FRAME_TICK;
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
        // Reset control signals.
        draw_scrn_start = 0;
		  draw_scrn_game_bg = 0;
		  draw_hungerbubble = 0;
		  draw_boredbubble = 0;
		draw_sickbubble = 0;
		draw_dirtybubble = 0;
		draw_dyingbubble = 0;
		draw_zzzs = 0;
        draw_river_obj_1 = 0;
        move_objects = 0;
        
        // Set control signals based on state.
        case (current_state)
            S_DRAW_SCRN_START: begin
                draw_scrn_start = 1;
            end
				S_DRAW_GAME_BG: begin
                draw_scrn_game_bg = 1;
            end
            
				//WAIT_HUNGER_BUBBLE: begin
				//	soundEnable = 1;
				//end
				DRAW_HUNGER_BUBBLE: begin
					draw_hungerbubble = 1;
				end
				PLAY_HUNGRY_AUDIO: begin
					//snd_hungry_bubble = 1;
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
			
		//PLAY_AUDIO : begin
			//soundEnable = 1;

		//end
				S_DRAW_RIVER_OBJ_1: begin
                draw_river_obj_1 = 1;
            end
            S_MOVE_OBJECTS: begin
                move_objects = 1;
            end
        
		  endcase
    end

endmodule // control