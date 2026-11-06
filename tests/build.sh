#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p test-build
clang -fno-objc-arc -Wall -Wno-incomplete-implementation -Wno-deprecated-declarations -Isrc tests/core.m src/CLAIRequest.m src/CLIntegration.m src/ORJSON.m src/LFAI.m -framework Foundation -o test-build/core
test-build/core
