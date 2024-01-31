This is a fork of https://github.com/MaxKellermann/cegcc-build to build a CeGCC 9.3.0 toolchain.
Unlike Max Kellermann's repo, this one targets x86 Windows CE devices.

Clone this repository using::

 git clone git://github.com/enlyze/cegcc-build

To build::

 cd cegcc-build
 git submodule update --init
 ./build_cf.sh /where/to/install
