/*
 * 2D Cube Simulator
 * CSCB58 Summer 2017 Final Project
 * Team members:
 * 	Shuang Wu
 *	Pingfan Xu
 */
module 2DCubeSimulator(
  LEDR,
  CLOCK_50,						//	On Board 50 MHz
  KEY,
  SW,
  VGA_CLK,   						//	VGA Clock
  VGA_HS,							//	VGA H_SYNC
  VGA_VS,							//	VGA V_SYNC
  VGA_BLANK_N,						//	VGA BLANK
  VGA_SYNC_N,						//	VGA SYNC
  VGA_R,   						//	VGA Red[9:0]
  VGA_G,	 						//	VGA Green[9:0]
  VGA_B   						//	VGA Blue[9:0]
  );
  output [7:0] LEDR;
	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

// Declare your inputs and outputs here
// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;	                        //	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

//signals
reg writeEn, draw, stopcount, draw_all;

//colour
wire [2:0] colour;
//X8, Y8, Colour3
reg [1025:0] code = 1026'b0000100000001000110_0000110000001000110_0001000000001000110_0000100000001100110_0000110000001100110_0001000000001100110_0000100000010000110_0000110000010000110_0001000000010000110_0001100000001000101_0001110000001000101_0010000000001000101_0001100000001100101_0001110000001100101_0010000000001100101_0001100000010000101_0001110000010000101_0010000000010000101_0010100000001000001_0010110000001000001_0011000000001000001_0010100000001100001_0010110000001100001_0011000000001100001_0010100000010000001_0010110000010000001_0011000000010000001_0000100000011000111_0000110000011000111_0001000000011000111_0000100000011100111_0000110000011100111_0001000000011100111_0000100000100000111_0000110000100000111_0001000000100000111_0001100000011000100_0001110000011000100_0010000000011000100_0001100000011100100_0001110000011100100_0010000000011100100_0001100000100000100_0001110000100000100_0010000000100000100_0010100000011000010_0010110000011000010_0011000000011000010_0010100000011100010_0010110000011100010_0011000000011100010_0010100000100000010_0010110000100000010_0011000000100000010;//1025:0
reg [1025:0] codereg, coderegshifter;
wire [7:0] input_x, input_y, X, Y;


