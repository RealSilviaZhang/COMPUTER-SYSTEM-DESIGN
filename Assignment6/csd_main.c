char pri_time[11];
char* csd_main(int a, int b, int c)
{
	// pri_time: Hh: Mm: Ss
	//[H][h][:][ ][M][m][:][ ][S][s]['\0']
	char temp;

	//Hour
	temp = (a % 10) + 48; // 48 is 0 in Ascii table
	a /= 10;
	pri_time[1] = temp; // h

	temp = a + 48;
	pri_time[0] = temp; // H

	pri_time[2] = ':'; //:
	pri_time[3] = 32; // 32 is space in Ascii table

	//Minute
	temp = (b % 10) + 48;
	b /= 10;
	pri_time[5] = temp; // m

	temp = b + 48;
	pri_time[4] = temp; // M

	pri_time[6] = ':';
	pri_time[7] = 32;

	//Second
	temp = (c % 10) + 48;
	c /= 10;
	pri_time[9] = temp; // s

	temp = c + 48;
	pri_time[8] = temp; // S

	pri_time[10] = '\0'; // end of a string

 return (char*)&pri_time;

}
