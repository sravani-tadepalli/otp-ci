#!/usr/bin/env bash
set -e
FN_DIR="$1"
OUT_DIR="$(pwd)/build"
mkdir -p "$OUT_DIR"
cd "$FN_DIR"
rm -f "../build/${FN_DIR}.zip"
mkdir -p package
if [ -f requirements.txt ]; then python3 -m pip install -r requirements.txt -t package; fi
cd package || true
zip -r9 "../../build/${FN_DIR}.zip" . || true
cd ..
zip -g "../build/${FN_DIR}.zip" *.py || true
cd ..
echo "Built build/${FN_DIR}.zip"
