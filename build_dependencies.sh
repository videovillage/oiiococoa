#/usr/bin/bash

brew install cmake
brew install Boost
brew install libtiff
brew install OpenEXR
git clone https://github.com/OpenImageIO/oiio.git oiio
cd oiio
make BUILDSTATIC=1 LINKSTATIC=1 OIIO_BUILD_TOOLS=0 OIIO_BUILD_TESTS=0 USE_PYTHON=0 USE_OPENJPEG=0 USE_GIF=0 USE_OPENGL=0 USE_QT=0
cp -R dist/macosx/lib ../Vendor/OpenImageIO/include
cp -R dist/macosx/lib ../Vendor/OpenImageIO/lib
