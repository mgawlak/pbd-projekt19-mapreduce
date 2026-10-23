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
  -D mapreduce.input.fileinputformat.split.maxsize=134217728 \
  -D stream.map.input.ignoreKey=true \
  -inputformat org.apache.hadoop.mapred.lib.CombineTextInputFormat \
  -files "$SCRIPT_DIR/mapper.py,$SCRIPT_DIR/combiner.py,$SCRIPT_DIR/reducer.py" \
  -input "$INPUT_DIR1" \
  -output "$OUTPUT_DIR3" \
  -mapper "python3 mapper.py" \
  -combiner "python3 combiner.py" \
  -reducer "python3 reducer.py"
