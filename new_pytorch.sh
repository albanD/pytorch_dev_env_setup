#!/bin/bash

set -e

PYTORCH_INSTALL_BASE=${HOME}/local/pytorch
INSTALL_HOME=${HOME}/local/installs


# Default for cla
DO_DEBUG="0"
USE_BINARY="0"
COMPAT_GCC="0" # Use this if gcc < 5.0
PY_VERSION="3.6"
CUDA_VERSION="cpu"

PARAMS=""
while (( "$#" )); do
  case "$1" in
    --debug)
      DO_DEBUG="1"
      shift 1
      ;;
    --binary)
      USE_BINARY="1"
      shift 1
      ;;
    --old-gcc)
      COMPAT_GCC="1"
      shift 1
      ;;
    -v|--version)
      PY_VERSION=$2
      shift 2
      ;;
    -c|--cuda)
      CUDA_VERSION=$2
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done
# set positional arguments in their proper place
eval set -- "$PARAMS"
if [ ! "$PARAMS" == "" ]; then
    echo "ERROR: Positional arguments are not allowed"
    false
fi

MODE="release"
if [ "${DO_DEBUG}" == "1" ]; then
    MODE="debug"
fi
TYPE="source"
if [ "${USE_BINARY}" == "1" ]; then
    TYPE="binary"
fi

# Workaround bad detection code
if [ "${CUDA_VERSION}" == "cpu" ]; then
    export USE_CUDA=0
fi

INSTALL_PATH=${PYTORCH_INSTALL_BASE}/${PY_VERSION}_${MODE}_${TYPE}
ENV_PATH=${PYTORCH_INSTALL_BASE}/${PY_VERSION}_${MODE}_${TYPE}_env
PY_INSTALL_REPO=${INSTALL_HOME}/python${PY_VERSION}/${MODE}/install

if [ -d ${INSTALL_PATH} ]; then
  echo "Install path already exists, skipping ${INSTALL_PATH}"
  exit 0
fi

${PY_INSTALL_REPO}/bin/virtualenv -p ${PY_INSTALL_REPO}/bin/python${PY_VERSION} ${ENV_PATH}

if [ "${USE_BINARY}" == "1" ]; then
    mkdir -p ${INSTALL_PATH}
    pushd ${INSTALL_PATH}
    echo ". ${ENV_PATH}/bin/activate" > .envrc
    direnv allow
    touch test.py

    . ${ENV_PATH}/bin/activate
    pip install numpy
    pip install --pre torch torchvision -f https://download.pytorch.org/whl/nightly/${CUDA_VERSION}/torch_nightly.html
    deactivate
    popd

else
    git clone git@github.com:pytorch/pytorch.git ${INSTALL_PATH}
    pushd ${INSTALL_PATH}
    git submodule update --init --recursive

    echo ". ${ENV_PATH}/bin/activate" > .envrc
    direnv allow

    . ${ENV_PATH}/bin/activate
    if [ "${COMPAT_GCC}" == "1" ]; then
        # For numpy install
        export OPENBLAS=${INSTALL_HOME}/openblas/lib/libopenblas.so
    fi
    # Warning: numpy won't find OpenBLAS here
    pip install -r requirements.txt
    if [ "${PY_VERSION}" == "2.7" ]; then
        pip install future
    fi
    pip install ninja
    python setup.py develop

    deactivate
    popd


fi
