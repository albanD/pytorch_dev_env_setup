#! /bin/bash

set -e

VERSIONS=("3.6" "3.7" "3.8" "3.9")
MODES=("release" "debug")

INSTALL_HOME=${HOME}/local/installs
echo "Installing all pythons in ${INSTALL_HOME}"

for VERSION in "${VERSIONS[@]}"; do
    for MODE in "${MODES[@]}"; do
        if [ "${MODE}" = "release" ]; then
            CONFIG_OPT="--enable-optimizations"
        else
            CONFIG_OPT="--with-pydebug"
        fi
        CURR_INSTALL_REPO=${INSTALL_HOME}/python${VERSION}/${MODE}/install
        CURR_SOURCE_REPO=${INSTALL_HOME}/python${VERSION}/${MODE}/source
        if [ -d ${CURR_SOURCE_REPO} ]; then
            continue
        fi

        git clone git@github.com:python/cpython.git ${CURR_SOURCE_REPO}
        pushd ${CURR_SOURCE_REPO}
        git checkout ${VERSION}
        ./configure --prefix=${CURR_INSTALL_REPO} --with-ensurepip=install ${CONFIG_OPT}
        make -j$(nproc)
        make install
        popd

        ${CURR_INSTALL_REPO}/bin/pip${VERSION} install virtualenv
    done
done
