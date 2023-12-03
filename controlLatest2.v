module control (
    clk, reset,
    go, plot_done, go_start,
    dne_signal_1, dne_signal_2,
    frame_tick,

	 hunger_enable,
	 bored_enable,
	 sick_enable,
	 dirty_enable,
	 dying_enable,
	 zzzs_enable,
	 dead_enable,
	 
	 foodGiven,
	 ballGiven,
	 broomGiven,
	 pillsGiven,
	 firstAidGiven,
	 
    draw_start_s,
	 draw_bg_s,
    draw_food_s,
	 draw_pills_s,
	 draw_first_aid_s,
	 draw_ball_s,
	 draw_broom_s,
	 
	 draw_hunger_bubble_s,
	 draw_bored_bubble_s,
	 draw_sick_bubble_s,
	 draw_dirty_bubble_s,
	 draw_dying_bubble_s,
	 draw_zzzs_s,
    move_objects_s,
	 current_state
);

    input clk, reset;
    input go, plot_done, go_start;
    input dne_signal_1, dne_signal_2;
    input frame_tick;
	 input hunger_enable, bored_enable, sick_enable, dirty_enable, dying_enable, zzzs_enable;

    output reg draw_start_s, draw_bg_s, draw_hunger_bubble_s, draw_bored_bubble_s, draw_sick_bubble_s, draw_dirty_bubble_s, draw_dying_bubble_s, draw_zzzs_s;
	 output reg draw_food_s, draw_pills_s, draw_first_aid_s, draw_broom_s, draw_ball_s, draw_dead_s;
    output reg move_objects_s;

    output reg [4:0] current_state;
    reg [4:0] next_state;

	 reg soundDone = 0;
	 reg itemGiven = foodGiven || ballGiven || broomGiven || pillsGiven || firstAidGiven;
	  
    // States.
    localparam  WAIT_START = 0,    // Wait before drawing START screen.
                DRAW_START = 1,    // Draw START screen.
                WAIT_BG = 2,    // Wait before drawing game background.
                DRAW_BG = 3,    // Draw game background.
                WAIT_OBJ = 4,    // Wait before drawing  objects.
                DRAW_FOOD = 5,
					 DRAW_PILLS = 6,
					 DRAW_FIRST_AID = 7,
					 DRAW_BALL = 8,
					 DRAW_BROOM = 9,
                MOVE_OBJECTS = 10,   // Move objects for the next cycle. (One cycle is from state 2 to 5).
                WAIT_FRAME_TICK = 11,   // Wait for frame tick.
					 DRAW_HUNGER_BUBBLE = 12,
					 WAIT_HUNGER_BUBBLE = 13,
					 DRAW_BORED_BUBBLE = 14,
					 WAIT_BORED_BUBBLE = 15,
					 DRAW_SICK_BUBBLE = 16,
					 WAIT_SICK_BUBBLE = 17,
					 DRAW_DIRTY_BUBBLE = 18,
					 WAIT_DIRTY_BUBBLE = 19,
					 DRAW_DYING_BUBBLE = 20,
					 WAIT_DYING_BUBBLE = 21,
					 DRAW_ZZZS = 22,
					 WAIT_ZZZS = 23,
					 PLAY_HUNGRY_AUDIO = 24;
					 WAIT_DEAD = 25;
					 DRAW_DEAD = 26;
					 
						
    // State table.
    always @ (*) begin
        case (current_state)
            WAIT_START:
                next_state = go ? DRAW_START : WAIT_START;
            DRAW_START: 
                next_state = go_start ? WAIT_BG : DRAW_START;
            WAIT_BG:
                next_state = go ? DRAW_BG : WAIT_BG;
            DRAW_BG:
				begin
					if (plot_done) begin
						if(itemGiven) begin
							next_state = WAIT_OBJ;
						end
						else if(dead_enable) begin
							next_state = WAIT_DEAD;
						end
						else if (hunger_enable) begin
							next_state = WAIT_HUNGER_BUBBLE;	
						end
						else if (bored_enable) begin
							next_state = WAIT_BORED_BUBBLE;
						end
						else if (sick_enable) begin
							next_state = WAIT_SICK_BUBBLE;
						end
						else if (dirty_enable) begin
							next_state = WAIT_DIRTY_BUBBLE;
						end
						else if (dying_enable) begin
							next_state = WAIT_DYING_BUBBLE;
						end
						else if (zzzs_enable) begin
							next_state = WAIT_ZZZS;
						end
					end
					else begin
						next_state = DRAW_BG;
					end
				end
				WAIT_DEAD:
					next_state = go ? DRAW_DEAD : WAIT_DEAD;
				DRAW_DEAD:
					next_state = reset ? WAIT_START : DRAW_DEAD; 
            WAIT_HUNGER_BUBBLE:
					next_state = go ? DRAW_HUNGER_BUBBLE : WAIT_HUNGER_BUBBLE;
				DRAW_HUNGER_BUBBLE:
					next_state = plot_done ? WAIT_FRAME_TICK : DRAW_HUNGER_BUBBLE;
					
				//next_state = plot_done ? PLAY_AUDIO : DRAW_HUNGER_BUBBLE;///
				//PLAY_HUNGRY_AUDIO: 
				//	next_state = soundDone ? WAIT_FRAME_TICK : PLAY_HUNGRY_AUDIO; // if soundDone is high, play audio, else go to the frame tick
				
				WAIT_BORED_BUBBLE:
					next_state = go ? DRAW_BORED_BUBBLE : WAIT_BORED_BUBBLE;
				DRAW_BORED_BUBBLE: 
					next_state = plot_done ? WAIT_FRAME_TICK : DRAW_BORED_BUBBLE;
				WAIT_SICK_BUBBLE:
					next_state = go ? DRAW_SICK_BUBBLE : WAIT_SICK_BUBBLE;
				DRAW_SICK_BUBBLE:
					next_state = plot_done? WAIT_FRAME_TICK : DRAW_SICK_BUBBLE;
				WAIT_DIRTY_BUBBLE:
					next_state = go ? DRAW_DIRTY_BUBBLE : WAIT_DIRTY_BUBBLE;
				DRAW_DIRTY_BUBBLE:
					next_state = plot_done ? WAIT_FRAME_TICK : DRAW_DIRTY_BUBBLE;	
				WAIT_DYING_BUBBLE:
					next_state = go ? DRAW_DYING_BUBBLE : WAIT_DYING_BUBBLE;
				DRAW_DYING_BUBBLE:
					next_state = plot_done ? WAIT_FRAME_TICK : DRAW_DYING_BUBBLE;
				WAIT_ZZZS:
					next_state = go ? DRAW_ZZZS : WAIT_ZZZS;
				DRAW_ZZZS:
					next_state = plot_done ? WAIT_FRAME_TICK : DRAW_ZZZS;
			 
			// PLAY_AUDIO: 
			//	next_state = soundDone ? WAIT_FRAME_TICK : PLAY_AUDIO; // if soundDone is high, play audio, else go to the frame tick
		 
