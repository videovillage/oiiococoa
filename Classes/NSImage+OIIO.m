//
//  NSImage+OIIO.m
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/9/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "NSImage+OIIO.h"
#import "OIIOImageRep.h"

@implementation NSImage (OIIO)

+ (instancetype)oiio_imageWithContentsOfURL:(NSURL *)url {
    return [[self alloc] initWithContentsOfURL:url];
}


+ (instancetype)oiio_initWithContentsOfURL:(NSURL *)url {
    OIIOImageRep *rep = [OIIOImageRep imageRepWithContentsOfURL:url];
    if (rep) {
        return [self oiio_imageWithRepresentation:rep];
    }
    else {
        return [[self alloc] initWithContentsOfURL:url];
    }
}

+ (instancetype)oiio_imageWithRepresentation:(NSBitmapImageRep *)rep {
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(rep.pixelsWide, rep.pixelsHigh)];
    [image addRepresentation:rep];
    return image;
}


@end
