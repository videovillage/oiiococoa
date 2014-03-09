//
//  OIIOImageRep.m
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "OIIOImageRep.h"
#include "imageio.h"

void OIIOTimer(NSString *message, OIIOTimerBlockType block) {
    NSDate *methodStart = [NSDate date];
    block();
    NSTimeInterval executionTime = [[NSDate date] timeIntervalSinceDate:methodStart];
    NSLog(@"%@: %fs", message, executionTime);
}

OIIO_NAMESPACE_USING

@implementation OIIOImageRep

+ (void)load {
    [NSImageRep registerImageRepClass:self];
}


+ (BOOL)canInitWithData:(NSData *)data {
    return NO;
}

+ (NSArray *)imageUnfilteredTypes {
    return @[@"org.smpte.dpx"];
}

+ (id)imageRepWithContentsOfURL:(NSURL *)url {
    
    
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    int xres = spec.width;
    int yres = spec.height;
    int channels = spec.nchannels;

    std::vector<unsigned short> pixels (xres*yres*channels);
    
    
    in->read_image (TypeDesc::UINT16, &pixels[0]);
    in->close ();
    delete in;
    
    
    OIIOImageRep *imageRep = [[self.class alloc] initWithBitmapDataPlanes:(unsigned char**)&pixels
                                                               pixelsWide:spec.width
                                                               pixelsHigh:spec.height
                                                            bitsPerSample:16
                                                          samplesPerPixel:3
                                                                 hasAlpha:NO
                                                                 isPlanar:NO
                                                           colorSpaceName:NSCalibratedRGBColorSpace
                                                              bytesPerRow:0
                                                             bitsPerPixel:0];


    return imageRep;
}

@end