//				WAIT_OBJ:
//					next_state = go ? DRAW_FOOD : WAIT_OBJ;
//					DRAW_FOOD:
//					next_state = plot_done ? MOVE_OBJECTS : DRAW_FOOD;
//					MOVE_OBJECTS:
//					next_state = WAIT_FRAME_TICK;
//					WAIT_FRAME_TICK:
//					next_state = frame_tick ? DRAW_BG : WAIT_FRAME_TICK;
				
				WAIT_OBJ:
				begin
					if(foodGiven) begin
						next_state = go ? DRAW_FOOD : WAIT_OBJ;
						DRAW_FOOD:
						next_state = plot_done ? MOVE_OBJECTS : DRAW_FOOD;
					end
					else if (pillsGiven) begin
						next_state = go ? DRAW_PILLS : WAIT_OBJ;
						DRAW_PILLS:
						next_state = plot_done ? MOVE_OBJECTS : DRAW_PILLS;
					end
					else if(firstAidGiven) begin
						next_state = go ? DRAW_FIRST_AID : WAIT_OBJ;
						DRAW_FIRST_AID:
						next_state = plot_done ? MOVE_OBJECTS : DRAW_FIRST_AID;
					end
					else if(broomGiven) begin
						next_state = go ? DRAW_BROOM : WAIT_OBJ;
						DRAW_BROOM:
						next_state = plot_done ? MOVE_OBJECTS : DRAW_BROOM;
					end
					else if(ballGiven) begin
						next_state = go ? DRAW_BALL : WAIT_OBJ;
						DRAW_BALL:
						next_state = plot_done ? MOVE_OBJECTS : DRAW_BALL;
					end
					else begin
						next_state = DRAW_BG;
					end
				end
				
				MOVE_OBJECTS:
				next_state = WAIT_FRAME_TICK;
				WAIT_FRAME_TICK:
				next_state = frame_tick ? DRAW_BG : WAIT_FRAME_TICK;
        endcase
    end

    // State switching and reset.
    always @ (posedge clk) begin
        if (reset)
            current_state <= WAIT_START;
        else
            current_state <= next_state;
    end

    // Output logic.
    always @ (*) begin
	     // Reset control signals.
	     draw_start_s = 0;
	     draw_bg_s = 0;
	     draw_hunger_bubble_s = 0;
	     draw_bored_bubble_s = 0;
		  draw_sick_bubble_s = 0;
		  draw_dirty_bubble_s = 0;
		  draw_dying_bubble_s = 0;
		  draw_zzzs_s = 0;
		  draw_food_s = 0;
		  draw_pills_s = 0;
		  draw_first_aid_s = 0;
		  draw_broom_s = 0;
		  draw_ball_s = 0;
        move_objects_s = 0;
        
        // Set control signals based on state.
        case (current_state)
            DRAW_START: begin
                draw_start_s = 1;
            end
				DRAW_BG: begin
                draw_bg_s = 1;
            end
				DRAW_DEAD: begin
					draw_dead_s = 1;
				end
				DRAW_HUNGER_BUBBLE: begin
					draw_hunger_bubble_s = 1;
				end
				DRAW_BORED_BUBBLE: begin
					draw_bored_bubble_s = 1;
				end
				DRAW_SICK_BUBBLE: begin
					draw_sick_bubble_s = 1;
				end
				DRAW_DIRTY_BUBBLE: begin
					draw_dirty_bubble_s = 1;
				end
				DRAW_DYING_BUBBLE: begin
					draw_dying_bubble_s = 1;
				end
				DRAW_ZZZS: begin
					draw_zzzs_s = 1;
				end
				DRAW_FOOD: begin
                draw_food_s = 1;
            end
				DRAW_PILLS: begin
					draw_pills_s = 1;
				end
				DRAW_FIRST_AID: begin
					draw_first_aid_s = 1;
				end
				DRAW_BROOM: begin
					draw_broom_s = 1;
				end
				DRAW_BALL: begin
					draw_ball_s = 1;
				end
            MOVE_OBJECTS: begin
                move_objects_s = 1;
            end
				
				//WAIT_HUNGER_BUBBLE: begin
				//	soundEnable = 1;
				//end
				
				//PLAY_AUDIO : begin
				//soundEnable = 1;
				//end
				
				//PLAY_HUNGRY_AUDIO: begin
				//snd_hungry_bubble = 1;
				//end
        
		  endcase
    end

endmodule // control