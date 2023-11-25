module control #(parameter X_SCREEN_PIXELS = 8'd160, Y_SCREEN_PIXELS = 7'd120) ();

	
	reg [5:0] current_state, next_state, prev_state;
	
	input go, normal, sleep, hungry, boredom, illness, filthy, plot, move;
	input [3:0] hungerValue;
	input [3:0] boredomValue;
	input [3:0] filthyValue;
	input [3:0] illnessValue;



    localparam	Start = 6'd0, // Start the program, then draw the BG, pet, and age
		Default_State = 6'd1, // The state when the pet is healthy
		Done_Sleeping = 6'd2, // The state for when the pet is sleeping
		Increase_Age = 6'd3, // to increase the pets age after sleeping
		Calc_Stats = 6'd4, // to recalculate all the pets stats and determine which 'mood' to go into
		Hunger = 6'd5, // when the pet is hungry
		Bored = 6'd6, // when the pet is bored
		Dirty = 6'd7, // when the pet is dirty
		Sick = 6'd8, // when the pet is sick
		Dying = 6'd9, // when the pet is dying
		Dead = 6'd10, // when the pet dies
		User_End = 6'd11, // when the user wants to end
		User_End_Confirm = 6'd12, // the state for the user to confirm that they want to end
		Game_End = 6'd13, // The state when the game has ended
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
		Erase_Objects = 6'd27, // erases all objects on the screen - to be redrawn
		Draw_Game_Over = 6'd28, // Draws the game over screen
		Game_End_Wait = 6'd29, // Waits for the user to restart after a game end
		Draw_Dead = 6'd30, // Draws a skull and crossbones instead of the pet
		Move_FirstAid = 6'd31, // Moves the first aid to the the pet
		Move_Broom = 6'd32, // Moves the broom right to left
		Move_Ball = 6'd33, // Moves the ball up and down
		Move_Food = 6'd34, // Moves the food to the pet
		Move_Pills = 6'd35, // Moves the pills to the pet
		Draw_Sleeping = 6'd36, // Draws Z's above the pet
		Animate_Zs = 6'd37; // Animates the sleeping Z's
					
	 
	 
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
		
			Draw_Sleeping: next_state = sleep ? (plot ? Draw_Sleeping : Animate_Zs) : Increase_Age;

			Animate_Zs: move ? Animate_Zs : Done_Sleeping; 
			
			Done_Sleeping: next_state = Draw_BG;

			Increase_Age: next_state = Calc_Stats;

			Calc_Stats: if (normal)
					next_state = Default_State;
				else if (hungry)
					next_state = Hunger;
				else if (boredom)
					next_state = Bored;
				else if (filthy)
					next_state = Dirty;
				else if (illness)
					next_state = Sick;
				else
					next_state = Default_State;

			Hunger: if (hungerValue == 4'd4) begin
						next_state = Draw_Hunger;
						prev_state = Hunger;
					end
					else
						next_state = Calc_Stats;

			Draw_Hunger: next_state = bubbleDrawn ?  : Draw_Hunger;

			
			
			Bored: if (boredomValue == 4'd4) begin
					next_state = Dying;
					prev_state = Bored;
				end
				else
					next_state = Calc_Stats;

			Dirty: if (filthyValue == 4'd4) begin
					next_state = Sick;
					prev_state = Dirty;
				end
				else
					next_state = Calc_Stats;

			Sick: if (illnessValue == 4'd4) begin
					next_state = Dying;
					prev_state = Sick;
				end
				else
					next_state = Calc_Stats;

			Dying: if (firstAidGiven)
					next_state = prev_state;
					else if (deceased)
						next_state = Dead;
					else
						next_state = Dying;

            default: next_state = Start;
        
		endcase
    
	end // state_table


    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0


        case (current_state)
            LOAD_X: begin
                loadX = 1'b1;
            end
            LOAD_Y_COLOUR: begin
                loadYColour = 1'b1;
            end
			PLOT: begin
				plotOut = 1'b1;
				outPlot = 1'b1;
				done = 1'b0;
			end
			DRAW_BLACK: begin
				black = 1'b1;
				plotOut = 1'b1;
				done = 1'b0;
				
			end
			DONE_PLOTTING: begin
				done = 1'b1;
			end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= LOAD_X;
        else if (clear)
            current_state <= DRAW_BLACK;
		else
			current_state <= next_state;
    end // state_FFS

endmodule // control