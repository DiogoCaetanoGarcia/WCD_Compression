#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 2 ]]
then
	echo "Usage: $0 encoder decoder [image.png ...]";
	exit 2;
fi

enc=$1;
dec=$2;
shift 2
for image in "$@"
do
	stem=$(basename "$image" .png)
	"$enc" "$image" results/"${stem}.wtc"
	"$dec" "$image" results/"${stem}.wtc" results/"${stem}_reconstructed.png"
	echo "Round-trip complete: $image"
done
