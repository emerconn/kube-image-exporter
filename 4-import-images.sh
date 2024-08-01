#!/bin/bash

OUTPUT_TAR="failed_images.tar"
OUTPUT_GZIP="${OUTPUT_TAR}.gz"

echo "Extracting '$OUTPUT_GZIP'"
gzip -d "$OUTPUT_GZIP"
echo "Extracted '$OUTPUT_TAR'"
echo "=================================="

echo "Loading images from '$OUTPUT_TAR'"
docker load -i "$OUTPUT_TAR"
echo "Loaded images from '$OUTPUT_TAR'"
