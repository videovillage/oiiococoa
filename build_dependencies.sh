#/usr/bin/bash

brew install cmake
brew upgrade cmake
brew install Boost
brew upgrade Boost
brew install libtiff
brew upgrade libtiff
brew install libpng
brew upgrade libpng
brew install jpeg
brew upgrade jpeg
brew install xz
brew upgrade xz
brew install ilmbase
brew upgrade ilmbase

brew install autoconf
brew upgrade autoconf
brew install automake
brew upgrade automake
brew install libtool
brew upgrade libtool

brew uninstall openexr
git clone https://github.com/openexr/openexr.git openexr
cd openexr/OpenEXR
./bootstrap 
./configure
make install

rm -rf ../../Vendor/openexr/lib/*
cp IlmImf/.libs/libIlmImf.a ../../Vendor/openexr/lib

cd ../../

rm -rf openexr

rm -rf Vendor/boost/lib/*
cp /usr/local/opt/boost/lib/libboost_filesystem.a Vendor/boost/lib
cp /usr/local/opt/boost/lib/libboost_regex.a Vendor/boost/lib
cp /usr/local/opt/boost/lib/libboost_system.a Vendor/boost/lib
cp /usr/local/opt/boost/lib/libboost_thread-mt.a Vendor/boost/lib

rm -rf Vendor/ilmbase/lib/*
cp /usr/local/opt/ilmbase/lib/libHalf.a Vendor/ilmbase/lib
cp /usr/local/opt/ilmbase/lib/libIex.a Vendor/ilmbase/lib
cp /usr/local/opt/ilmbase/lib/libIexMath.a Vendor/ilmbase/lib
cp /usr/local/opt/ilmbase/lib/libIlmThread.a Vendor/ilmbase/lib
cp /usr/local/opt/ilmbase/lib/libImath.a Vendor/ilmbase/lib

rm -rf Vendor/libjpeg/lib/*
cp /usr/local/opt/jpeg/lib/libjpeg.a Vendor/jpeg/lib

rm -rf Vendor/libpng/lib/*
cp /usr/local/opt/libpng/lib/libpng16.a Vendor/libpng/lib

rm -rf Vendor/libtiff/lib/*
cp /usr/local/opt/libtiff/lib/libtiff.a Vendor/libtiff/lib
cp /usr/local/opt/libtiff/lib/libtiffxx.a Vendor/libtiff/lib

rm -rf Vendor/xz/lib/*
cp /usr/local/opt/xz/lib/liblzma.a Vendor/xz/lib


git clone https://github.com/OpenImageIO/oiio.git oiio
cd oiio
make BUILDSTATIC=1 LINKSTATIC=1 OIIO_BUILD_TOOLS=0 OIIO_BUILD_TESTS=0 USE_PYTHON=0 USE_OPENJPEG=0 USE_GIF=0 USE_OPENGL=1 USE_QT=0
rm -rf ../Vendor/OpenImageIO/include/*
rm -rf ../Vendor/OpenImageIO/lib/*
cp -R dist/macosx/include/* ../Vendor/OpenImageIO/include
cp -R dist/macosx/lib/* ../Vendor/OpenImageIO/lib
cd ../
