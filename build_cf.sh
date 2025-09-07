#!/bin/bash
#
# Builds a Binutils & GCC toolchain for Windows CE software development.
#
# Usage:
#   ./build_cf.sh PREFIX_DIRECTORY
#
# GNU tools can be confusing enough, so this script is meant to be simple:
# No branches, no options, just rebuilds the entire toolchain in the right order.
# If you want to skip a few steps, just comment them out.
#
# Written by Colin Finck for ENLYZE GmbH
#

set -eu

if [[ $# -ne 2 ]]; then
    echo "Usage: ./build_cf.sh PREFIXDIR TARGET"
    echo
    echo "Supported targets are":
    echo "  - arm-mingw32ce"
    echo "  - i386-mingw32ce"
    exit 1
fi

J="-j `nproc`"
OLDPATH="$PATH"
PREFIXDIR="$1"
TARGET="$2"

rm -rf ${PREFIXDIR}
mkdir ${PREFIXDIR}


# --enable-threads=win32 of our GCC build wants to include <windows.h> from w32api.
# But building w32api requires a target GCC.
#
# GCC solves this circular dependency by considering the optional directory "winsup".
# "winsup/mingw/include" and "winsup/w32api/include" are added to the include path when
# building target components.
cd gcc
sudo apt install libgmp-dev libmpfr-dev libmpc-dev -y
rm -rf winsup
mkdir winsup
cd winsup
ln -s ../../mingw
ln -s ../../w32api
cd ../..


echo "##################################"
echo "# BINUTILS                       #"
echo "##################################"

rm -rf binutils-build
mkdir binutils-build
cd binutils-build
../binutils/configure --prefix="${PREFIXDIR}" --target="${TARGET}" --with-pkgversion="salman-javed-nz" \
    --disable-multilib --disable-werror --enable-lto --enable-plugins \
    --with-zlib=yes --disable-nls --disable-unit-tests --disable-shared
make $J
make install
cd ..


echo "##################################"
echo "# INITIAL GCC                    #"
echo "##################################"

ADDITIONAL_GCC_PARAMETERS=""
if [[ "$TARGET" = "arm-mingw32ce" ]]; then
       ADDITIONAL_GCC_PARAMETERS+="--disable-__cxa_atexit"
fi

rm -rf gcc-build
mkdir gcc-build
cd gcc-build
../gcc/configure --prefix="${PREFIXDIR}" --target="${TARGET}" --with-pkgversion="salman-javed-nz" \
    --enable-languages=c,c++,go --disable-shared --disable-multilib --disable-nls \
    --disable-werror --disable-win32-registry --disable-libstdcxx-verbose \
    --disable-threads ${ADDITIONAL_GCC_PARAMETERS}

# Only build and install GCC so far to let us build low-level CE binaries.
make $J all-gcc
make install-gcc
make install-lto-plugin

# Building anything with GCC also requires libgcc.
make $J all-target-libgcc
make install-target-libgcc

cd ..


# mingw and w32api need to find the toolchain we just built.
export PATH="${PREFIXDIR}/bin:$PATH"

echo "##################################"
echo "# MINGW                          #"
echo "##################################"

rm -rf mingw-build
mkdir mingw-build
cd mingw-build
../mingw/configure --prefix="${PREFIXDIR}" --host="${TARGET}" --target="${TARGET}"
make $J
make install
cd ..


echo "##################################"
echo "# W32API                         #"
echo "##################################"

rm -rf w32api-build
mkdir w32api-build
cd w32api-build
../w32api/configure --prefix="${PREFIXDIR}" --host="${TARGET}" --target="${TARGET}"
make $J
make install
cd ..


# Continue building the rest of GCC as before.
# The remaining components (like libstdc++) can now depend on all headers and libraries
# of mingw and w32api.
export PATH="$OLDPATH"

echo "##################################"
echo "# REST OF GCC                    #"
echo "##################################"

cd gcc-build
make $J
make install
