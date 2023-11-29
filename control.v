module control #(parameter X_SCREEN_PIXELS = 8'd160, Y_SCREEN_PIXELS = 7'd120) ();

	
	reg [5:0] current_state, next_state, prev_state;
	
	input clk;
	input go, normal, sleep, hungry, boredom, illness, filthy, plot, move, pet_dying, deceased;
	input foodGiven, ballGiven, broomGiven, pillsGiven, firstAidGiven;
	input bubbleDrawn, removeBubble;
	input [3:0] deathValue;
	output reg plotOut; // when we want to draw
	output reg moveOut; // want to animate something
	output reg draw_start, draw_bg, draw_pet, draw_age, draw_zs, draw_hunger, draw_bored, draw_dirty, draw_sick;
	output reg draw_dying, draw_end;
	output reg draw_food, draw_ball, draw_broom, draw_pills, draw_firstAid;


    localparam	Start = 6'd0, // Start the program, then draw the BG, pet, and age
		Default_State = 6'd1, // The state when the pet is healthy
		Done_Sleeping = 6'd2, // The state for when the pet is sleeping
		//Increase_Age = 6'd3, // to increase the pets age after sleeping
		Calc_Stats = 6'd4, // to recalculate all the pets stats and determine which 'mood' to go into
		Hunger = 6'd5, // when the pet is hungry
		Bored = 6'd6, // when the pet is bored
		Dirty = 6'd7, // when the pet is dirty
		Sick = 6'd8, // when the pet is sick
		Dying = 6'd9, // when the pet is dying
		Dead = 6'd10, // when the pet dies
		//User_End = 6'd11, // when the user wants to end
		//User_End_Confirm = 6'd12, // the state for the user to confirm that they want to end
		//Game_End = 6'd13, // The state when the game has ended
		Draw_Hunger = 6'd14, // draws the hungry bubble
		Draw_Bored = 6'd15, // draws the bored bubble
		Draw_Dirty = 6'd16, // draws the dirty bubble
		Draw_Sick = 6'd17, // draws the sick bubble
		Draw_Dying = 6'd18, // draws the dying bubble
		Draw_FirstAid = 6'd19, // draws the first aid to be moved
		Draw_Broom = 6'd20, // draws the broom to be moved
		Draw_Ball = 6'd21, // draws the ball to be moved
		Draw_Food = 6'd22, // draws the food to be moved
		Draw_Pills = 6'd23, // Draws the pills to be moved
		Draw_BG = 6'd24, // Draws the background
		Draw_Pet = 6'd25, // Draws the pet itself
		Draw_Age = 6'd26, // Draws the age indicator on the screen
		//Erase_Objects = 6'd27, // erases all objects on the screen - to be redrawn
		Draw_Game_Over = 6'd28, // Draws the game over screen
		Game_End_Wait = 6'd29, // Waits for the user to restart after a game end
		Draw_Dead = 6'd30, // Draws a skull and crossbones instead of the pet
		Move_FirstAid = 6'd31, // Moves the first aid to the the pet
		Move_Broom = 6'd32, // Moves the broom right to left
		Move_Ball = 6'd33, // Moves the ball up and down
		Move_Food = 6'd34, // Moves the food to the pet
		Move_Pills = 6'd35, // Moves the pills to the pet
		Draw_Sleeping = 6'd36, // Draws Z's above the pet
		Animate_Zs = 6'd37, // Animates the sleeping Z's
		Hunger_Wait = 6'd38, // Waits for the bubble to be removed
		Bored_Wait = 6'd39,
		Dirty_Wait = 6'd40,
		Sick_Wait = 6'd41,
		Dying_Wait = 6'd42;
	 
	 
    // Next state logic aka our state table
    always@(*)
    begin: state_table
        
		case (current_state)
			
			Draw_BG: next_state = deceased ? Draw_Game_Over : Draw_Pet;

			Draw_Pet: next_state = Draw_Age;

			Draw_Game_Over: next_state = plot ? Draw_Game_Over : Game_End_Wait;

			Draw_Age: next_state = Default_State;
			
			Start: next_state = go ? Draw_BG : Start;
		
			Default_State: next_state = sleep ? Draw_Sleeping : Calc_Stats;
		
			Draw_Sleeping: next_state = plot ? Draw_Sleeping : Animate_Zs;

			Animate_Zs: move ? Animate_Zs : Done_Sleeping; 
			
			Done_Sleeping: next_state = Draw_BG;

			//Increase_Age: next_state = Calc_Stats;

			Calc_Stats: if (pet_dying) // list is in priority order
				next_state = Dying;
				else if (illness)
					next_state = Sick;
				else if (hungry)
					next_state = Hungry;
				else if (filthy)
					next_state = Dirty;
				else if (boredom)
					next_state = Bored;
				else
					next_state = Default_State;
				

			Hungry: next_state = Draw_Hunger;

			Draw_Hunger: next_state = bubbleDrawn ? Hunger_Wait : Draw_Hunger; // if the bubble is drawn, go to calc stats
			
			Hunger_Wait: next_state = removeBubble ? Draw_BG : (pet_dying ? Dying : (foodGiven ? Draw_Food : Hunger_Wait)); // wait for the hunger buble, or if food is given
			
			Draw_Food: next_state = plot ? Draw_Food : Move_Food;
			
			Move_Food: next_state = move ? Move_Food: Draw_BG;
			
			Bored: next_state = Draw_Bored;
					
			Draw_Bored: next_state = bubbleDrawn ? Bored_Wait : Draw_Bored;
			
			Bored_Wait: next_state = removeBubble ? Draw_BG : (pet_dying ? Dying : (ballGiven ? Draw_Ball : Bored_Wait));
			
			Draw_Ball: next_state = plot ? Draw_Ball : Move_Ball;
			
			Move_Ball: next_state = move ? Move_Ball : Draw_BG;

			Dirty: next_state = Draw_Dirty;
				
			Draw_Dirty: next_state = bubbleDraw ? Dirty_Wait : Draw_Dirty;
			
			Dirty_Wait: next_state = removeBubble ? Draw_BG : (pet_dying ? Dying : (broomGiven ? Draw_Broom : Dirty_Wait));
			
			Draw_Broom: next_state = plot ? Draw_Broom : Move_Broom;
			
			Move_Broom: next_state = move ? Move_Broom : Draw_BG;

			Sick: next_state = Draw_Sick;
					
			Draw_Sick: next_state = bubbleDrawn ? Sick_Wait : Draw_Sick;
			
			Sick_Wait: next_state = removeBubble ? Draw_BG : (pet_dying ? Dying : (pillsGiven ? Draw_Pills : Sick_Wait));
			
			Draw_Pills: next_state = plot ? Draw_Pills : Move_Pills;
			
			Move_Pills: next_state = move ? Move_Pills : Draw_BG;

			Dying: if (deathValue == 4'd4)
					next_state = Dead;
					else if (deathValue >= 4'd0 && deathValue < 4'd4)
						next_state = Draw_Dying;
					else
						next_state = Calc_Stats
				
			Draw_Dying: next_state = bubbleDrawn ? Dying_Wait : Draw_Dying;
			
			Dying_Wait: next_state = removeBubble ? Draw_BG : (deceased ? Dead : (firstAidGiven ? Draw_FirstAid : Dying_Wait));
			
			Draw_FirstAid: next_state = plot ? Draw_FirstAid : Move_FirstAid;
			
			Move_FirstAid: next_state = move ? Move_FirstAid : Braw_BG;
			
			Dead: next_state = Draw_Dead; // left ambiguous
			
			Draw_Dead: next_state = Draw_Game_Over; // left ambiguous
			
			//User_End:
			
			//User_End_Confirm:
			
			Game_End_Wait: next_state = go ? Draw_BG : Game_End_Wait;
		  
		endcase
    
	end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
		  plotOut = 0;
		  moveOut = 0;
		  draw_start = 0;
		  draw_bg = 0;
		  draw_pet = 0;
		  draw_age = 0;
		  draw_zs = 0;
		  draw_hunger = 0;
		  draw_bored = 0;
		  draw_dirty = 0;
		  draw_sick = 0;
		  draw_dying = 0;
		  draw_end = 0;
		  draw_food = 0;
		  draw_ball = 0;
		  draw_broom = 0;
		  draw_pills = 0;
		  draw_firstAid = 0;

        case (current_state)
			Start: draw_start = 1;
			Draw_BG: draw_bg = 1;
			Draw_Pet: draw_pet = 1;
			Draw_Age: draw_age = 1;
			Draw_Sleeping: begin
				plotOut = 1;
				draw_zs = 1;
			end
			Animate_Zs: moveOut = 1;
			
			//
			Draw_Hunger: begin
				plotOut = 1;
				draw_hunger = 1;
			end
			Draw_Food: begin
				plotOut = 1;
				draw_food = 1;
			end
			Move_Food: begin
				moveOut = 1;
				draw_food = 1;
			
			//
			Draw_Bored: begin
				plotOut = 1;
				draw_bored = 1;
			end
			Draw_Ball: begin
				plotOut = 1;
				draw_ball = 1;
			end
			Move_Ball: begin
				moveOut = 1;
				draw_ball = 1;
			
			//
			Draw_Dirty: begin
				plotOut = 1;
				draw_dirty = 1;
			end
			Draw_Broom: begin
				plotOut = 1;
				draw_broom = 1;
			end
			Move_Broom: begin
				moveOut = 1;
				draw_broom = 1;
				
			//
			Draw_Sick: begin
				plotOut = 1;
				draw_sick = 1;
			end
			Draw_Pills: begin
				plotOut = 1;
				draw_pills = 1;
			end
			Move_Pills: begin
				moveOut = 1;
				draw_pills = 1;
				
			//
			Draw_Dying: begin
				plotOut = 1;
				draw_dying = 1;
			end
			Draw_FirstAid: begin
				plotOut = 1;
				draw_firstAid = 1;
			end
			Move_FirstAid: begin
				moveOut = 1;
				draw_firstAid = 1;
				
			Draw_Game_Over: draw_end = 1;
			
			end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= Start;
		else
			current_state <= next_state;
    end // state_FFS

endmodule // control
