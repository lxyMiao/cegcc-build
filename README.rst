This is a fork of https://github.com/MaxKellermann/cegcc-build to build a CeGCC 14.2.0 toolchain.
Unlike Max Kellermann's repo, this one also targets x86 Windows CE devices.

Clone this repository using::

 git clone git://github.com/salman-javed-nz/cegcc-build

To build::

 cd cegcc-build
 git submodule update --init
 ./build_cf.sh /where/to/install i386-mingw32ce

Alternatively, you can also build an arm-mingw32ce toolchain.
This version builds up on Max Kellermann's work and enables some more modern C++ features and Windows CE API definitions.
