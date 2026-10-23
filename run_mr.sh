#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 input_dir1 output_dir3" >&2
  exit 1
fi

INPUT_DIR1="$1"
OUTPUT_DIR3="$2"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

hadoop fs -rm -r -f "$OUTPUT_DIR3"

mapred streaming \
  -files "$SCRIPT_DIR/mapper.py,$SCRIPT_DIR/combiner.py,$SCRIPT_DIR/reducer.py" \
  -input "$INPUT_DIR1" \
  -output "$OUTPUT_DIR3" \
  -mapper "python3 mapper.py" \
  -combiner "python3 combiner.py" \
  -reducer "python3 reducer.py"
