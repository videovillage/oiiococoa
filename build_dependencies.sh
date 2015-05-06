#/usr/bin/bash

brew upgrade cmake
brew upgrade Boost
brew upgrade libtiff
#brew upgrade OpenEXR
brew upgrade libpng
brew upgrade ilmbase
brew upgrade jpeg
brew upgrade xz
git clone https://github.com/OpenImageIO/oiio.git oiio
cd oiio
make BUILDSTATIC=1 LINKSTATIC=1 OIIO_BUILD_TOOLS=0 OIIO_BUILD_TESTS=0 USE_PYTHON=0 USE_OPENJPEG=0 USE_GIF=0 USE_OPENGL=1 USE_QT=0
cp -R dist/macosx/lib ../Vendor/OpenImageIO/include
cp -R dist/macosx/lib ../Vendor/OpenImageIO/lib
