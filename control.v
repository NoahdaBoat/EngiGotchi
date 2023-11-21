module control #(parameter X_SCREEN_PIXELS = 8'd160, Y_SCREEN_PIXELS = 7'd120) ();

	
	reg [5:0] current_state, next_state;

    localparam	Default = 3'd0,
					Sleeping = 3'd1,
					Increase_Age = 3'd2,
					
	 
	 
    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
            
            default: next_state = 
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