#ifndef OCTREE_H
#define OCTREE_H

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

typedef struct
{
	uint64_t path;
	uint32_t x,y,z;
} Node;

typedef struct
{
	uint8_t*p;
	size_t n,c;
} Vec;

typedef struct
{
	uint32_t x,y,z;
} WCPoint;

int oct_encode(
	const WCPoint *pts,
	size_t n,
	uint8_t **out,
	size_t *outn);

int oct_decode(
	const uint8_t *o,
	size_t n,
	WCPoint **pts,
	size_t *npts);

#endif
