#! /bin/bash

set -e

INSTALL_HOME=${HOME}/local/installs
echo "Installing all the dependencies in ${INSTALL_HOME}"

mkdir -p ${INSTALL_HOME}
pushd ${INSTALL_HOME}

CMAKE_INSTALL_PATH=${INSTALL_HOME}/cmake
if [ ! -d ${CMAKE_INSTALL_PATH} ]
then
    CMAKE_TMP_INSTALL_PATH=${INSTALL_HOME}/cmake_tmp
    wget https://github.com/Kitware/CMake/releases/download/v3.15.3/cmake-3.15.3.tar.gz
    tar zxvf cmake-3.15.3.tar.gz
    rm cmake-3.15.3.tar.gz
    mv cmake-3.15.3 ${CMAKE_TMP_INSTALL_PATH}

    pushd ${CMAKE_TMP_INSTALL_PATH}
    ./bootstrap --prefix=${CMAKE_INSTALL_PATH}
    make -j$(nproc)
    make install
    popd
    rm -rf ${CMAKE_TMP_INSTALL_PATH}

    echo ""
    echo "# cmake path update:" >> ~/.bashrc
    echo "export PATH=\${PATH}:${CMAKE_INSTALL_PATH}/bin" >> ~/.bashrc
    PATH=${PATH}:${CMAKE_INSTALL_PATH}/bin
fi

OPENBLAS_INSTALL_PATH=${INSTALL_HOME}/openblas
if [ ! -d ${OPENBLAS_INSTALL_PATH} ]
then
    OPENBLAS_TMP_INSTALL_PATH=${INSTALL_HOME}/openblas_tmp
    git clone https://github.com/xianyi/OpenBLAS ${OPENBLAS_TMP_INSTALL_PATH}
    pushd ${OPENBLAS_TMP_INSTALL_PATH}
    make -j$(nproc)
    make PREFIX=${OPENBLAS_INSTALL_PATH} install
    popd
    rm -rf ${OPENBLAS_TMP_INSTALL_PATH}

    echo ""
    echo "# OpenBLAS library path update:" >> ~/.bashrc
    echo "export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:${OPENBLAS_INSTALL_PATH}/lib" >> ~/.bashrc
    LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${OPENBLAS_INSTALL_PATH}/lib
fi

AUTOCONF_INSTALL_PATH=${INSTALL_HOME}/autoconf
if [ ! -d ${AUTOCONF_INSTALL_PATH} ]
then
    AUTOCONF_TMP_INSTALL_PATH=${INSTALL_HOME}/autoconf_tmp
    wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
    tar zxvf autoconf-2.69.tar.gz
    rm autoconf-2.69.tar.gz
    mv autoconf-2.69 ${AUTOCONF_TMP_INSTALL_PATH}

    pushd ${AUTOCONF_TMP_INSTALL_PATH}
    ./configure --prefix=${AUTOCONF_INSTALL_PATH}
    make -j$(nproc)
    make install
    popd
    rm -rf ${AUTOCONF_TMP_INSTALL_PATH}

    echo ""
    echo "# autoconf path update:" >> ~/.bashrc
    echo "export PATH=\${PATH}:${AUTOCONF_INSTALL_PATH}/bin" >> ~/.bashrc
    PATH=${PATH}:${AUTOCONF_INSTALL_PATH}/bin
fi

AUTOMAKE_INSTALL_PATH=${INSTALL_HOME}/automake
if [ ! -d ${AUTOMAKE_INSTALL_PATH} ]
then
    AUTOMAKE_TMP_INSTALL_PATH=${INSTALL_HOME}/automake_tmp
    wget http://ftp.gnu.org/gnu/automake/automake-1.16.tar.gz
    tar zxvf automake-1.16.tar.gz
    rm automake-1.16.tar.gz
    mv automake-1.16 ${AUTOMAKE_TMP_INSTALL_PATH}

    pushd ${AUTOMAKE_TMP_INSTALL_PATH}
    ./configure --prefix=${AUTOMAKE_INSTALL_PATH}
    make install-binSCRIPTS
    popd
    rm -rf ${AUTOMAKE_TMP_INSTALL_PATH}

    echo ""
    echo "# automake path update:" >> ~/.bashrc
    echo "export PATH=\${PATH}:${AUTOMAKE_INSTALL_PATH}/bin" >> ~/.bashrc
    PATH=${PATH}:${AUTOMAKE_INSTALL_PATH}/bin
