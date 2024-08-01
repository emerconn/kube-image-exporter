#!/bin/bash

OUTPUT_TXT="failed_images.txt"

kubectl get pods --all-namespaces | grep -E 'ImagePull' | while read -r line
do
    namespace=$(echo "$line" | awk '{print $1}')
    pod_name=$(echo "$line" | awk '{print $2}')

    kubectl get pod "$pod_name" -n "$namespace" -o json | jq -r '
        (.status.initContainerStatuses + .status.containerStatuses)[] |
        select(.state.waiting.reason == "Init:ImagePullBackOff" or
               .state.waiting.reason == "ImagePullBackOff" or
               .state.waiting.reason == "ErrImagePull") |
        .image
    '
done | sort -u | tee "$OUTPUT_TXT"

echo "List saved to: $OUTPUT_TXT"
