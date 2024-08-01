#!/bin/bash

# on each node run
docker images --format "{{.Repository}}:{{.Tag}}"
# copy the output from each node and paste in all_images.txt

# sort and remove duplicates
sort all_images.txt | uniq > all_images_filtered.txt

# remove L2023.2 tags
sed -i '/L2023.2/d' all_images_filtered.txt

# remove <none> tags
sed -i '/<none>/d' all_images_filtered.txt

# run job in background
nohup ./2-export-images.sh all_images_filtered.txt > output.log 2>&1 &
