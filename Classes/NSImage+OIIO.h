//
//  NSImage+OIIO.h
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/9/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (OIIO)

/**
 *  Initializes an image with the contents of the URL, using OpenImageIO. If OpenImageIO fails to read the image, it will be loaded using [NSImage initWithContentsOfURL:].
 *
 *  @param url A file URL.
 *
 *  @return An image.
 */
+ (instancetype)oiio_initWithContentsOfURL:(NSURL *)url;

// Convenience methods for creating images.
+ (instancetype)oiio_imageWithContentsOfURL:(NSURL *)url;
+ (instancetype)oiio_imageWithRepresentation:(NSBitmapImageRep *)rep;

@end
