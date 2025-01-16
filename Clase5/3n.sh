#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 filename start_line end_line"
    exit 1
fi

filename=$1
start=$2
end=$3

if [ ! -f "$filename" ]; then
    echo "Error: File $filename does not exist"
    exit 1
fi

lines=$(( end - start + 1 ))

head -n "$end" "$filename" | tail -n "$lines"