#!/bin/bash

OUTPUT_TAR="failed_images.tar"
OUTPUT_GZIP="${OUTPUT_TAR}.gz"

# handle Ctrl+C (SIGINT)
trap 'echo -e "\nScript interrupted. Exiting..."; exit 1' SIGINT

# --gzip flag
USE_GZIP=false
for arg in "$@"; do
    if [ "$arg" == "--gzip" ]; then
        USE_GZIP=true
        shift
    fi
done

# filename argument
if [ $# -eq 0 ]; then
    echo "Please provide the filename as an argument."
    exit 1
fi

images=()
while IFS= read -r image; do
    # skip empty lines
    if [ -n "$image" ]; then
        echo "Pulling image: $image"
        sudo docker pull "$image"
        images+=("$image")
        echo "=================================="
    fi
done < "$1"

echo "All images have been pulled"
echo "=================================="

echo "Saving all images to '$OUTPUT_TAR'"
sudo docker save "${images[@]}" -o "$OUTPUT_TAR"
echo "Saved to '$OUTPUT_TAR'"
echo "=================================="

if [ "$USE_GZIP" = true ]; then
    echo "Compressing '$OUTPUT_TAR' to '$OUTPUT_GZIP'"
    sudo gzip -f "$OUTPUT_TAR"
    echo "Compressed to '$OUTPUT_GZIP'"
else
    echo "Skipping compression (--gzip flag not provided)"
fi

# ./3-distribute-failed-images.sh

# run in background
# nohup ./2-export-images.sh failed_images.txt > output.log 2>&1 &
