#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 input_dir3 input_dir4 output_dir6" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HDFS_HOME="/user/$(id -un)"

abs_path() {
  case "$1" in
    /*|*://*) echo "$1" ;;
    *) echo "$HDFS_HOME/$1" ;;
  esac
}

INPUT_DIR3="$(abs_path "$1")"
INPUT_DIR4="$(abs_path "$2")"
OUTPUT_DIR6="$(abs_path "$3")"

beeline -n "$(id -un)" -u jdbc:hive2://localhost:10000/default \
  --hivevar input_dir3="$INPUT_DIR3" \
  --hivevar input_dir4="$INPUT_DIR4" \
  --hivevar output_dir6="$OUTPUT_DIR6" \
  -f "$SCRIPT_DIR/hive.hql"
