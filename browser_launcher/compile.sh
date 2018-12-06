#!/bin/bash

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

rm -rf bin
mkdir -p bin
gcc $(pkg-config --cflags --libs gtk+-2.0) browser_launcher.c -o bin/browser_launcher
