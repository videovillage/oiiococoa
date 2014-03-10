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

    std::vector<unsigned short> pixels (spec.width * spec.height * spec.nchannels);
    
    in->read_image (TypeDesc::UINT16, &pixels[0]);
    in->close ();
    
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
    
    OIIOImageRep *imageRep = [[self.class alloc] initWithBitmapDataPlanes:(unsigned char**)&pixels
                                                               pixelsWide:spec.width
                                                               pixelsHigh:spec.height
                                                            bitsPerSample:16
                                                          samplesPerPixel:spec.nchannels
                                                                 hasAlpha:NO
                                                                 isPlanar:NO
                                                           colorSpaceName:NSCalibratedRGBColorSpace
                                                              bytesPerRow:spec.width * ((16 * spec.nchannels) / 8)
                                                             bitsPerPixel:16 * spec.nchannels];
    imageRep.ooio_metadata = [attributes copy];

    delete in;

    return imageRep;
}
    
- (BOOL)drawInRect:(NSRect)dstSpacePortionRect fromRect:(NSRect)srcSpacePortionRect operation:(NSCompositingOperation)op fraction:(CGFloat)requestedAlpha respectFlipped:(BOOL)respectContextIsFlipped hints:(NSDictionary *)hints NS_AVAILABLE_MAC(10_6) {
    
    return [super drawInRect:dstSpacePortionRect fromRect:srcSpacePortionRect operation:op fraction:requestedAlpha respectFlipped:respectContextIsFlipped hints:hints];
}

@end
