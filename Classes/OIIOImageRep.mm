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

//+ (void)load {
//    [NSImageRep registerImageRepClass:self];
//}


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

    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    for (size_t i = 0;  i < spec.extra_attribs.size();  ++i) {
        
        const ParamValue &p (spec.extra_attribs[i]);
        NSString *name = [NSString stringWithCString:p.name().c_str() encoding:NSUTF8StringEncoding];
        id value = [NSNull null];
        
        if (p.type() == TypeDesc::TypeString){
            value = @(*(const char **)p.data());
        }
        else if (p.type() == TypeDesc::TypeFloat) {
            value = @(*(const float *)p.data());
        }
        else if (p.type() == TypeDesc::TypeInt) {
            value = @(*(const int *)p.data());
        }
        else if (p.type() == TypeDesc::UINT){
            value = @(*(const unsigned int *)p.data());
        }
//        else if (p.type() == TypeDesc::TypeMatrix) {
//            const float *f = (const float *)p.data();
//            printf ("\%f \%f \%f \%f \%f \%f \%f \%f "
//                    "\%f \%f \%f \%f \%f \%f \%f \%f",
//                    f[0], f[1], f[2], f[3], f[4], f[5], f[6], f[7],
//                    f[8], f[9], f[10], f[11], f[12], f[13], f[14], f[15]);
//        } else
//            printf ("<unknown data type>");
        attributes[name] = value;
    }
    imageRep.ooio_metadata = [attributes copy];

    return imageRep;
}

@end
