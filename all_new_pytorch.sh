#!/bin/bash

set -e

PY_VERSIONS=("3.8" "3.9" "3.10" "3.11")
MODES=("" "--debug" "--shared")
BUILDS=("" "--binary")

for PY_VERSION in "${PY_VERSIONS[@]}"; do
    for MODE in "${MODES[@]}"; do
        for BUILD in "${BUILDS[@]}"; do
            if [ "${MODE}" == "--debug" ]; then
                if [ "${BUILD}" == "--binary" ]; then
                    # No binary exists for debug pytorch
                    continue
                fi
            fi
            if [ "${MODE}" == "--shared" ]; then
                if [ "${BUILD}" == "--binary" ]; then
                    # Only do debug shared for now
                    continue
                fi
            fi
            ./new_pytorch.sh --version ${PY_VERSION} ${MODE} ${BUILD}
        done
    done
done
