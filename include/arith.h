#ifndef ARITH_H
#define ARITH_H

#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#define TOP  0xffffffffULL
#define Q1   0x40000000ULL
#define HALF 0x80000000ULL
#define Q3   0xc0000000ULL

typedef struct
{
	uint8_t *p;
	size_t n,cap;
	unsigned char buf,bits;
} BW;

typedef struct
{
	const uint8_t*p;
	size_t n,pos;
	unsigned bits;
	uint8_t buf;
} BR;

int ar_encode(
	const uint8_t *symbols,
	size_t n,
	const uint64_t *freq,
	size_t alphabet,
	uint8_t **out,
	size_t *outn);
int ar_decode(
	const uint8_t *in,
	size_t in_n,
	const uint64_t *freq,
	size_t alphabet,
	size_t n,
	uint8_t *out);

#endif
