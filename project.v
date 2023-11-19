/* This is a project developed for ECE241 at the University of Toronto */
/* By: Noah Monti & Kyle Saboto */
/* 11/18/2023 */

module project(CLOCK_50, SW, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY);
	// Parameters
	parameter X_SCREEN_PIXELS = 10'd640;
	parameter Y_SCREEN_PIXELS = 9'd480;
	
	// Inputs
	input CLOCK_50;
	
	input [9:0] SW;
	
	input [3:0] KEY;
	
	// Outputs
	output [9:0] LEDR;
	
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	output [6:0] HEX4;
	output [6:0] HEX5;
	
	// Wires
	
	// Regs
	
	// Modules
	fill #(.X_SCREEN_PIXELS(X_SCREEN_PIXELS), .Y_SCREEN_PIXELS(Y_SCREEN_PIXELS)) f0(); // VGA Controller (Top-Level)
	
	hex_decoder h0(.c(), .display());
	hex_decoder h1(.c(), .display());
	hex_decoder h2(.c(), .display());
	hex_decoder h3(.c(), .display());
	hex_decoder h4(.c(), .display());
	hex_decoder h5(.c(), .display());

endmodule // project