fi

CCACHE_INSTALL_PATH=${INSTALL_HOME}/ccache
if [ ! -d ${CCACHE_INSTALL_PATH} ]
then
    CCACHE_TMP_INSTALL_PATH=${INSTALL_HOME}/ccache_tmp
    git clone https://github.com/ccache/ccache ${CCACHE_TMP_INSTALL_PATH}
    pushd ${CCACHE_TMP_INSTALL_PATH}
    git checkout v3.7.3
    ./autogen.sh
    ./configure --disable-man
    make  -j$(nproc)
    make install prefix=${CCACHE_INSTALL_PATH}
    popd
    rm -rf ${CCACHE_TMP_INSTALL_PATH}

    ln -s ${CCACHE_INSTALL_PATH}/bin/ccache ${CCACHE_INSTALL_PATH}/bin/cc
    ln -s ${CCACHE_INSTALL_PATH}/bin/ccache ${CCACHE_INSTALL_PATH}/bin/c++
    ln -s ${CCACHE_INSTALL_PATH}/bin/ccache ${CCACHE_INSTALL_PATH}/bin/gcc
    ln -s ${CCACHE_INSTALL_PATH}/bin/ccache ${CCACHE_INSTALL_PATH}/bin/g++
    ln -s ${CCACHE_INSTALL_PATH}/bin/ccache ${CCACHE_INSTALL_PATH}/bin/nvcc

    echo ""
    echo "# ccache path update (had to be first in the path):" >> ~/.bashrc
    echo "export PATH=${CCACHE_INSTALL_PATH}/bin:\${PATH}" >> ~/.bashrc
    PATH=${CCACHE_INSTALL_PATH}/bin:${PATH}
fi

DIRENV_INSTALL_PATH=${INSTALL_HOME}/direnv
if [ ! -d ${DIRENV_INSTALL_PATH} ]
then
    mkdir -p ${DIRENV_INSTALL_PATH}
    pushd ${DIRENV_INSTALL_PATH}
    wget https://github.com/direnv/direnv/releases/download/v2.20.0/direnv.linux-amd64
    mv direnv.linux-amd64 direnv
    chmod +x direnv
    popd

    echo ""
    echo "# direnv path update and hooking in the terminal" >> ~/.bashrc
    echo "export PATH=\${PATH}:${DIRENV_INSTALL_PATH}" >> ~/.bashrc
    echo "eval \"\$(direnv hook bash)\"" >> ~/.bashrc
fi


SQLITE_INSTALL_PATH=${INSTALL_HOME}/sqlite
if [ ! -d ${SQLITE_INSTALL_PATH} ]
then
    SQLITE_TMP_INSTALL_PATH=${INSTALL_HOME}/sqlite_tmp
    wget https://www.sqlite.org/2019/sqlite-autoconf-3290000.tar.gz
    tar zxvf sqlite-autoconf-3290000.tar.gz
    rm sqlite-autoconf-3290000.tar.gz
    mv sqlite-autoconf-3290000 ${SQLITE_TMP_INSTALL_PATH}

    pushd ${SQLITE_TMP_INSTALL_PATH}
    ./configure --prefix=${SQLITE_INSTALL_PATH}
    make
    make install
    popd
    rm -rf ${SQLITE_TMP_INSTALL_PATH}



    echo ""
    echo "# sqlite detection update (python will find the lib relatively from sqlite3.h" >> ~/.bashrc
    echo "export CPPFLAGS=-I/home/albandes/local/installs/sqlite/include" >> ~/.bashrc
fi

popd
echo 'All done, you probably want to "source ~/.bashrc" now'
