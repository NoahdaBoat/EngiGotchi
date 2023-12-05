//******************************************************************************************************
//
// Music module for ECE241 project
//
// Accepts off-chip lines as parameters to create an instance of the Audio_Controller module
// Other parameters are connected to wires that indicate the state of the pet and to turn sound off
//
// Data send/receive wires are defined to communicate with the Audio_Controller
//
// 
// The basis of audio generation and corresponding configuration modules were sourced from:
//
//		The Univerity of Toronto
//			Audio Controller introduction
//				https://www.eecg.utoronto.ca/~pc/courses/241/DE1_SoC_cores/audio/audio.html
//
//		Intel Corporation
//			Audio_Controller.v: Altera_UP_Avalon_Audio description and use and submodules
//			https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/18.1/University_Program_IP_Cores/
//					Audio_Video/Audio_and_Video_Config.pdf
//
//******************************************************************************************************

module music (
	clk, 
	reset,
	AUD_ADCDAT,
	AUD_BCLK,
	AUD_ADCLRCK,
	AUD_DACLRCK,
	AUD_XCK,
	AUD_DACDAT,
	 
	hungerEnable,
	boredEnable,
	sickEnable,
	dirtyEnable,
	dyingEnable,
	zzzsEnable,
	soundOff,
	soundVol
);

	input clk, reset;
	
	// Audio
	input				AUD_ADCDAT;

	// Bidirectionals
	inout				AUD_BCLK;
	inout				AUD_ADCLRCK;
	inout				AUD_DACLRCK;

	// Outputs
	output				AUD_XCK;
	output				AUD_DACDAT;
	
	// Pet states
	input hungerEnable;
	input boredEnable;
	input sickEnable;
	input dirtyEnable;
	input dyingEnable;
	input zzzsEnable;
	
	// Audio controls
	input soundOff;
	input soundVol;
	
	// Oscillator 'switch'
	reg snd;
	
	// Audio Wires
	wire audio_in_available;
	wire [31:0] left_channel_audio_in;
	wire [31:0] right_channel_audio_in;
	wire read_audio_in;

	wire	audio_out_allowed;
	wire	[31:0] left_channel_audio_out;
	wire	[31:0] right_channel_audio_out;
	wire	write_audio_out;
	
	// Delays for "Notes"
	wire [18:0] delay15 =	19'b0000_000_101110111000; // Do not use
	wire [18:0] delay14 =	19'b0001_000_101110111000; //~F
	wire [18:0] delay13 =	19'b0010_000_101110111000; //~F#
	wire [18:0] delay12 =	19'b0011_000_101110111000; //~B
	wire [18:0] delay11 =	19'b0100_000_101110111000; //~F#
	wire [18:0] delay10 =	19'b0101_000_101110111000; //~D
	wire [18:0] delay9  =	19'b0110_000_101110111000; //~B
	wire [18:0] delay8  =	19'b0111_000_101110111000; //~A
	wire [18:0] delay7  =	19'b1000_000_101110111000; //~F#
	wire [18:0] delay6  =	19'b1001_000_101110111000; //~E
	wire [18:0] delay5  =	19'b1010_000_101110111000; //~D
	wire [18:0] delay4  =	19'b1011_000_101110111000; //~C#
	wire [18:0] delay3  =	19'b1100_000_101110111000; //~B
	wire [18:0] delay2  =	19'b1101_000_101110111000; //~Bf
	wire [18:0] delay1  =	19'b1110_000_101110111000; //~A
	wire [18:0] delay0  =	19'b1111_000_101110111000; //~G
	
	// Enable/disable sounds within always block
	reg soundEnable = 1;
	
	// Master delay to generate tones
	reg [18:0] delay_cnt;
	reg [18:0] delay = 19'b0011_000_101110111000;
	
	// ~2 second melody loop
	wire [25:0] timer_limit = 26'd60000000;
	reg [26:0] timer_count = 0;
	reg [4:0] count = 0; //debug
	 
	// Creates loud or attenuated triangle wave by scaling the effective amplitude
	wire [31:0] sound = (!soundEnable || soundOff) ? 0 : snd ? 32'd10000000 : -32'd10000000;
	wire [31:0] soundq = (!soundEnable || soundOff) ? 0 : snd ? 32'd6000000 : -32'd6000000;

	// Main loop
	always@(posedge clk) begin
		
		// Main triangle wave oscillator
		if(delay_cnt == delay) begin
			delay_cnt <= 0;
			snd <= !snd;
		end else delay_cnt <= delay_cnt + 1;
		
		// All sounds are combinations of 8 on/off tones
		if (timer_count >= timer_limit)
		begin
			timer_count <= 0;
			count <= 0; //debug
		end
		else
			timer_count <= timer_count + 1;
			
		// Melody section: split timer into eight sections and determine pet state
		if ((timer_count >= 0) && (timer_count < timer_limit / 8))
		begin
			count <= 1; //debug
			if (hungerEnable) begin
				soundEnable <= 1;
				delay <= delay13;
			end else if (boredEnable) begin
				soundEnable <= 1;
				delay <= delay12;
			end else if (sickEnable) begin
				soundEnable <= 1;				
				delay <= delay4;
				delay <= delay + 3000000;
			end else if (dirtyEnable) begin
				soundEnable <= 1;				
				delay <= delay7;
			end else if (dyingEnable) begin
				soundEnable <= 1;
				delay <= delay12;
			end else if (zzzsEnable) begin
				soundEnable <= 1;
				delay <= delay2;
				delay <= delay - 5000;
			end else begin
				soundEnable <= 1;
				delay <= delay9;
			end
		end
		if ((timer_count >= timer_limit / 8 ) && (timer_count < timer_limit / 4))
		begin
			count <= 2; //debug
			if (hungerEnable) begin
				soundEnable <= 1;
				delay <= delay13;
			end else if (boredEnable) begin
				soundEnable <= 1;
				delay <= delay12;
			end else if (sickEnable) begin
				soundEnable <= 1;				
				delay <= delay6;
				delay <= delay + 3000000;
			end else if (dirtyEnable) begin
				soundEnable <= 0;				
				delay <= delay3;
			end else if (dyingEnable) begin
				soundEnable <= 1;
				delay <= delay12;
			end else if (zzzsEnable) begin
				soundEnable <= 1;
				delay <= delay2;
				delay <= delay - 5000;
			end else begin
				soundEnable <= 0;
				delay <= delay9;
			end
		end
		if ((timer_count >= timer_limit / 4) && (timer_count < ((timer_limit / 8) * 3)))
		begin
			count <= 3; //debug
			if (hungerEnable) begin
				soundEnable <= 1;
				delay <= delay12;
			end else if (boredEnable) begin
				soundEnable <= 0;
				delay <= delay5;
			end else if (sickEnable) begin
				soundEnable <= 1;				
				delay <= delay8;
				delay <= delay + 3000000;
			end else if (dirtyEnable) begin
				soundEnable <= 0;				
				delay <= delay7;
			end else if (dyingEnable) begin
				soundEnable <= 1;
				delay <= delay12;
			end else if (zzzsEnable) begin
				soundEnable <= 0;
				delay <= delay1;
			end else begin
				soundEnable <= 1;
				delay <= delay11;
			end
		end
		if ((timer_count >= ((timer_limit / 8) * 3)) && (timer_count < timer_limit / 2))
		begin
			count <= 4; //debug
			if (hungerEnable) begin
				soundEnable <= 0;
				delay <= delay8;
			end else if (boredEnable) begin
				soundEnable <= 0;
				delay <= delay5;
			end else if (sickEnable) begin
				soundEnable <= 1;				
				delay <= delay10;
				delay <= delay + 3000000;
			end else if (dirtyEnable) begin
				soundEnable <= 0;				
				delay <= delay3;
			end else if (dyingEnable) begin
				soundEnable <= 1;
				delay <= delay12;
			end else if (zzzsEnable) begin
				soundEnable <= 0;
				delay <= delay1;
			end else begin
				soundEnable <= 0;
				delay <= delay7;
			end
		end
		if ((timer_count > timer_limit / 2) && (timer_count < ((timer_limit / 8) * 5)))
		begin
			count <= 5; //debug
			if (hungerEnable) begin
				soundEnable <= 1;
				delay <= delay11;
			end else if (boredEnable) begin
				soundEnable <= 13;
				delay <= delay5;
			end else if (sickEnable) begin
				soundEnable <= 0;				
				delay <= delay4;
				delay <= delay + 3000000;
			end else if (dirtyEnable) begin
				soundEnable <= 1;				
				delay <= delay6;
			end else if (dyingEnable) begin
				soundEnable <= 1;
				delay <= delay13;
			end else if (zzzsEnable) begin
				soundEnable <= 0;
				delay <= delay1;
			end else begin
				soundEnable <= 1;
				delay <= delay9;
			end
		end
		if ((timer_count >= ((timer_limit / 8) * 5)) && (timer_count < ((timer_limit / 4) * 3)))
		begin
			count <= 6; //debug
			if (hungerEnable) begin
				soundEnable <= 0;
				delay <= delay6;
			end else if (boredEnable) begin
				soundEnable <= 13;
				delay <= delay5;
			end else if (sickEnable) begin
				soundEnable <= 0;				
				delay <= delay4;
				delay <= delay + 3000000;
			end else if (dirtyEnable) begin
				soundEnable <= 1;				
				delay <= delay6;
			end else if (dyingEnable) begin
				soundEnable <= 1;
				delay <= delay13;
			end else if (zzzsEnable) begin
				soundEnable <= 0;
				delay <= delay1;
			end else begin
				soundEnable <= 0;
				delay <= delay7;
			end
		end
		if ((timer_count >= ((timer_limit / 4) * 3)) && (timer_count < ((timer_limit / 8) * 7)))
		begin
			count <= 7; //debug
			if (hungerEnable) begin
				soundEnable <= 0;
				delay <= delay6;
			end else if (boredEnable) begin
				soundEnable <= 0;
				delay <= delay5;
			end else if (sickEnable) begin
				soundEnable <= 0;				
				delay <= delay4;
				delay <= delay + 3000000;
			end else if (dirtyEnable) begin
				soundEnable <= 1;				
				delay <= delay3;
			end else if (dyingEnable) begin
				soundEnable <= 1;
				delay <= delay13;
			end else if (zzzsEnable) begin
				soundEnable <= 0;
				delay <= delay1;
			end else begin
				soundEnable <= 1;
				delay <= delay7;
			end
		end
		if ((timer_count >= ((timer_limit / 8) * 7)) && (timer_count < timer_limit))
		begin
			count <= 8; //debug
			if (hungerEnable) begin
				soundEnable <= 0;
				delay <= delay6;
			end else if (boredEnable) begin
				soundEnable <= 0;
				delay <= delay5;
			end else if (sickEnable) begin
				soundEnable <= 0;				
				delay <= delay4;
				delay <= delay + 3000000;
			end else if (dirtyEnable) begin
				soundEnable <= 0;				
				delay <= delay3;
			end else if (dyingEnable) begin
				soundEnable <= 1;
				delay <= delay13;
			end else if (zzzsEnable) begin
				soundEnable <= 0;
				delay <= delay1;
			end else begin
				soundEnable <= 0;
				delay <= delay7;
			end
		end
	end
	 
	assign read_audio_in			= audio_in_available & audio_out_allowed;

	// Output channel assignment
	assign left_channel_audio_out	= soundVol ? sound : soundq;
	assign right_channel_audio_out	= soundVol ? sound : soundq;
	assign write_audio_out			= audio_in_available & audio_out_allowed;

	// Create an instance of the Audio_Controller module
	Audio_Controller Audio_Controller (
		// Inputs
		.CLOCK_50						(clk),

		.reset						(0),

		.clear_audio_in_memory		(),
		.read_audio_in				(read_audio_in),
		
		.clear_audio_out_memory		(),
		.left_channel_audio_out		(left_channel_audio_out),
		.right_channel_audio_out	(right_channel_audio_out),
		.write_audio_out			(write_audio_out),

		.AUD_ADCDAT					(AUD_ADCDAT),

		// Bidirectionals
		.AUD_BCLK					(AUD_BCLK),
		.AUD_ADCLRCK				(AUD_ADCLRCK),
		.AUD_DACLRCK				(AUD_DACLRCK),


		// Outputs
		.audio_in_available			(audio_in_available),
		.left_channel_audio_in		(left_channel_audio_in),
		.right_channel_audio_in		(right_channel_audio_in),

		.audio_out_allowed			(audio_out_allowed),

		.AUD_XCK					(AUD_XCK),
		.AUD_DACDAT					(AUD_DACDAT)

	);
endmodule
