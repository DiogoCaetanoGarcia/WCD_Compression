#include "arith.h"

static int putbit(BW *b,unsigned bit)
{
	b->buf=(unsigned char)(b->buf>>1);
	if(bit)
		b->buf|=0x80;
	if(--b->bits==0)
	{
		if(b->n==b->cap)
		{
			size_t c=b->cap?b->cap*2:64;
			void*q=realloc(b->p,c);
			if(!q)
				return 0;
			b->p=q;
			b->cap=c;
		}
		b->p[b->n++] = b->buf;
		b->buf=0;
		b->bits=8;
	}
	return 1;
}

static int follow(BW *b, unsigned bit, uint64_t *pending)
{
	if(!putbit(b,bit))
		return 0;
	while(*pending)
	{
		if(!putbit(b,!bit))
			return 0;
		--*pending;
	}
	return 1;
}

int ar_encode(const uint8_t*s,size_t n,const uint64_t*f,size_t A,uint8_t**out,size_t*outn) {
	if(!n)
	{
		*out=NULL;
		*outn=0;
		return 1;
	}
	uint64_t total=0;
	
	for(size_t i=0; i<A; i++)
		total+=f[i];
	if(!total)
		return 0;
	uint64_t *cum=calloc(A+1,sizeof(uint64_t));
	if(!cum)
		return 0;
	for(size_t i=0; i<A; i++)
		cum[i+1]=cum[i]+f[i];
	BW b= {0};
	b.bits=8;

	uint64_t low=0,high=TOP,pending=0;
	for(size_t k=0; k<n; k++)
	{
		unsigned sym=s[k];
		if(sym>=A||!f[sym])
			goto fail;
		uint64_t range=high-low+1;
		high = low+(range*cum[sym+1])/total-1;
		low  = low+(range*cum[sym])/total;
		for(;;)
		{
			if(high<HALF)
			{
				if(!follow(&b,0,&pending))
					goto fail;
			}
			else if(low>=HALF)
			{
				if(!follow(&b,1,&pending))
					goto fail;
				low-=HALF;
				high-=HALF;
			}
			else if(low>=Q1&&high<Q3)
			{
				pending++;
				low-=Q1;
				high-=Q1;
			}
			else
				break;
			low<<=1;
			high=(high<<1)|1;
		}
	}
	pending++;
	if(!follow(&b,low<Q1?0:1,&pending))
		goto fail;
	if(b.n==b.cap)
	{
		void*q = realloc(b.p,b.cap+1);
		if(!q)
			goto fail;
		b.p=q;
		b.cap++;
	}
	b.p[b.n++] = (uint8_t)(b.buf>>b.bits);
	free(cum);
	*out=b.p;
	*outn=b.n;
	return 1;
fail:
	free(cum);
	free(b.p);
	return 0;
}

static unsigned getbit(BR *b)
{
	if(!b->bits) {
		b->buf=b->pos<b->n?b->p[b->pos++]:0;
		b->bits=8;
	}
	unsigned v=b->buf&1;
	b->buf>>=1;
	b->bits--;
	return v;
}

int ar_decode(const uint8_t*in,size_t in_n,const uint64_t*f,size_t A,size_t n,uint8_t*out)
{
	if(!n)
		return 1;
	uint64_t total=0;
	for(size_t i=0; i<A; i++)
		total+=f[i];
	if(!total)
		return 0;
	uint64_t *cum = calloc(A+1,sizeof(uint64_t));
	if(!cum)
		return 0;
	for(size_t i=0; i<A; i++)
		cum[i+1]=cum[i]+f[i];
	BR b = {in,in_n,0,0,0};
	uint64_t low=0,high=TOP,value=0;
	for(int j=0; j<32; j++)
		value=(value<<1)|getbit(&b);
	for(size_t k=0; k<n; k++)
	{
		uint64_t range=high-low+1,c=((value-low+1)*total-1)/range;
		size_t lo=0,hi=A;
		while(lo<hi)
		{
			size_t m=(lo+hi)/2;
			if(cum[m+1]<=c)
				lo=m+1;
			else
				hi=m;
		}
		if(lo>=A||!f[lo])
		{
			free(cum);
			return 0;
		}
		size_t sym=lo;
		high=low+(range*cum[sym+1])/total-1;
		low=low+(range*cum[sym])/total;
		for(;;)
		{
			if(high<HALF) {} else if(low>=HALF)
			{
				low-=HALF;
				high-=HALF;
				value-=HALF;
			}
			else if(low>=Q1&&high<Q3)
			{
				low-=Q1;
				high-=Q1;
				value-=Q1;
			}
			else
				break;
			low<<=1;
			high=(high<<1)|1;
			value=(value<<1)|getbit(&b);
		}
		out[k]=(uint8_t)sym;
	}
	free(cum);
	return 1;
}
