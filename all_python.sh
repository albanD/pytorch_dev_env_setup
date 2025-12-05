#! /bin/bash

set -e

VERSIONS=("3.14")
# package/deploy is dead I guess
# MODES=("release" "debug" "shared" "nogil")
MODES=("release" "debug" "nogil")

INSTALL_HOME=${HOME}/local/installs
echo "Installing all pythons in ${INSTALL_HOME}"

for VERSION in "${VERSIONS[@]}"; do
    for MODE in "${MODES[@]}"; do
        if [ "${MODE}" = "release" ]; then
            # CONFIG_OPT="--enable-optimizations"
            CONFIG_OPT=""
        elif [ "${MODE}" = "nogil" ]; then
            # nogil is always debug build!
            CONFIG_OPT="--disable-gil --with-pydebug"
        else
            # Shared is always debug build!
            CONFIG_OPT="--with-pydebug"
        fi

        if [ "${MODE}" = "shared" ]; then
            SHARED_OPT="--enable-shared"
        else
            SHARED_OPT=""
        fi

        if [ "${MODE}" = "nogil" ]; then
            if [[ ! ${VERSION} =~ ^(3\.13|3\.14).* ]]; then
                continue
            fi
        fi

        CURR_INSTALL_REPO=${INSTALL_HOME}/python${VERSION}/${MODE}/install
        CURR_SOURCE_REPO=${INSTALL_HOME}/python${VERSION}/${MODE}/source
        if [ -d ${CURR_SOURCE_REPO} ]; then
            continue
        fi

        git clone git@github.com:python/cpython.git ${CURR_SOURCE_REPO}
        pushd ${CURR_SOURCE_REPO}
        # git checkout v${VERSION}
        git checkout ${VERSION}
        ./configure --prefix=${CURR_INSTALL_REPO} --with-ensurepip=install ${SHARED_OPT} ${CONFIG_OPT}
        make -j$(nproc)
        make install
        popd

        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${CURR_INSTALL_REPO}/lib ${CURR_INSTALL_REPO}/bin/pip3 install virtualenv uv
    done
done
