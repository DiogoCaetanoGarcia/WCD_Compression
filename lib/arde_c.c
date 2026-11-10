#include "mex.h"

#define CODE_VALUE_BITS	32
#define TOP_VALUE		0xFFFFFFFF
#define FIRST_QTR		0x40000000
#define HALF			0x80000000
#define THIRD_QTR		0xC0000000

unsigned char buffer, bits_to_go, garbage_bits;
unsigned char *in_vec;
mwIndex in_index, out_index;
mwSize L, N;

unsigned long long input_bit(void);

void mexFunction (int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
	unsigned long long *ccts = (unsigned long long*) mxGetPr(prhs[1]);
	unsigned long long *x = (unsigned long long*) mxGetPr(prhs[2]);
	unsigned long long range, cum, symbol, low, high, value, max_count = ccts[mxGetM(prhs[1])-1];
	mwIndex j;

	garbage_bits = 0;
	bits_to_go = 0;
	buffer = 0;
	low = 0;
	high = TOP_VALUE;
	in_index = 0;
	out_index = 0;
	in_vec = (unsigned char*) mxGetPr(prhs[0]);
	L = mxGetM(prhs[0]);
	N = mxGetM(prhs[2]);
	for(value=0, j=0; j<CODE_VALUE_BITS; j++)
	{
		value <<=1;
		value |= input_bit();
	}
	while(1)
	{
		range = (high-low)+1;
		cum = (((value-low)+1)*max_count-1)/range;
		for(symbol=0;ccts[symbol]<=cum; symbol++);
		symbol--;
		high  = low + (range*ccts[symbol+1])/max_count-1;
		low   = low + (range*ccts[symbol])/max_count;
		for (;;)
		{
			if(high < HALF)
			{
			}
			else if(low >= HALF)
			{
				low -= HALF;
				high -= HALF;
				value -= HALF;
			}
			else if((low>=FIRST_QTR) && (high<THIRD_QTR))
			{
				low -= FIRST_QTR;
				high -= FIRST_QTR;
				value -= FIRST_QTR;
			}
			else
			{
				break;
			}
			low <<= 1;
			high <<= 1;
			high++;
			value <<= 1;
			value |= input_bit();
		}
		x[out_index++] = symbol;
		if(out_index==N)
		{
			break;
		}
	}
}

unsigned long long input_bit(void)
{
	unsigned long long t;
	if(bits_to_go==0)
	{
		// if(in_index==L)
		// {
		// 	mexPrintf("Error reading encoded file in position %d (value = %d)!\n",in_index+1,in_vec[in_index]);
		// 	mexCallMATLAB(0, NULL, 0, NULL, "drawnow");
		// }
		buffer = in_vec[in_index++];
		if(out_index==N)
		{
			garbage_bits++;
			if(garbage_bits>CODE_VALUE_BITS-2)
			{
				mexPrintf("Bad decoded file!\n");
				mexCallMATLAB(0, NULL, 0, NULL, "drawnow");
			}
		}
		bits_to_go = 8;
	}
	t = buffer & 1;
	buffer >>= 1;
	//t = (buffer&0x80) ? 1 : 0;
	//buffer <<= 1;
	bits_to_go--;
	return t;
}