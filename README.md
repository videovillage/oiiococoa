# oiiococoa

[![Version](https://img.shields.io/cocoapods/v/oiiococoa.svg?style=flat)](http://cocoadocs.org/docsets/oiiococoa)
[![License](https://img.shields.io/cocoapods/l/oiiococoa.svg?style=flat)](http://cocoadocs.org/docsets/oiiococoa)
[![Platform](https://img.shields.io/cocoapods/p/oiiococoa.svg?style=flat)](http://cocoadocs.org/docsets/oiiococoa)
([pronunciation guide](http://www.youtube.com/watch?v=p7c3bQQmwVE#t=36))

Easily use some [OpenImageIO](http://openimageio.org) magic in your Cocoa apps.

## Features

- Read into image files into NSImage via OpenImageIO. 
- Supported file formats:
  - TIFF
  - JPEG/JFIF
  - OpenEXR
  - PNG
  - HDR/RGBE
  - Targa
  - JPEG-2000
  - DPX
  - Cineon
  - FITS
  - BMP
  - ICO
  - RMan Zfile
  - Softimage PIC
  - DDS
  - SGI
  - Maya IFF
  - PNM/PPM/PGM/PBM
  - Field3d
  - WebP
  - Photoshop PSD
  - Wavefront RLA

## Installation

oiiococoa is available through [CocoaPods](http://cocoapods.org), to install
it simply add the following line to your Podfile:

    pod 'oiiococoa', :head
    
## Usage

It's pretty simple.

```objc
// Get the URL to an image file.
NSURL *file = [[NSBundle mainBundle] URLForResource:@"dlad_1920x1080" withExtension:@"dpx"];

// Load it up.
NSImage *image = [NSImage oiio_initWithContentsOfURL:file];
```

## Author

Wil Gieseler ([wilg](//github.com/wilg))
Greg Cotten ([gregcotten](//github.com/gregcotten))

## License

oiiococoa is available under the MIT license. 

License details and the licenses for dependencies are included in [LICENSE.md](LICENSE.md).