// Create an Instance of a VGA controller - there can be only one!
// Define the number of colours as well as the initial background
// image file (.MIF) for the controller.
vga_adapter VGA(
    .resetn(KEY[3]),
    .clock(CLOCK_50),
    .colour(colour),
    .x(input_x),
    .y(input_y),
    .plot(writeEn),
    /* Signals for the DAC to drive the monitor. */
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_HS(VGA_HS),
    .VGA_VS(VGA_VS),
    .VGA_BLANK(VGA_BLANK_N),
    .VGA_SYNC(VGA_SYNC_N),
    .VGA_CLK(VGA_CLK));
  defparam VGA.RESOLUTION = "160x120";
  defparam VGA.MONOCHROME = "FALSE";
  defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
  defparam VGA.BACKGROUND_IMAGE = "black.mif";

	reg [1:0] current_state, next_state;
	localparam DRAW_ALL = 2'b00, REST = 2'b01, ADJUSTMENT = 2'b11, TEMP = 2'b10;

	//Main FSM
  always@(posedge CLOCK_50)
  begin
    case (current_state)
		DRAW_ALL: next_state = draw_all? REST : DRAW_ALL;
		REST: next_state = (~KEY[0])? ADJUSTMENT : REST;// KEY[0] for load the operation code ie.up&cw
		ADJUSTMENT: next_state = TEMP;
		TEMP: next_state = DRAW_ALL;
	 endcase
  end

	//several actions can be performed;
	localparam UP_CW = 8'b0100_0001, UP_CCW = 8'b0000_0001, DOWN_CW = 8'b0100_0010, DOWN_CCW = 8'b0000_0010, LEFT_CW = 8'b0100_0100, LEFT_CCW = 8'b0000_0100;
	localparam RIGHT_CW = 8'b0100_1000, RIGHT_CCW = 8'b0000_1000, FRONT_CW = 8'b0101_0000, FRONT_CCW = 8'b0001_0000, BACK_CW = 8'b0110_0000, BACK_CCW = 8'b0010_0000;


	//Corresponding FSM actions;
  always@(posedge CLOCK_50)
  begin
	draw_all <= 1'b0;
    case (current_state)
    DRAW_ALL: begin
					if (coderegshifter[18:0] == 19'd0)
					begin
					draw_all <= 1'b1;
					end
					else if (delay && (coderegshifter[18:0] != 19'd0))
					begin
					writeEn <= 1;
					end
					else if (!delay && (coderegshifter[18:0] != 19'd0))
					begin
					test <= 1'b1;//to check whether this condition
					coderegshifter[1025:0] = (coderegshifter[1025:0] >> 19);
					end
					current_state <= next_state;
		end
    REST: begin
			current_state <= next_state;
			end
    ADJUSTMENT:
		begin
		if (SW[7] == 1)//if reset
		begin
			codereg <= code;//default value;
		end
                else if (SW[7:0] == UP_CW)//if up&cw, change wires and then load into a reg for later shifting
		begin
			codereg[971:969] <= codereg[1009:1007];	  // 1->3
			codereg[1009:1007] <= codereg[895:893];	  // 7->1
			codereg[895:893] <= codereg[857:855];     // 9->7
			codereg[857:855] <= codereg[971:969];	  // 3->9
			codereg[914:912] <= codereg[990:988];	  // 2->6
			codereg[990:988] <= codereg[952:950];  // 4->2
			codereg[952:950] <= codereg[876:874];  // 8->4
			codereg[876:874] <= codereg[914:912];	  // 6->8

			codereg[838:836] <= codereg[667:665];		//front to left
			codereg[819:817] <= codereg[648:646];		//
			codereg[800:798] <= codereg[629:627];		//

			codereg[667:665] <= codereg[325:323];		//right to front
			codereg[648:646] <= codereg[306:304];		//
			codereg[629:627] <= codereg[287:285];		//

			codereg[325:323] <= codereg[154:152];		//back to right
			codereg[306:304] <= codereg[135:133];		//
			codereg[287:285] <= codereg[116:114];

			codereg[154:152] <= codereg[838:836];		//left to back
			codereg[135:133] <= codereg[819:817];
			codereg[116:114] <= codereg[800:798];


		end
                else if (SW[7:0] == UP_CCW)//if up&ccw,
		begin

			codereg[895:893] <= codereg[1009:1007];	  	// 1->7
			codereg[1009:1007] <= codereg[971:969]; 	// 3->1
			codereg[971:969] <= codereg[857:855];           // 9->3
			codereg[857:855] <= codereg[895:893];		// 7->9

			codereg[952:950] <= codereg[990:988];		// 2->4
			codereg[990:988] <= codereg[914:912];		// 6->2
			codereg[914:912] <= codereg[876:874];		// 8->6
			codereg[876:874] <= codereg[952:950];		// 4->8


			codereg[325:323] <= codereg[667:665];		//front to right
			codereg[306:304] <= codereg[648:646];		//
			codereg[287:285] <= codereg[629:627];		//

			codereg[667:665] <= codereg[838:836];		//left to front
			codereg[648:646] <= codereg[819:817];
			codereg[629:627] <= codereg[800:798];

			codereg[838:836] <= codereg[154:152];		//back to left
			codereg[819:817] <= codereg[135:133];
			codereg[800:798] <= codereg[116:114];

			codereg[154:152] <= codereg[325:323];		//right to back
			codereg[135:133] <= codereg[306:304];
			codereg[116:114] <= codereg[287:285];

		end
                else if (SW[7:0] == DOWN_CW)//if down&cw,
		begin

			codereg[458:456] <= codereg[496:494];	  // 28->30
			codereg[496:494] <= codereg[382:380];		// 34->28
			codereg[382:380] <= codereg[344:342];            // 36->34
			codereg[344:342] <= codereg[458:456];	  // 30->36

			codereg[401:399] <= codereg[477:475];			  // 29->33
			codereg[477:475] <= codereg[439:437];			  // 31->29
			codereg[439:437] <= codereg[363:361];			  // 35->31
			codereg[363:361] <= codereg[401:399];			  // 33->35


			codereg[211:209] <= codereg[553:551];		//front to right
			codereg[192:190] <= codereg[534:532];
			codereg[173:171] <= codereg[515:513];

			codereg[553:551] <= codereg[724:722];		//left to front
			codereg[534:532] <= codereg[705:703];
			codereg[515:513] <= codereg[686:684];

			codereg[724:722] <= codereg[40:38];		//back to left
			codereg[705:703] <= codereg[21:19];
			codereg[686:684] <= codereg[2:0];

			codereg[40:38] <= codereg[211:209];		//right to back
			codereg[21:19] <= codereg[192:190];
			codereg[2:0] <= codereg[173:171];

		end
                else if (SW[7:0] == DOWN_CCW)//if down&ccw,
		begin

			codereg[382:380] <= codereg[496:494];	  	// 28->34
			codereg[496:494] <= codereg[458:456]; 	// 30->28
			codereg[458:456] <= codereg[344:342];           // 36->30
			codereg[344:342] <= codereg[382:380];		// 34->36

			codereg[439:437] <= codereg[477:475];			// 29->31
			codereg[477:475] <= codereg[401:399];		// 33->29
			codereg[401:399] <= codereg[363:361];		// 35->33
			codereg[363:361] <= codereg[439:437];		// 31->35


			codereg[724:722] <= codereg[553:551];		//front to left
			codereg[705:703] <= codereg[534:532];
			codereg[686:684] <= codereg[515:513];

			codereg[553:551] <= codereg[211:209];		//right to front
			codereg[534:532] <= codereg[192:190];
			codereg[515:513] <= codereg[173:171];

			codereg[211:209] <= codereg[40:38];		//back to right
			codereg[192:190] <= codereg[21:19];
			codereg[173:171] <= codereg[2:0];

			codereg[40:38] <= codereg[724:722];		//left to back
			codereg[21:19] <= codereg[705:703];
			codereg[2:0] <= codereg[686:684];

		end
                else if (SW[7:0] == LEFT_CW)//if left&cw,
		begin

			codereg[800:798] <= codereg[838:836];	  // 10->12
			codereg[838:836] <= codereg[724:722];		// 16->10
			codereg[724:722] <= codereg[686:684];          // 18->16
			codereg[686:684] <= codereg[800:798];			  // 12->18

			codereg[743:741] <= codereg[819:817];			  // 11->15
			codereg[819:817] <= codereg[781:779];			  // 13->11
			codereg[781:779] <= codereg[705:703];			  // 17->13
			codereg[705:703] <= codereg[743:741];			  // 15->17

			//front to down
			codereg[496:494] <= codereg[667:665];		//19->28
			codereg[439:437] <= codereg[610:608];		//22->31
			codereg[382:380] <= codereg[553:551];		//25->34
			//up to front
			codereg[667:665] <= codereg[1009:1007];		//1->19
			codereg[610:608] <= codereg[952:950];		//4->22
			codereg[553:551] <= codereg[895:893];		//7->25
			//back to up
			codereg[1009:1007] <= codereg[2:0];		//54->1
			codereg[952:950] <= codereg[59:57];		//51->4
			codereg[895:893] <= codereg[116:114];		//48->7
			//down to back
			codereg[2:0] <= codereg[496:494];		//28->54
			codereg[59:57] <= codereg[439:437];		//31->51
			codereg[116:114] <= codereg[382:380];		//34->48

		end
		else if (SW[7:0] == LEFT_CCW)
		begin

			codereg[724:722] <= codereg[838:836];	  	// 10->16
			codereg[838:836] <= codereg[800:798]; 	// 12->10
			codereg[800:798] <= codereg[686:684];           // 18->12
			codereg[686:684] <= codereg[724:722];		// 16->18

			codereg[781:779] <= codereg[819:817];			// 11->13
			codereg[819:817] <= codereg[743:741];		// 15->11
			codereg[743:741] <= codereg[705:703];		// 17->15
			codereg[705:703] <= codereg[781:779];		// 13->17

			//front to up
			codereg[1009:1007] <= codereg[667:665];
			codereg[952:950] <= codereg[610:608];
			codereg[895:893] <= codereg[553:551];
			//up to back
			codereg[2:0] <= codereg[1009:1007];
			codereg[59:57] <= codereg[952:950];
			codereg[116:114] <= codereg[895:893];
			//back to down
			codereg[496:494] <= codereg[2:0];
			codereg[439:437] <= codereg[59:57];
			codereg[382:380] <= codereg[116:114];
			//down to front
			codereg[667:665] <= codereg[496:494];
			codereg[610:608] <= codereg[439:437];
			codereg[553:551] <= codereg[382:380];
		end
		else if (SW[7:0] == RIGHT_CW)
		begin

			codereg[287:285] <= codereg[325:323];	  // 37->39
			codereg[325:323] <= codereg[211:209];		// 43->37
			codereg[211:209] <= codereg[173:171];           // 45->43
			codereg[173:171] <= codereg[287:285];			  // 39->45

			codereg[230:228] <= codereg[306:304];			  // 38->42
			codereg[306:304] <= codereg[268:266];			  // 40->38
			codereg[268:266] <= codereg[192:190];			  // 44->40
			codereg[192:190] <= codereg[230:228];			  // 42->44

			//front to up
			codereg[971:969] <= codereg[629:627];		//21->3
			codereg[914:912] <= codereg[572:570];		//24->6
			codereg[857:855] <= codereg[515:513];		//27->9
			//up to back
			codereg[40:38] <= codereg[971:969];		//3->52
			codereg[97:95] <= codereg[914:912];	//6->49
			codereg[154:152] <= codereg[857:855];		//9->46
			//back to down
			codereg[458:456] <= codereg[40:38];		//52->30
			codereg[401:399] <= codereg[97:95];		//49->33
			codereg[344:342] <= codereg[154:152];		//46->36
			//down to front
			codereg[629:627] <= codereg[458:456];		//30->21
			codereg[572:570] <= codereg[401:399];		//33->24
			codereg[515:513] <= codereg[344:342];		//36->27

		end
		else if (SW[7:0] == RIGHT_CCW)
		begin

			codereg[211:209] <= codereg[325:323];	  	// 37->43
			codereg[325:323] <= codereg[287:285]; 	// 39->37
			codereg[287:285] <= codereg[173:171];           // 45->39
			codereg[173:171] <= codereg[211:209];		// 43->45

			codereg[268:266] <= codereg[306:304];			// 38->40
			codereg[306:304] <= codereg[230:228];		// 42->38
			codereg[230:228] <= codereg[192:190];		// 44->42
			codereg[192:190] <= codereg[268:266];		// 40->44

			codereg[458:456] <= codereg[629:627];
			codereg[401:399] <= codereg[572:570];
			codereg[344:342] <= codereg[515:513];
			//up to front
			codereg[629:627] <= codereg[971:969];
			codereg[572:570] <= codereg[914:912];
			codereg[515:513] <= codereg[857:855];
			//back to up
			codereg[971:969] <= codereg[40:38];
			codereg[914:912] <= codereg[97:95];
			codereg[857:855] <= codereg[154:152];
			//down to back
			codereg[40:38] <= codereg[458:456];
			codereg[97:95] <= codereg[401:399];
			codereg[154:152] <= codereg[344:342];

		end
		else if (SW[7:0] == FRONT_CW)
		begin
			codereg[629:627] <= codereg[667:665];	  // 19->21
			codereg[667:665] <= codereg[553:551];		// 25->19
			codereg[553:551] <= codereg[515:513];            // 27->25
			codereg[515:513] <= codereg[629:627];			  // 21->27

			codereg[572:570] <= codereg[648:646];			  // 20->24
			codereg[648:646] <= codereg[610:608];			  // 22->20
			codereg[610:608] <= codereg[534:532];			  // 26->22
			codereg[534:532] <= codereg[572:570];			  // 24->26


			codereg[325:323] <= codereg[895:893];	 //UP to Right
			codereg[268:266] <= codereg[876:874];
			codereg[211:209] <= codereg[857:855];

			codereg[458:456] <= codereg[325:323];	//Right to Down
			codereg[477:475] <= codereg[268:266];
			codereg[496:494] <= codereg[211:209];

			codereg[686:684] <= codereg[458:456];	//Down to Left
			codereg[743:741] <= codereg[477:475];
			codereg[800:798] <= codereg[496:494];

			codereg[895:893] <= codereg[686:684];	//Left to Up
			codereg[876:874] <= codereg[743:741];
			codereg[857:855] <= codereg[800:798];
		end
		else if (SW[7:0] == FRONT_CCW)
		begin
			codereg[553:551] <= codereg[667:665];	  	// 19->25
			codereg[667:665] <= codereg[629:627]; 		// 21->19
			codereg[629:627] <= codereg[515:513];           // 27->21
			codereg[515:513] <= codereg[553:551];		// 25->27

			codereg[610:608] <= codereg[648:646];		// 20->22
			codereg[648:646] <= codereg[572:570];		// 24->20
			codereg[572:570] <= codereg[534:532];		// 26->24
			codereg[534:532] <= codereg[610:608];		// 22->26

			codereg[686:684] <= codereg[895:893];	 //UP to Left
			codereg[743:741] <= codereg[876:874];
			codereg[800:798] <= codereg[857:855];

			codereg[458:456] <= codereg[686:684];	//Left to Down
			codereg[477:475] <= codereg[743:741];
			codereg[496:494] <= codereg[800:798];

			codereg[325:323] <= codereg[458:456];	//Down to Right
			codereg[268:266] <= codereg[477:475];
			codereg[211:209] <= codereg[496:494];

			codereg[895:893] <= codereg[325:323];	//Right to Up
			codereg[876:874] <= codereg[268:266];
			codereg[857:855] <= codereg[211:209];
		end
		else if (SW[7:0] == BACK_CW)
		begin
			codereg[116:114] <= codereg[154:152];	  // 46->48
			codereg[154:152] <= codereg[40:38];		// 52->46
			codereg[40:38] <= codereg[2:0];           // 54->52
			codereg[2:0] <= codereg[116:114];			  // 48->54
			codereg[59:57] <= codereg[135:133];			  // 47->51
			codereg[135:133] <= codereg[97:95];			  // 49->47
			codereg[97:95] <= codereg[21:19];			  // 53->49
			codereg[21:19] <= codereg[59:57];			  // 51->53

			codereg[724:722] <= codereg[1009:1007];	//Up to Left
			codereg[781:779] <= codereg[990:988];
			codereg[838:836] <= codereg[971:969];

			codereg[344:342] <= codereg[724:722];	//Left to Down
			codereg[363:361] <= codereg[781:779];
			codereg[382:380] <= codereg[838:836];

			codereg[287:285] <= codereg[344:342];	//Down to Right
			codereg[230:228] <= codereg[363:361];
			codereg[173:171] <= codereg[382:380];

			codereg[1009:1007] <= codereg[287:285];	//Right to Up
			codereg[990:988] <= codereg[230:228];
			codereg[971:969] <= codereg[173:171];
		end
		else if (SW[7:0] == BACK_CCW)
		begin
			codereg[40:38] <= codereg[154:152];	  	// 46->52
			codereg[154:152] <= codereg[116:114]; 	// 48->46
			codereg[116:114] <= codereg[2:0];           // 54->48
			codereg[2:0] <= codereg[40:38];		// 52->54

			codereg[97:95] <= codereg[135:133];		// 47->49
			codereg[135:133] <= codereg[59:57];		// 51->47
			codereg[59:57] <= codereg[21:19];		// 53->51
			codereg[21:19] <= codereg[97:95];		// 49->53

			codereg[287:285] <= codereg[1009:1007];	//Up to Right
			codereg[230:228] <= codereg[990:988];
			codereg[173:171] <= codereg[971:969];

			codereg[344:342] <= codereg[287:285];	//Right to Down
			codereg[363:361] <= codereg[230:228];
			codereg[382:380] <= codereg[173:171];

			codereg[724:722] <= codereg[344:342];	//Down to Left
			codereg[781:779] <= codereg[363:361];
			codereg[838:836] <= codereg[382:380];

			codereg[1009:1007] <= codereg[724:722];	//Left to Up
			codereg[990:988] <= codereg[781:779];
			codereg[971:969] <= codereg[838:836];
		end
		else//else, no change
		begin
		end
		stopcount <= 1;
      		current_state <= next_state;
		end
    TEMP: begin
		coderegshifter[1025:0] <= codereg[1025:0];
		stopcount <= 0;
          current_state <= next_state;
			 end
	endcase
  end


	//assignments for current pixel location to draw
  assign X = coderegshifter[18:11];
  assign Y = coderegshifter[10:3];
  assign colour = coderegshifter[2:0];

  reg [3:0] counter_out;
	assign input_x = X + counter_out[1:0];
	assign input_y = Y + counter_out[3:2];

	//counter for 4*4
    	always @(posedge CLOCK_50)
  	begin
      	if (counter_out == 4'b1111)
  		begin
  		counter_out <= 4'b0;
      		end
  	 else
  		begin
  		counter_out <= counter_out + 1;
      		end
  	end

	//timer for delay
	reg [6:0] count = 7'b0;
	reg delay;
	always @(posedge CLOCK_50)
	begin
		if(count==7'd100)//adjustable counter for delay
		begin
			count<=7'd0;
			delay<=0;
		end
		else if(stopcount)
		begin
			count<=7'd0;
		end
		else
		begin
			count<=count+1;
			delay<=1;
		end
	end
endmodule
