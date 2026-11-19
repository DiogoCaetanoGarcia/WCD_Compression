#ifndef WATERCOLUMN_H
#define WATERCOLUMN_H

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct
{
		uint32_t h,w;
		int8_t *v;
		uint8_t *valid;
} WCImage;

typedef struct
{
	uint8_t *p;
	size_t n,cap,pos;
} WCBytes;

typedef struct
{
	uint32_t h,w;
	uint8_t *v;
} WCByteImage;

typedef struct {
    uint8_t *p;
    size_t n,c,pos;
} Buf;

int png_read_wc(
	const char*,
	WCImage*);
int png_write_wc(
	const char*,
	const WCImage*);
void wc_free_image(
	WCImage*);
int wc_encode(
	const WCImage*,
	const char*);
int wc_decode(
	const WCImage*,
	const char*,
	const char*);
void wc_bytes_free(
	WCBytes*);

#endif
