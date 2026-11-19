# Water-column lossless coder in C

The project builds two independent command-line programs:

```bash
./watercolumn_encoder input.png output.wtc
./watercolumn_decoder input.png output.wtc reconstructed.png
```

## Build requirements

- GCC or Clang with C11 support
- `make`
- libpng development package

On Debian/Ubuntu/WSL:

```bash
sudo apt install build-essential libpng-dev
make
```

## PNG convention

Input is an 8-bit grayscale+alpha PNG (`LA`). The gray channel is converted to signed intensity `gray - 128`. `alpha == 0` marks an invalid sample. The output PNG preserves the alpha validity mask. Internally, matrices use column-major indexing to match Octave.

## Decoder input and legacy border behavior

The original Octave predictor initializes the prediction image with the input image and does not overwrite the first `H0-1` samples of the first column of each region. Consequently, for valid samples in those small border areas, the prediction/context is the sample itself. The bitstream contains `p(1)` for the first valid sample globally, but does not contain equivalent context selectors for the corresponding border of the second region (or the following border samples).

To decode the legacy format without changing its layout, the decoder therefore reads the original PNG gray values **only to select the context stream** for those unpredicted border positions. The decoded sample value itself still comes from the arithmetic-coded stream. For all other pixels, the PNG gray channel is not used; the alpha channel supplies the validity mask. If the decoder must use only alpha from the PNG, the encoder/bitstream must be revised to explicitly signal these initial border contexts.

## Bitstream

The implementation preserves the supplied layout: packed 255-bin occupancy histogram, arithmetic-coded octree occupancy bytes, ASCII header `H,W1,W2,H0,W0,p0,`, 30 raw IEEE-754 doubles (15 LS coefficients per region), and one length-prefixed arithmetic stream per nonempty prediction context. Length fields are little-endian. Octree path accumulation uses `uint64_t`, avoiding loss of integer precision for the 57-bit paths required by the frequency coordinate.

## Validation performed

The project was compiled with `make` and round-trip tested on the five supplied PNGs (`img1.png` through `img5.png`). For all five, the reconstructed gray channel matched every valid input pixel exactly, and the alpha channel matched exactly. This verifies C encoder/decoder self-consistency on those samples. It is not a byte-for-byte comparison against an Octave-generated `.wtc` file; cross-implementation compatibility should still be checked with a known Octave bitstream.

The LS coefficients are computed by a Householder QR least-squares solver in C and serialized as doubles. Since the C encoder stores its own coefficients, its decoder uses the exact stored values. A C-generated bitstream may differ from an Octave-generated one if their least-squares implementations produce slightly different coefficients.
