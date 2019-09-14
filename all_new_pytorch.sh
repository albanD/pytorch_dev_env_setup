#!/bin/bash

set -e

PY_VERSIONS=("2.7" "3.5" "3.6")
MODES=("" "--debug")
BUILDS=("" "--binary")
COMPAT_GCC="--old-gcc" # Or empty string

for PY_VERSION in "${PY_VERSIONS[@]}"; do
    for MODE in "${MODES[@]}"; do
        for BUILD in "${BUILDS[@]}"; do
            if [ "${MODE}" == "--debug" ]; then
                if [ "${BUILD}" == "--binary" ]; then
                    # No binary exists for debug pytorch
                    continue
                fi
            fi
            ./new_pytorch.sh --version ${PY_VERSION} ${MODE} ${BUILD}
        done
    done
done
