//
//  OIIOImageRep.m
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "OIIOImageRep.h"
#include <OpenImageIO/imageio.h>

OIIO_NAMESPACE_USING

@implementation OIIOImageRep

//+ (void)load {
//    NSLog(@"load PLUS");
//    [NSImageRep registerImageRepClass:self];
//}
//
//+ (BOOL)canInitWithData:(NSData *)data {
//    NSLog(@"CEE PLUS PLUS");
//    return YES;
//}

+ (NSImage *)imageFromURL:(NSURL *)url {

    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    int xres = spec.width;
    int yres = spec.height;
    int channels = spec.nchannels;
    
    std::vector<double> pixels (xres*yres*channels);

    
    in->read_image (TypeDesc::DOUBLE, &pixels[0]);
    in->close ();
    delete in;
    
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                                        pixelsWide:spec.width
                                                                        pixelsHigh:spec.height
                                                                     bitsPerSample:16
                                                                   samplesPerPixel:3
                                                                          hasAlpha:NO
                                                                          isPlanar:NO
                                                                    colorSpaceName:NSCalibratedRGBColorSpace
                                                                       bytesPerRow:0
                                                                      bitsPerPixel:0];
    
    for (NSUInteger x = 0; x < spec.width; x++) {
        for (NSUInteger y = 0; y < spec.height; y++) {
            
            NSUInteger i = x + y * spec.width;
        
            double red = pixels[i * spec.nchannels];
            double green = pixels[i * spec.nchannels + 1];
            double blue = pixels[i * spec.nchannels + 2];

            [imageRep setColor:[NSColor colorWithCalibratedRed:red
                                                         green:green
                                                          blue:blue
                                                         alpha:0] atX:x y:y];
            
        }
    }

    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(spec.width, spec.height)];
    [image addRepresentation:imageRep];
    
    return image;
}

@end
