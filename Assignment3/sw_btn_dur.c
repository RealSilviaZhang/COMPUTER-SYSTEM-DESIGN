#define csd_SW_ADDR 0x41210000
#define SW0 0b00000001
#define SW1 0b00000010
#define SW2 0b00000100
#define SW3 0b00001000
#define SW4 0b00010000
#define SW5 0b00100000
#define SW6 0b01000000
#define SW7 0b10000000

int sw_btn_dur(){

 	unsigned dur = 1, input = 0; // initial dur and input as duration and switches input
	unsigned char*sw = (unsigned char*) csd_SW_ADDR; // get the pointer of the switches

	input = *sw; // assign the switches status to input
	if (input >= SW7) // SW7 is on
		input = SW7;
	else if ((input >= SW6)&&(input < SW7)) // SW6 is on
		input = SW6;
	else if ((input >= SW5)&&(input < SW6)) // SW5 is on
		input = SW5;
	else if ((input >= SW4)&&(input < SW5)) // SW4 is on
		input = SW4;
	else if ((input >= SW3)&&(input < SW4)) // SW3 is on
		input = SW3;
	else if ((input >= SW2)&&(input < SW3)) // SW2 is on
		input = SW2;
	else if ((input >= SW1)&&(input < SW2)) // SW1 is on
		input = SW1;
	else if ((input >= SW0)&&(input < SW1)) // SW0 is on
		input = SW0;

	switch(input){ // get the duration from the input status of switches accordingly
		case SW7:
			dur = 100;
			break;
		case SW6:
			dur = 200;
			break;
		case SW5:
			dur = 300;
			break;
		case SW4:
			dur = 400;
			break;
		case SW3:
			dur = 500;
			break;
		case SW2:
			dur = 600;
			break;
		case SW1:
			dur = 700;
			break;
		case SW0:
			dur = 800;
			break;
		default: // no switch is on or exception handling
			dur = 1000;
			break;
		}

	return dur*600000; // 600000 here as a multiplier, stretch the duration, make sure the program can be executed at an appropriate time
}
