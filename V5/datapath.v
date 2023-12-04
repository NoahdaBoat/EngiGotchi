module datapath (
    clk, reset,
	 foodGiven, ballGiven, broomGiven, pillsGiven, firstAidGiven,
	 hungry, bored, sick, dirty, dying, deceased, sleeping, age,
    draw_scrn_start,
	 draw_scrn_game_bg,
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
    move_objects,
    nextframe,
	 lifeCounter,
    plot_done,
    plot, x, y, color,
	 done_moving
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
	localparam maxLifeSpan = 9'd330,
		clockCycles = 26'h2FAF07F,
		//testClockCycles = 16'b1100001101010000, //for model sim testing
		hungerFreq = 5'd16,
		boredFreq = 5'd20,
		dirtyFreq = 5'd25,
		sickFreq = 5'd30,
		objStartX = 8'd50,
		objStartY = 7'd100,
		broomStartX = 8'd50, //change broom position later
		broomStartY = 7'd100, 
		sleepingFreq = 8'd45,
		sleepingTime = 3'd5,
		dyingToDeadFreq = 3'd4,
		stateToDyingFreq = 3'd4,
		X_SCREEN_PIXELS = 9'd320,
		Y_SCREEN_PIXELS = 9'd240;

    // IO + reg \\

    input clk, reset;

    input draw_scrn_start, draw_scrn_game_bg, draw_hungerbubble, draw_boredbubble, draw_sickbubble, draw_dirtybubble, draw_dyingbubble, draw_gameover;
	 input draw_zzzs;
    input draw_ball, draw_food, draw_broom, draw_pills, draw_firstAid;
    
	 input move_objects;
	
	 input foodGiven, ballGiven, broomGiven, pillsGiven, firstAidGiven;
	 //input draw_bg, draw_start, draw_end, draw_pet, draw_zs, draw_food, draw_ball, draw_broom, draw_pills, draw_firstAid, draw_hunger;
	 //input draw_bored, draw_dirty, draw_sick, draw_dying;
	
	 output reg hungry, bored, sick, dirty, dying, deceased, sleeping;
	 output reg [3:0] age;
    
    output plot_done;
    wire plot_done_scrn, plot_done_ball, plot_done_bubble, plot_done_sleepZ, plotDoneObj;
    assign plot_done = plot_done_scrn || plot_done_ball || plot_done_bubble || plot_done_sleepZ || plotDoneObj;
	 
	 
	 wire objGiven;
	 assign objGiven = foodGiven || broomGiven || pillsGiven || firstAidGiven;

    wire [8:0] next_x_scrn, ballX_next;
    wire [8:0] next_y_scrn, ballY_next;
	 wire [8:0] next_x_bubble, next_y_bubble;
	 wire [8:0] next_x_zzzs, next_y_zzzs;
	 wire [8:0] objX_next, objY_next;
    output reg [2:0] color;

    output plot;
    output reg [8:0] x;
    output reg [8:0] y;
    
	 output reg done_moving;
	 
    reg [6:0] rate;
	 
	 output reg [8:0] lifeCounter;
	
	 reg [25:0] everyCycleCtr; // counts up to 49.999999M
	
	 reg [8:0] obj_x;
	
	 reg [8:0] obj_y;
	
	 reg [8:0] ball_x;
	 reg [8:0] ball_y;

	
	 reg localHungry, localBored, localDirty, localSick, localDying, localSleeping, localDeceased;
	
	 //counters
	 reg [2:0] hungrytoDyingCtr;
	 reg [2:0] boredtoDyingCtr;
	 reg [2:0] dirtytoDyingCtr;
	 reg [2:0] sicktoDyingCtr;
	 reg [2:0] dyingtoDeadCtr;
	 reg [3:0] sleepCtr;
    
    reg pre_plot;
    wire is_transparent;
    assign plot = pre_plot && !is_transparent && !plot_done;
	 
	 reg [8:0] bubble_x;
	 reg [8:0] bubble_y;
	 reg [8:0] zzzs_x;
	 reg [8:0] zzzs_y;
	 
    wire draw, draw_scrn, draw_bbl, draw_sleepZ, draw_ballZ, draw_obj;
    assign draw = draw_scrn || draw_bbl || draw_sleepZ || draw_ballZ || draw_obj;
    assign draw_scrn = draw_scrn_start || draw_scrn_game_bg || draw_gameover;
    assign draw_bbl = draw_hungerbubble || draw_boredbubble || draw_sickbubble || draw_dirtybubble || draw_dyingbubble;
	 assign draw_sleepZ = draw_zzzs;
	 assign draw_ballZ = draw_ball;
	 assign draw_obj = draw_food || draw_broom || draw_pills || draw_firstAid;
	 
	 
	 wire moving_any;
	 assign moving_any = move_objects || ballGiven || foodGiven || broomGiven || pillsGiven || firstAidGiven;
      

     wire [20:0] frame_counter;
     output nextframe;
     assign nextframe = frame_counter == 834168;

    counter counter0 (
        .clk(clk),
        .en(1),
        .rst(reset),
        .out(frame_counter)
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
		if (localDeceased || draw_scrn_start || draw_gameover) begin
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
		if (moving_any) begin
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
		
		
		
		if (!localDying && !moving_any && !deceased) begin
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
        // Plot signal, x and y need to be delayed by one clock cycle
        // due to delay of retrieving data from memory.
        // The x and y offsets specify the top left corner of the sprite
        // that is being drawn.
        pre_plot <= draw;
		  
		  if (reset) begin
            
            ball_x <= 105;
            ball_y <= 50;
				bubble_x <= 175;
				bubble_y <= 70;
				zzzs_x <= 105;
				zzzs_y <= 70;
				
				//position of food, pills, first aid
				obj_x <= 105;
				obj_y <= 50;
            // reset the data
				done_moving <= 0;

	     end 
		  else if (draw_ball) begin
            x <= ballX_next + ball_x;
            y <= ballY_next + ball_y;

        end
		 else if (draw_obj) begin
			x <= objX_next + obj_x;
			y <= objY_next + obj_y;
			end
		  else if (move_objects && ballGiven) begin
				if (ball_y <= 145) begin
					ball_y <= ball_y + 1;
					ball_x <= ball_x;
				end
				else begin
					ball_y <= ball_y;
					ball_x <= ball_x;
				end
		  end
		 else if (move_objects && objGiven) begin
			if (obj_y <= 145) begin
				obj_y <= obj_y + 1;
				obj_x <= obj_x;
			end
			else begin
				obj_y <= obj_y;
				obj_x <= obj_x;
			end
		end	
		  else if (draw_hungerbubble || draw_boredbubble || draw_sickbubble || draw_dirtybubble || draw_dyingbubble) begin
				x <= bubble_x + next_x_bubble;
				y <= bubble_y + next_y_bubble;
		  end 
		  else if (draw_zzzs) begin
			x <= zzzs_x + next_x_zzzs;
			y <= zzzs_y + next_y_zzzs;
		  end
		  else if (draw_scrn_start || draw_scrn_game_bg || draw_gameover) begin
            x <= next_x_scrn;
            y <= next_y_scrn;
			end
			
			if (!ballGiven) begin
				ball_y <= 50;
				ball_x <= 105;
			end
			if (!foodGiven && !broomGiven && !pillsGiven && !firstAidGiven) begin
				obj_y <= 50;
				obj_x <= 105;
			end
    end

    // ### Plotters ### \\

    plotter #(
        .WIDTH_X(9),
        .WIDTH_Y(8),
        .MAX_X(320),
        .MAX_Y(240)
    ) plt_scrn (
        .clk(clk), .en(draw_scrn && !plot_done),
        .x(next_x_scrn), .y(next_y_scrn),
        .done(plot_done_scrn)
    );

	 plotter #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .MAX_X(32),
        .MAX_Y(32)
    ) plt_bubble (
        .clk(clk), .en(draw_bbl && !plot_done),
        .x(next_x_bubble), .y(next_y_bubble),
        .done(plot_done_bubble)
    );
	 
	 plotter #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .MAX_X(32),
        .MAX_Y(32)
    ) plt_zzzs (
        .clk(clk), .en(draw_sleepZ && !plot_done),
        .x(next_x_zzzs), .y(next_y_zzzs),
        .done(plot_done_sleepZ)
    );
	 
	 plotter #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .MAX_X(32),
        .MAX_Y(32)
    ) plot_ball (
        .clk(clk), .en(draw_ballZ && !plot_done),
        .x(ballX_next), .y(ballY_next),
        .done(plot_done_ball)
    );
	 
	 plotter #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .MAX_X(32),
        .MAX_Y(32)
    ) plt_obj (
        .clk(clk), .en(draw_obj && !plot_done),
        .x(objX_next), .y(objY_next),
        .done(plotDoneObj)
    );
	 
    // ### Start screen ### \\

    wire [2:0] scrn_start_color;

    sprite_ram_module #(
        .WIDTH_X(9),
        .WIDTH_Y(8),
        .RESOLUTION_X(320),
        .RESOLUTION_Y(240),
        .MIF_FILE("graphics/newstartscreen.mif")
    ) srm_scrn_start (
        .clk(clk),
        .x(next_x_scrn), .y(next_y_scrn),
        .color_out(scrn_start_color)
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
        .x(ballX_next), .y(ballY_next),
        .color_out(ball_colour)
    ); 


    wire [2:0] scrn_game_bg_color;

    sprite_ram_module #(
        .WIDTH_X(9),
        .WIDTH_Y(8),
        .RESOLUTION_X(320),
        .RESOLUTION_Y(240),
        .MIF_FILE("graphics/pet320x240.mif")
    ) srm_scrn_game_bg (
        .clk(clk),
        .x(next_x_scrn), .y(next_y_scrn),
		  .color_out(scrn_game_bg_color)
    );
	 
	 wire [2:0] gameover_colour;

    sprite_ram_module #(
        .WIDTH_X(9),
        .WIDTH_Y(8),
        .RESOLUTION_X(320),
        .RESOLUTION_Y(240),
        .MIF_FILE("graphics/death-screen.mif")
    ) gameover_screen (
        .clk(clk),
        .x(next_x_scrn), .y(next_y_scrn),
		  .color_out(gameover_colour)
    );
	 
	 wire [2:0] hunger_bubble_color;

    sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/hungerbubble.mif")
    ) srm_hungerbubble (
        .clk(clk),
        .x(next_x_bubble), .y(next_y_bubble),
		  .color_out(hunger_bubble_color)
    );
	 
	 wire [2:0] bored_bubble_color;
	 
	 sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/boredbubble.mif")
    ) srm_boredbubble (
        .clk(clk),
        .x(next_x_bubble), .y(next_y_bubble),
		  .color_out(bored_bubble_color)
    );

	 wire [2:0] sick_bubble_color;
	 
	 sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/sickbubble.mif")
    ) srm_sickbubble (
        .clk(clk),
        .x(next_x_bubble), .y(next_y_bubble),
		  .color_out(sick_bubble_color)
    );
	 
	 wire [2:0] dirty_bubble_color;
	 
	 sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/dirtybubble.mif")
    ) srm_dirtybubble (
        .clk(clk),
        .x(next_x_bubble), .y(next_y_bubble),
		  .color_out(dirty_bubble_color)
    );
	 
	 wire [2:0] dying_bubble_color;
	 
	 sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/dyingbubble.mif")
    ) srm_dyingbubble (
        .clk(clk),
        .x(next_x_bubble), .y(next_y_bubble),
		  .color_out(dying_bubble_color)
    );
	 
	 wire [2:0] sleepZ_color;
	 
	 sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/zzzs.mif")
    ) srm_zzzs (
        .clk(clk),
        .x(next_x_zzzs), .y(next_y_zzzs),
		  .color_out(sleepZ_color)
    );
	 
	 wire [2:0] food_colour;
	 
	 sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/chicken-leg.mif")
    ) food (
        .clk(clk),
        .x(objX_next), .y(objY_next),
		  .color_out(food_colour)
    );
	 
	 wire [2:0] broom_colour;
	 
	 sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/broom.mif")
    ) broom (
        .clk(clk),
        .x(objX_next), .y(objY_next),
		  .color_out(broom_colour)
    );
	 
	 wire [2:0] pills_colour;
	 
	 sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/pills.mif")
    ) pills (
        .clk(clk),
        .x(objX_next), .y(objY_next),
		  .color_out(pills_colour)
    );
	 
	 wire [2:0] firstAid_colour;
	 
	 sprite_ram_module #(
        .WIDTH_X(6),
        .WIDTH_Y(6),
        .RESOLUTION_X(32),
        .RESOLUTION_Y(32),
        .MIF_FILE("graphics/medkit.mif")
    ) firstAid (
        .clk(clk),
        .x(objX_next), .y(objY_next),
		  .color_out(firstAid_colour)
    );
	 
	 assign is_transparent = (draw_hungerbubble && hunger_bubble_color == 3) || (draw_boredbubble && bored_bubble_color == 3) || (draw_sickbubble && sick_bubble_color == 3) || (draw_dirtybubble && dirty_bubble_color == 3) || (draw_dyingbubble && dying_bubble_color == 3) || (draw_zzzs && sleepZ_color == 3) || (draw_ball && ball_colour == 3) || (draw_food && food_colour == 3) || (draw_broom && broom_colour == 3) || (draw_pills && pills_colour == 3) || (draw_firstAid && firstAid_colour == 3);
	 
    always @ (*) begin
			if (draw_scrn_start)
            color = scrn_start_color;
			else if (draw_scrn_game_bg)
            color = scrn_game_bg_color;
			else if (draw_gameover)
				color = gameover_colour;
			else if (draw_hungerbubble)
				color = hunger_bubble_color;
			else if (draw_boredbubble)
				color = bored_bubble_color;
			else if (draw_sickbubble)
				color = sick_bubble_color;
			else if (draw_dirtybubble)
				color = dirty_bubble_color;
			else if (draw_dyingbubble)
				color = dying_bubble_color;
			else if (draw_zzzs)
				color = sleepZ_color;
			else if (draw_ball)
            color = ball_colour;
			else if (draw_food)
				color = food_colour;
			else if (draw_broom)
				color = broom_colour;
			else if (draw_pills)
				color = pills_colour;
			else if (draw_firstAid)
				color = firstAid_colour;
        else
            color = 7;
    end

endmodule // datapath