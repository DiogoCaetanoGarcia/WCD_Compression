#include "watercolumn.h"
#include <stdlib.h>

void wc_bytes_free(WCBytes*b)
{
	free(b->p);
	b->p=NULL;
	b->n = b->cap = b->pos = 0;
}
