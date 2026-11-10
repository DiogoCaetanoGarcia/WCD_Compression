#include "mex.h"

#define CODE_VALUE_BITS	32
#define TOP_VALUE		0xFFFFFFFF
#define FIRST_QTR		0x40000000
#define HALF			0x80000000
#define THIRD_QTR		0xC0000000

unsigned char buffer, bits_to_go;
unsigned char *out_vec;
unsigned long long low, high, bits_to_follow;
mwIndex out_index;
mwSize L;

void output_bit(int bit);
void bit_plus_follow(int bit);

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	unsigned long long *x = (unsigned long long*) mxGetPr(prhs[0]);
	unsigned long long *ccts = (unsigned long long*) mxGetPr(prhs[1]);
	unsigned long long range, symbol, max_count = ccts[mxGetM(prhs[1])-1];
	mwIndex j;

	L = mxGetM(prhs[0]);
	buffer=0;
	bits_to_go=8;
	low=0;
	high=TOP_VALUE;
	bits_to_follow = 0;
	out_index=0;
	out_vec = (unsigned char*) mxGetPr(prhs[2]);
	range = (high-low)+1;
	//mexPrintf("Start: %#lx %#lx %#lx\n",low,range,high);
	//mexPrintf("ccts = ");
	// for(j=0;j<mxGetM(prhs[1]);j++)
	// 	mexPrintf("%ld ",ccts[j]);
	// mexPrintf("\n");
	for(j=0;j<L;j++)
	{
		symbol = x[j];
		range = (high-low)+1;
		high  = low + (range*ccts[symbol+1])/max_count - 1;
		low   = low + (range*ccts[symbol])/max_count;
		for (;;)
		{
			if(high < HALF)
			{
				bit_plus_follow(0);
			}
			else if(low >= HALF)
			{
				bit_plus_follow(1);
				low -= HALF;
				high -= HALF;
			}
			else if((low>=FIRST_QTR) && (high<THIRD_QTR))
			{
				bits_to_follow++;
				low -= FIRST_QTR;
				high -= FIRST_QTR;
			}
			else
			{
				break;
			}
			low <<= 1;
			high <<= 1;
			high++;
		}
	}
	bits_to_follow++;
	if (low<FIRST_QTR)
		bit_plus_follow(0);
	else
		bit_plus_follow(1);
	out_vec[out_index++] = (buffer>>bits_to_go);

	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	double *outMatrix = mxGetPr(plhs[0]);
	outMatrix[0] = out_index;
}

void output_bit(int bit)
{
	buffer >>= 1;
	if(bit)
	{
		buffer |= 0x80;
	}
	bits_to_go--;
	if(bits_to_go==0)
	{
		out_vec[out_index++] = buffer;
		buffer = 0;
		bits_to_go = 8;
	}
}

void bit_plus_follow(int bit)
{
	output_bit(bit);
	while (bits_to_follow>0)
	{
		output_bit(!bit);
		bits_to_follow--;
	}
}