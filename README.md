# Water Column Data Codec

A lossless codec for multibeam sonar water column data (WCD), written in GNU Octave. Each WCD image is split in two regions, predicted with a least-squares (LS) linear predictor, and coded with context-based arithmetic coding. The side information (per-context histograms) is compressed as a sparse 3D point cloud using an octree coder.

Tested with GNU Octave 11.3.0 (x86_64-pc-linux-gnu) on Windows 11, using Ubuntu 22.04.5 under WSL 2.

If you use this code, please cite the paper where the codec was proposed (see [How to cite](#how-to-cite)).

## Directory layout

```
.
├── data/
│   └── 1.mat ... 5.mat           # Test WCD images
├── lib/                          # Support functions (see below)
├── test_codec.m                  # Test script: runs the codec on data/1..5.mat
└── watercolumn_arith_cod.m       # Main codec function
```

### Main codec

`watercolumn_arith_cod.m` implements the encoder and, when the internal flag `decode_seq` is set to `1`, a decoder that checks each part of the bitstream.

```matlab
[r_bits, cur_wtcs] = watercolumn_arith_cod(wcd_img);
```

- **Input:** `wcd_img`, a matrix with rows = beams and columns = radial samples. Values are in dB in the range [-128, 127]; `-Inf` marks invalid samples.
- **Output:** `r_bits` is the size of the bitstream in bits. `cur_wtcs` is a 1x2 cell with the two regions coded separately (before and after the first seafloor return).

Internal flags at the top of the function:

| Flag | Default | Meaning |
|---|---|---|
| `show_intermediate_imgs` | `0` | Plot the image, its prediction and the prediction error |
| `decode_seq` | `1` | Decode the bitstream and check every part against the original |
| `H0`, `W0` | `4`, `4` | Size of the causal neighborhood used by the LS predictor |

### Support functions (`lib/`)

| File | Role |
|---|---|
| `watercolumn_LS_pred.m` | LS linear prediction of a region of the image |
| `aren.m`, `aren_c.c` | Arithmetic encoder (Octave wrapper and C/MEX source) |
| `arde.m`, `arde_c.c` | Arithmetic decoder (Octave wrapper and C/MEX source) |
| `decode_ar_bytes.m` | Decodes an arithmetic-coded byte stream given its histogram |
| `general_octree_coding.m` | Octree coding of a 3D point cloud |
| `general_octree_decoding.m` | Octree decoding |
| `separate_octree_levels.m` | Helper for the octree coder |
| `Nbits_to_byte.m`, `byte_to_Nbits.m` | Pack and unpack integers using N bits each |
| `watercolumn_datafilling.m` | Fills invalid samples of the WCD image |
| `watercolumn_img_diff.m` | Image differencing helper |
| `ls_pred_arith_cod.m` | Alternative LS-prediction + arithmetic-coding codec |
| `build_mex_files.m` | Builds the MEX files from the C sources |
| `ccc.m` | Utility script |

## Requirements

- GNU Octave (tested with 11.3.0).
- A C compiler and Octave's development tools, needed to build the MEX files. On Ubuntu:

  ```bash
  sudo apt install liboctave-dev build-essential
  ```

## Setup

1. Build the MEX files for the arithmetic encoder and decoder (`aren_c.c` and `arde_c.c`). From Octave:

   ```octave
   cd lib
   build_mex_files
   cd ..
   ```

   The compiled files are platform-specific and must be rebuilt on each new system.

2. Add `lib/` to the Octave path. Run this from the top-level directory, once per Octave session:

   ```octave
   addpath('lib')
   ```

## Usage

### Running the test script

From the top-level directory (the script uses the relative path `data/`):

```octave
addpath('lib')
test_codec
```

For each file `data/1.mat` to `data/5.mat`, `test_codec.m`:

1. Loads the file, which must define the matrix `wcd_img`.
2. Calls `watercolumn_arith_cod(wcd_img)`, which encodes the image and, with `decode_seq = 1`, verifies the decoded streams.
3. Prints the image size, the number of valid pixels (and their percentage), and the compression ratio.

The compression ratio is computed as

```
numel(wcd_img) * 8 / r_bits
```

that is, relative to the raw image stored with 8 bits per pixel, **including the invalid pixels**.

Example output format:

```
data/1.mat
- Size: <rows> x <columns> pixels
- Valid pixels: <count> (<percentage>%)
- Proposed codec compression ratio: <ratio>
```

### Reading the verification output

While `decode_seq` is on, the codec prints the result of each check (`oh_decode_ok`, `o_decode_ok`, `ctx_dec_ok`, `header_dec_ok`, `aok_dec_ok`). Every one should be `1` (true). The decoder only verifies that the coded streams are recovered exactly; it does not rebuild the image.

### Using the codec on your own data

Save your image as a matrix named `wcd_img` in a `.mat` file, or call the function directly:

```octave
addpath('lib')
load('my_data.mat')                       % defines wcd_img
[r_bits, regions] = watercolumn_arith_cod(wcd_img);
cr = numel(wcd_img) * 8 / r_bits;
```

To skip the verification step and speed up encoding, set `decode_seq = 0` at the top of `watercolumn_arith_cod.m`.

## Troubleshooting

- **`'aren' undefined` or a missing `.mex` error:** the MEX files have not been built (or `lib/` is not on the path). Run `build_mex_files` and `addpath('lib')`.
- **`mkoctfile` not found:** install `liboctave-dev`.
- **`data/1.mat` not found:** run `test_codec` from the top-level directory.

## How to cite

If you use this code in your work, please cite the paper where the codec was proposed:

> Garcia, D. C., Queiroz, R. L. de, & Fonseca, L. E. N. da (2023). Lossless and lossy compression of water-column profile data from multibeam echosounders based on image predictions and multiple-context entropy-encoding. *Boletim de Ciências Geodésicas*, 29(04), e2023010.
> DOI: <https://doi.org/10.1590/s1982-21702023000400010>

**BibTeX**

```bibtex
@article{garcia2023lossless,
  title={Lossless and lossy compression of water-column profile data from multibeam echosounders based on image predictions and multiple-context entropy-encoding},
  author={Garcia, Diogo Caetano and Queiroz, Ricardo Lopes de and Fonseca, Luciano Em{\'\i}dio Neves da},
  journal={Boletim de Ci{\^e}ncias Geod{\'e}sicas},
  volume={29},
  number={04},
  pages={e2023010},
  year={2023},
  publisher={SciELO Brasil}
}
```

**MLA**

Garcia, Diogo Caetano, Ricardo Lopes de Queiroz, and Luciano Emídio Neves da Fonseca. "Lossless and lossy compression of water-column profile data from multibeam echosounders based on image predictions and multiple-context entropy-encoding." *Boletim de Ciências Geodésicas* 29.04 (2023): e2023010.

**NBR 6023**

GARCIA, Diogo Caetano; QUEIROZ, Ricardo Lopes de; FONSECA, Luciano Emídio Neves da. Lossless and lossy compression of water-column profile data from multibeam echosounders based on image predictions and multiple-context entropy-encoding. *Boletim de Ciências Geodésicas*, v. 29, n. 04, p. e2023010, 2023.

**APA**

Garcia, D. C., Queiroz, R. L. D., & Fonseca, L. E. N. D. (2023). Lossless and lossy compression of water-column profile data from multibeam echosounders based on image predictions and multiple-context entropy-encoding. *Boletim de Ciências Geodésicas*, 29(04), e2023010.