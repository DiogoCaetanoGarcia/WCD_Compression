CC ?= gcc
CFLAGS ?= -O3 -std=gnu11 -Wall -Wextra # -Wpedantic
CPPFLAGS += -Iinclude
LDLIBS += -lpng -lz -lm
COMMON = src/watercolumn.c src/png_io.c src/arith.c src/octree.c src/bitstream.c
all: watercolumn_encoder watercolumn_decoder
watercolumn_encoder: $(COMMON) src/encoder_main.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $^ -o $@ $(LDLIBS)
watercolumn_decoder: $(COMMON) src/decoder_main.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $^ -o $@ $(LDLIBS)
clean:
	rm -f watercolumn_encoder watercolumn_decoder
.PHONY: all clean
