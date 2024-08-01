#!/bin/bash

HOSTS=("hostname.something.com")

# Default values
USE_GZIP=false
INPUT_FILE=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --gzip) USE_GZIP=true ;;
        --file) INPUT_FILE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if INPUT_FILE is provided
if [ -z "$INPUT_FILE" ]; then
    echo "Error: Please provide a filename using the --file option."
    exit 1
fi

# Check file extension based on --gzip flag
if $USE_GZIP; then
    if [[ ! "$INPUT_FILE" == *.gz ]]; then
        echo "Error: When using --gzip, the --file parameter must end with .gz"
        exit 1
    fi
    OUTPUT_TAR="${INPUT_FILE%.gz}"
    OUTPUT_GZIP="$INPUT_FILE"
else
    if [[ ! "$INPUT_FILE" == *.tar ]]; then
        echo "Error: When not using --gzip, the --file parameter must end with .tar"
        exit 1
    fi
    OUTPUT_TAR="$INPUT_FILE"
    OUTPUT_GZIP="${INPUT_FILE}.gz"
fi

if $USE_GZIP; then
    printf '%s\n' "Will distribute '$OUTPUT_GZIP' to and load into Docker:"
else
    printf '%s\n' "Will distribute '$OUTPUT_TAR' to and load into Docker:"
fi
printf '%s\n' "${HOSTS[@]}"
read -rsp "root password: " PASSWORD
echo
printf '%s\n' "=================================="

process_host() {
    local host=$1
    local use_gzip=$2
    local file_to_copy
    file_to_copy=$([ "$use_gzip" = true ] && echo "$OUTPUT_GZIP" || echo "$OUTPUT_TAR")

    echo "Processing $host"
    echo "Copying '$file_to_copy' to root@$host:/root/"

    if sudo sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no "$file_to_copy" root@"$host":/root/; then
        echo "Copy to $host complete"

        local ssh_command
        if [ "$use_gzip" = true ]; then
            echo "SSHing to $host, decompressing, and loading images to Docker"
            ssh_command="gzip -fd /root/$OUTPUT_GZIP && docker load -i /root/$OUTPUT_TAR && rm -rf /root/$OUTPUT_TAR /root/$OUTPUT_GZIP"
        else
            echo "SSHing to $host and loading images to Docker"
            ssh_command="docker load -i /root/$OUTPUT_TAR && rm -rf /root/$OUTPUT_TAR"
        fi

        sshpass -p "$PASSWORD" ssh root@"$host" "$ssh_command"
    else
        echo "Copy to $host failed"
    fi
    echo "=================================="
}

export -f process_host
export OUTPUT_TAR OUTPUT_GZIP PASSWORD USE_GZIP

parallel --will-cite --keep-order --line-buffer process_host ::: "${HOSTS[@]}" ::: "$USE_GZIP"

echo "All operations completed."
