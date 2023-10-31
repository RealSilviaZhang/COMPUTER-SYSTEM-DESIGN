// ------------------------------------------
//  Author: Aoxuan Zhang
//          Computer Science & Engineering
//          College of Informatics, Korea Univ.
//  Date:   May 01, 2023
// ------------------------------------------


#pragma GCC target ("arm")

int arm_C_test(void)
{
	int indata[32] = { 2, 0, -7, -1, 3, 8, -4, 10,
					  -9, -16, 15, 13, 1, 4, -3, 14,
					  -8, -10, -15, 6, -13, -5, 9, 12,
					  -11, -14, -6, 11, 5, 7, -2, -12 }; // Input data
	int outdata[32] = { 2, 0, -7, -1, 3, 8, -4, 10,
			 	 	   -9, -16, 15, 13, 1, 4, -3, 14,
					   -8, -10, -15, 6, -13, -5, 9, 12,
					   -11, -14, -6, 11, 5, 7, -2, -12 }; // Output data
	//Section sorting
    int i,j,temp; // Declare variables i, j, and temp

    for(i=0;i<31;i++)// Loop through outdata to perform selection sort
    {
        for(j=i+1;j<32;j++)// Inner loop to compare each element with every other element
        {
            if(outdata[i]>outdata[j])// Check if current element is greater than next element
            {
                temp=outdata[i];// Swap current element with next element
                outdata[i]=outdata[j];
                outdata[j]=temp;
            }
        }
    }

    return 0;
}

#pragma GCC target ("thumb")

int thumb_C_test(void)
{
	int indata[32] = { 2, 0, -7, -1, 3, 8, -4, 10,
					  -9, -16, 15, 13, 1, 4, -3, 14,
					  -8, -10, -15, 6, -13, -5, 9, 12,
					  -11, -14, -6, 11, 5, 7, -2, -12 }; // Input data
	int outdata[32] = { 2, 0, -7, -1, 3, 8, -4, 10,
			 	 	   -9, -16, 15, 13, 1, 4, -3, 14,
					   -8, -10, -15, 6, -13, -5, 9, 12,
					   -11, -14, -6, 11, 5, 7, -2, -12 }; // Output data
	//Section sorting
    int i,j,temp; // Declare variables i, j, and temp

    for(i=0;i<31;i++)// Loop through outdata to perform selection sort
    {
        for(j=i+1;j<32;j++)// Inner loop to compare each element with every other element
        {
            if(outdata[i]>outdata[j])// Check if current element is greater than next element
            {
                temp=outdata[i];// Swap current element with next element
                outdata[i]=outdata[j];
                outdata[j]=temp;
            }
        }
    }

    return 0;
}
