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
    NSImage *imageLoadedByDefaultImplementation = [[self alloc] initWithContentsOfURL:url];
    if (imageLoadedByDefaultImplementation) {
        return imageLoadedByDefaultImplementation;
    }
    else {
        return [self oiio_forceImageWithContentsOfURL:url];
    }
    return nil;
}

+ (instancetype)oiio_forceImageWithContentsOfURL:(NSURL *)url {
    OIIOImageRep *rep = [OIIOImageRep imageRepWithContentsOfURL:url];
    if (rep) {
        return [self oiio_imageWithRepresentation:rep];
    }
    return nil;
}
    
+ (instancetype)oiio_imageWithRepresentation:(NSBitmapImageRep *)rep {
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(rep.pixelsWide, rep.pixelsHigh)];
    [image addRepresentation:rep];
    return image;
}

- (NSDictionary *)ooio_metadata {
    for (NSImageRep *rep in self.representations) {
        if ([rep respondsToSelector:@selector(ooio_metadata)]) {
            return [rep performSelector:@selector(ooio_metadata) withObject:nil];
        }
    }
    return nil;
}


@end
