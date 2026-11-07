#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p test-build
clang -fno-objc-arc -Wall -Wno-incomplete-implementation -Wno-deprecated-declarations -Isrc tests/core.m src/CLAIRequest.m src/CLIntegration.m src/ORJSON.m src/LFAI.m src/CLCoachData.m -framework Foundation -o test-build/core
test-build/core

clang -fno-objc-arc -O2 -Wall -Wno-deprecated-declarations -Wno-incompatible-pointer-types -Isrc tests/search.m src/LFSearch.m src/LFStore.m src/ORJSON.m -framework Foundation -o test-build/search
test-build/search
