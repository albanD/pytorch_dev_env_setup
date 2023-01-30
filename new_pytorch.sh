#!/bin/bash

set -e
set -o xtrace

PYTORCH_INSTALL_BASE=${HOME}/local/pytorch
INSTALL_HOME=${HOME}/local/installs


# Default for cla
DO_DEBUG="0"
USE_BINARY="0"
USE_SHARED="0"
PY_VERSION="3.6"
CUDA_VERSION="cpu"
PREFIX=""

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
    --shared)
      USE_SHARED="1"
      shift 1
      ;;
    -v|--version)
      PY_VERSION=$2
      shift 2
      ;;
    -p|--prefix)
      PREFIX=$2
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

PILLOW_FLAG=""

MODE="release"
if [ "${DO_DEBUG}" == "1" ]; then
    MODE="debug"
fi
if [ "${USE_SHARED}" == "1" ]; then
    MODE="shared"
fi

TYPE="source"
if [ "${USE_BINARY}" == "1" ]; then
    TYPE="binary"
fi

# Workaround bad detection code
if [ "${CUDA_VERSION}" == "cpu" ]; then
    export USE_CUDA=0
fi

INSTALL_PATH=${PYTORCH_INSTALL_BASE}/${PREFIX}${PY_VERSION}_${MODE}_${TYPE}
ENV_PATH=${PYTORCH_INSTALL_BASE}/${PREFIX}${PY_VERSION}_${MODE}_${TYPE}_env
PY_INSTALL_REPO=${INSTALL_HOME}/python${PY_VERSION}/${MODE}/install

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${PY_INSTALL_REPO}/lib 

if [ -d ${INSTALL_PATH} ]; then
  echo "Install path already exists, skipping ${INSTALL_PATH}"
  exit 0
fi

echo $LD_LIBRARY_PATH

${PY_INSTALL_REPO}/bin/virtualenv -p ${PY_INSTALL_REPO}/bin/python${PY_VERSION} ${ENV_PATH}


if [ "${USE_BINARY}" == "1" ]; then
    mkdir -p ${INSTALL_PATH}
    pushd ${INSTALL_PATH}
    echo ". ${ENV_PATH}/bin/activate" > .envrc
    direnv allow
    touch test.py

    . ${ENV_PATH}/bin/activate
    pip install ipython
    # pip install ghstack
    pip install numpy
    pip install --pre torch torchvision torchaudio torchtext -f https://download.pytorch.org/whl/nightly/${CUDA_VERSION}/torch_nightly.html
    deactivate
    popd

else
    git clone git@github.com:pytorch/pytorch.git ${INSTALL_PATH}
    pushd ${INSTALL_PATH}
    git remote add alban git@github.com:albanD/pytorch.git
    git submodule update --init --recursive

    echo ". ${ENV_PATH}/bin/activate" > .envrc
    direnv allow

    . ${ENV_PATH}/bin/activate
    pip install ipython
    # pip install ghstack
    pip install hypothesis
    pip install Pillow
    # Warning: numpy won't find OpenBLAS here
    pip install -r requirements.txt
    if [ "${PY_VERSION}" == "2.7" ]; then
        pip install future
    fi
    pip install ninja
    python setup.py develop

    # ASAN command if you're advanturous
    # ASAN_OPTIONS="detect_leaks=0" CFLAGS="-fsanitize=address -fsanitize=undefined -fno-sanitize-recover=all -fsanitize-address-use-after-scope" USE_ASAN=1 USE_DISTRIBUTED=0 USE_MKLDNN=0 USE_CUDA=0 BUILD_TEST=0 USE_FBGEMM=0 USE_NNPACK=0 USE_QNNPACK=0 USE_XNNPACK=0 USE_COLORIZE_OUTPUT=0 python setup.py develop

    popd

    clone_lib () {
      git clone git@github.com:pytorch/$1.git ${INSTALL_PATH}_$1
      pushd ${INSTALL_PATH}_$1

      git submodule update --init --recursive

      echo ". ${ENV_PATH}/bin/activate" > .envrc
      direnv allow

      popd
    }

    install_lib () {
      clone_lib $1

      pushd ${INSTALL_PATH}_$1
      python setup.py develop
      popd
    }

    # Install domains!
    install_lib "vision"
    install_lib "audio"
    install_lib "data"
    install_lib "text"
    clone_lib "benchmark"

    deactivate

fi
