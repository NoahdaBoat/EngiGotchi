module datapath #(parameter X_SCREEN_PIXELS = 8'd160, Y_SCREEN_PIXELS = 7'd120) ();

	input clk;
	
	input foodGiven, ballGiven, broomGiven, pillsGiven, firstAidGiven;
	input draw_bg, draw_start, draw_end, draw_pet, draw_zs, draw_food, draw_ball, draw_broom, draw_pills, draw_firstAid, draw_hunger;
	input draw_bored, draw_dirty, draw_sick, draw_dying;
	
	
	
	
	localparam maxLifeSpan = 9'd330,
		clockCycles = 26'h2FAF07F,
		hungerFreq = 5'd15,
		boredFreq = 5'd20,
		dirtyFreq = 5'd25,
		sickFreq = 5'd30,
		objStartX = 8'd50,
		objStartY = 7'd100,
		sleepingFreq = 7'h42,
		dyingToDeadFreq = 3'd4,
		stateToDyingFreq = 3'd4;
	
	
	reg [8:0] actualLifeSpan; // how many seconds the pet will actually live for
	
	reg [8:0] lifeCounter;
	
	reg [25:0] everyCycleCtr; // counts up to 49.9M
	
	reg [7:0] obj_x;
	
	reg [6:0] obj_y;
	
	reg [6:0] ball_y;
	
	reg localHungry, localBored, localDirty, localSick, localDying;
	
	reg [2:0] hungertoDyingCtr;
	reg [2:0] boredtoDyingCtr;
	reg [2:0] dirtytoDyingCtr;
	reg [2:0] sicktoDyingCtr;
	reg [2:0] dyingtoDeadCtr;
	
	// Outputs
	
	output reg hungry, bored, sick, dirty, dying, deceased;
	output 
	
	
	// ***Modules of Sprites*** \\
	
	// Background \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) game_bg (.clk(), .x(), .y(), .colour_out());

	// Start Screen \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) start_screen (.clk(), .x(), .y(), .colour_out());
	
	// End screen \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) end_screen (.clk(), .x(), .y(), .colour_out());
	
	// Pet \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) pet (.clk(), .x(), .y(), .colour_out());
	
	// Z's \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) zeds (.clk(), .x(), .y(), .colour_out());
	
	// Food \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) food (.clk(), .x(), .y(), .colour_out());
	
	draw_and_move #() move_food ();
	
	// Ball \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) ball (.clk(), .x(), .y(), .colour_out());
	
	move_ball #() move_the_ball ();
	
	// Broom \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) broom (.clk(), .x(), .y(), .colour_out());
	
	move_broom #() move_the_broom ();
	
	// Pills \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) pills (.clk(), .x(), .y(), .colour_out());
	
	draw_and_move #() move_pills ();
	
	// First Aid \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) firstaid (.clk(), .x(), .y(), .colour_out());
	
	draw_and_move #() move_firstaid ();
	
	// Hunger Bubble \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) hunger_bbl (.clk(), .x(), .y(), .colour_out());
	
	// Bored Bubble \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) bored_bbl (.clk(), .x(), .y(), .colour_out());
	
	// Dirty Bubble \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) dirty_bbl (.clk(), .x(), .y(), .colour_out());
	
	// Sick Bubble \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) sick_bbl (.clk(), .x(), .y(), .colour_out());
	
	// Dying Bubble \\
	sprite_ram_module #(.WIDTH_X(), .WIDTH_Y(), .RESOLUTION_X(), .RESOLUTION_Y(), .MIF_FILE()) dying_bbl (.clk(), .x(), .y(), .colour_out());
	
	//***************\\
	
	always@(posedge clk) begin
		
		if (!resetn) begin
			deceased <= 0;
			actualLifeSpan <= maxLifeSpan;
			lifeCounter <= 0;
			everyCycleCtr <= 0;
			obj_x <= objStartX;
			obj_y <= objStartY;
			ball_y <= objStartY;
			hungrytoDyingCtr <= 0;
			boredtoDyingCtr <= 0;
			dirtytoDyingCtr <= 0;
			sicktoDyingCtr <= 0;
		end
		
		// Life Counters
		
		if (lifeCounter == actualLifeSpan) begin // this is the death condition
			deceased <= 1;
		end
		else if (everyCycleCtr < clockCycles) begin // increment this on every clock cycle
			everyCycleCtr <= everyCycleCtr + 1;
		end
		else if (everyCycleCtr == clockCycles) begin // increment this once per second
			lifeCounter <= lifeCounter + 1;
			everyCycleCtr <= 0;
		end
		else begin
		//
		end
		
		// Sleep Enable
		if (actualLifeSpan % sleepingFreq) begin
			
		end
		
		// Hungry enable
		if (foodGiven) begin
			localHungry <= 0;
			hungrytoDyingCtr <= 0;
		end
		else if (lifeCounter % hungerFreq == 0) begin
			localHungry <= 1;
		end
		else begin
			localHungry <= 0;
		end
		
		if (localHungry) begin
			if (lifeCounter % stateToDyingFreq == 0) begin // if the pet is hungry and hasn't recieved food, increment the move to dying state counter
				hungrytoDyingCtr <= hungrytoDyingCtr + 1;
			end
		end
		
		
		
		// Bored enable
		if (ballGiven) begin
			localBored <= 0;
			boredtoDyingCtr <= 0;
		end
		else if (lifeCounter % boredFreq == 0) begin
			localBored <= 1;
		end
		else begin
			localBored <= 0;
		end
		
		if (localBored) begin
			if (lifeCounter % stateToDyingFreq == 0) begin
				boredtoDyingCtr <= boredtoDyingCtr + 1;
			end
		end

		
		
		// Dirty enable
		if (broomGiven) begin
			localDirty <= 0;
			dirtytoDyingCtr <= 0;
		end
		else if (lifeCounter % dirtyFreq == 0) begin
			localDirty <= 1;
		end
		else begin
			localDirty <= 0;
		end
		
		if (localDirty) begin
			if (lifeCounter % stateToDyingFreq == 0) begin
				dirtytoDyingCtr <= dirtytoDyingCtr + 1;
			end
		end
		
		
		
		// Sick enable
		if (pillsGiven) begin
			localSick <= 0;
			sicktoDyingCtr <= 0;
		end
		else if (lifeCounter % sickFreq == 0) begin
			localSick;
		end
		else begin
			localSick <= 0;
		end
		
		if (localSick) begin
			if (lifeCounter % stateToDyingFreq == 0) begin
				sicktoDyingCtr <= sicktoDyingCtr + 1;
			end
		end
		
		
		
		// Dying enable
		if (hungrytoDyingCtr == stateToDyingFreq || boredtoDyingCtr == stateToDyingFreq || dirtytoDyingCtr == stateToDyingFreq || sicktoDyingCtr == stateToDyingFreq) begin
			localDying <= 1;
		end
		else begin
			localDying <= 0;
		end
		
		// Dying to dead
		
		if (localDying) begin
			if (lifeCounter % dyingToDeadFreq == 0) begin
				dyingtoDeadCtr <= dyingtoDeadCtr + 1;
			end
		end
		
		if (dyingtoDeadCtr == dyingToDeadFreq) begin
			deceased <= 1;
		end
			
		
		
		// Assignments to outputs
		
		if (!deceased && localDying) begin
			dying <= 1;
		end
		else begin
			dying <= 0;
		end
		
		if (!deceased && !localDying && localSick) begin
			sick <= 1;
		end
		else begin
			sick <= 0;
		end
		
		if (!deceased && !localDying && !localSick && localHungry) begin
			hungry <= 1;
		end
		else begin
			hungry <= 0;
		end
		
		if (!deceased && !localDying && !localSick && !localHungry && localDirty) begin
			dirty <= 1;
		end
		else begin
			dirty <= 0;
		end
		
		if (!deceased && !localDying && !localSick && !localHungry && !localDirty && localBored) begin
			bored <= 1;
		end
		else begin
			bored <= 0;
		end
		
	end // always@
	
	
	
	
	
	
	
	


endmodule