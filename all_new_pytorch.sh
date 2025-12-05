#!/bin/bash

set -e

# PY_VERSIONS=("3.8" "3.9" "3.10" "3.11" "3.12" "3.13")
PY_VERSIONS=("3.14")
# package/deploy is dead I guess
# MODES=("" "--debug" "--shared")
# MODES=("" "--debug")
# BUILDS=("" "--binary")
GILS=("" "--no-gil")
MODES=("" "--debug")
BUILDS=("" "--binary")

for PY_VERSION in "${PY_VERSIONS[@]}"; do
    for MODE in "${MODES[@]}"; do
        for BUILD in "${BUILDS[@]}"; do
            for GIL in "${GILS[@]}"; do
                if [ "${MODE}" == "--debug" ]; then
                    if [ "${BUILD}" == "--binary" ]; then
                        # No binary exists for debug pytorch
                        continue
                    fi
                else
                    if [ "${GIL}" == "--no-gil" ]; then
                        # nogil build is debug only
                        continue
                    fi
                fi
                if [ "${MODE}" == "--shared" ]; then
                    if [ "${BUILD}" == "--binary" ]; then
                        # Only do debug shared for now
                        continue
                    fi
                fi

                if [ "${GIL}" == "--no-gil" ]; then
                    if [[ ! ${PY_VERSION} =~ ^(3\.13|3\.14).* ]]; then
                        continue
                    fi
                fi

                echo "Running " ${PY_VERSION} ${MODE} ${BUILD} ${GIL}
                ./new_pytorch.sh --version ${PY_VERSION} ${MODE} ${BUILD} ${GIL}
            done
        done
    done
done
