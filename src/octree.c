#include "octree.h"

static int cmpnode(const void*a, const void*b)
{
	const Node*x=a,*y=b;
	return x->path<y->path?-1:x->path>y->path?1:0;
}


static int push(Vec*v, uint8_t b)
{
	if(v->n==v->c)
	{
		size_t c=v->c?v->c*2:128;
		void*q=realloc(v->p,c);
		if(!q)return 0;
		v->p=q;
		v->c=c;
	}
	v->p[v->n++]=b;
	return 1;
}

int oct_encode(const WCPoint*pts, size_t n, uint8_t**out, size_t*outn)
{
	if(!n)return 0;
	uint32_t mx=0;
	for(size_t i=0; i<n; i++)
	{
		if(pts[i].x>mx)mx=pts[i].x;
		if(pts[i].y>mx)mx=pts[i].y;
		if(pts[i].z>mx)mx=pts[i].z;
	}
	unsigned L=0;
	uint64_t q=(uint64_t)mx+1;
	while(((uint64_t)1<<L)
		<q&&L<63)L++;
	if(!L)
		L=1;
	if(L>21)
		return 0;
	Node *cur = calloc(n,sizeof(Node));
	if(!cur)
		return 0;
	for(size_t i=0; i<n; i++)
	{
		cur[i].x=pts[i].x;
		cur[i].y=pts[i].y;
		cur[i].z=pts[i].z;
	}
	Vec v= {0};
	size_t cn=n;
	for(unsigned lev=0; lev<L; lev++)
	{
		unsigned sh=L-1-lev;
		for(size_t i=0; i<cn; i++)
		{
			uint8_t oct=(uint8_t)((((cur[i].x>>sh)&1)<<2)|(((cur[i].y>>sh)&1)<<1)|((cur[i].z>>sh)&1));
			cur[i].path=(cur[i].path<<3)|oct;
		}
		qsort(cur,cn,sizeof(Node),cmpnode);
		size_t groups=0;
		uint64_t prev=UINT64_MAX;
		for(size_t i=0; i<cn; i++)
		{
			uint64_t parent=cur[i].path>>3;
			if(i==0||parent!=prev)
			{
				groups++;
				prev=parent;
			}
		}
		if(!groups)
			goto bad;
		/* Rebuild one occupancy byte per distinct parent, children represented by bit 2^octant. */
		size_t idx=0;
		while(idx<cn)
		{
			uint64_t par=cur[idx].path>>3;
			uint8_t mask=0;
			while(idx<cn&&(cur[idx].path>>3)==par)
			{
				mask|=(uint8_t)(1u<<(cur[idx].path&7));
				idx++;
			}
			if(!push(&v,mask))
				goto bad;
		}
		if(lev+1<L)
		{
			for(size_t i=0; i<cn; i++)
				cur[i].path &= ((UINT64_C(1)<<(3*(lev+1)))-1);
		}
	}
	free(cur);
	*out=v.p;
	*outn=v.n;
	return 1;

bad:
	free(cur);
	free(v.p);
	return 0;
}

int oct_decode(const uint8_t*o, size_t n, WCPoint**out, size_t*outn)
{
	if(!n)
		return 0;
	typedef struct
	{
		uint32_t x,y,z;
	} C;
	
	C *nodes=calloc(1,sizeof(C));
	if(!nodes)return 0;
	size_t nn=1,off=0;
	while(off<n)
	{
		size_t cur_n=nn;
		if(off+cur_n>n)
		{
			free(nodes);
			return 0;
		}
		size_t childn=0;
		for(size_t i=0; i<cur_n; i++)
			for(int b=0; b<8; b++)
				childn+=(o[off+i]>>b)&1;
		if(!childn)
		{
			free(nodes);
			return 0;
		}
		C* next = calloc(childn,sizeof(C));
		if(!next)
		{
			free(nodes);
			return 0;
		}
		size_t j=0;
		for(size_t i=0; i<cur_n; i++)
			for(int b=0; b<8; b++)
				if((o[off+i]>>b)&1)
				{
					next[j].x=(nodes[i].x<<1)|((b>>2)&1);
					next[j].y=(nodes[i].y<<1)|((b>>1)&1);
					next[j].z=(nodes[i].z<<1)|(b&1);
					j++;
				}
		free(nodes);
		nodes=next;
		nn=childn;
		off+=cur_n;
	}
	WCPoint* pts = calloc(nn,sizeof(WCPoint));
	if(!pts)
	{
		free(nodes);
		return 0;
	}
	for(size_t i=0; i<nn; i++)
		pts[i]=(WCPoint){nodes[i].x,nodes[i].y,nodes[i].z};
	free(nodes);
	*out=pts;
	*outn=nn;
	return 1;
}
