# pytorch_dev_env_setup

Small script to setup a full dev-env for different python versions

## What it will create
HOME=~/local is the base of everything
HOME/installs all the local installs
HOME/installs_source
HOME/pytorch/PY_VERSION contains a pytorch install for that particular python version

WIP:
## Brand new install

### Cmake
wget whatever from https://cmake.org/download/
tar zxvf cmake-3.*
cd cmake-3.*
./bootstrap --prefix=/home/albandes/local/cmake_install
make -j$(nproc)
make install
add cmake_install to PATH

### OpenBLAS
git clone https://github.com/xianyi/OpenBLAS
make
make PREFIX=/home/albandes/local/openblas_install install
add /home/albandes/local/openblas_install/lib to LD_LIBRARY_PATH

### Ccache
Get autoconf from http://ftp.gnu.org/gnu/autoconf/
install
Get ccache https://github.com/ccache/ccache
./autogen.sh
./configure
make install prefix=/home/albandes/local/ccache_install
ln -s ~/local/tmp_ccache_install/bin/ccache ~/local/tmp_ccache_install/bin/cc
ln -s ~/local/tmp_ccache_install/bin/ccache ~/local/tmp_ccache_install/bin/c++
ln -s ~/local/tmp_ccache_install/bin/ccache ~/local/tmp_ccache_install/bin/gcc
ln -s ~/local/tmp_ccache_install/bin/ccache ~/local/tmp_ccache_install/bin/g++
ln -s ~/local/tmp_ccache_install/bin/ccache ~/local/tmp_ccache_install/bin/nvcc
export PATH=/home/albandes/local/tmp_ccache_install/bin:$PATH

### lld (not possible in devserver)

### direnv

### Python stuff
cpython download
cpython local install
use local pip to install virtualenv
use virtualenv to create env for this python
direnv is either provided or can be downloaded from they github
add ```eval "$(direnv hook bash)"``` at the end of bashrc and allow all the necessary folders

### Pytorch
git clone
submodule update init recursive
git remote add alban git@github.com:albanD/pytorch.git
pip install requirements.txt
pip install ninja
python setup.py develop

## Pytorch update
git checkout
submodule update
python setup.py clean
python setup.py develop
