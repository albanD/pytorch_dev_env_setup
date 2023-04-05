#! /bin/bash

set -e

# VERSIONS=("3.8" "3.9" "3.10" "3.11")
VERSIONS=("3.10")
# MODES=("release" "debug" "shared")
MODES=("debug")

INSTALL_HOME=${HOME}/local/installs
echo "Installing all pythons in ${INSTALL_HOME}"

for VERSION in "${VERSIONS[@]}"; do
    for MODE in "${MODES[@]}"; do
        if [ "${MODE}" = "release" ]; then
            # CONFIG_OPT="--enable-optimizations"
            CONFIG_OPT=""
        else
            # Shared is always debug build!
            CONFIG_OPT="--with-pydebug"
        fi

        if [ "${MODE}" = "shared" ]; then
            SHARED_OPT="--enable-shared"
        else
            SHARED_OPT=""
        fi

        CURR_INSTALL_REPO=${INSTALL_HOME}/python${VERSION}/${MODE}/install
        CURR_SOURCE_REPO=${INSTALL_HOME}/python${VERSION}/${MODE}/source
        if [ -d ${CURR_SOURCE_REPO} ]; then
            continue
        fi

        git clone git@github.com:python/cpython.git ${CURR_SOURCE_REPO}
        pushd ${CURR_SOURCE_REPO}
        git checkout ${VERSION}
        ./configure --prefix=${CURR_INSTALL_REPO} --with-ensurepip=install ${SHARED_OPT} ${CONFIG_OPT}
        make -j$(nproc)
        make install
        popd

        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${CURR_INSTALL_REPO}/lib ${CURR_INSTALL_REPO}/bin/pip${VERSION} install virtualenv
    done
done
