//
//  NSImage+OIIO.h
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/9/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OIIOImageRep.h"

@interface NSImage (OIIO)

/**
 *  Initializes an image with the contents of the URL. If NSImage's default implementation fails to read the image, it will be loaded using OpenImageIO.
 *
 *  @param url A file URL.
 *
 *  @return An image.
 */
+ (instancetype)oiio_imageWithContentsOfURL:(NSURL *)url;

/**
 *  Initializes an image with the contents of the URL, loaded using OpenImageIO. This will not fall back to NSImage's default implementation.
 *
 *  @param url A file URL.
 *
 *  @return An image.
 */
+ (instancetype)oiio_forceImageWithContentsOfURL:(NSURL *)url;

// Convenience for creating image with a representation.
+ (instancetype)oiio_imageWithRepresentation:(NSBitmapImageRep *)rep;

- (BOOL)oiio_forceWriteToURL:(NSURL *)url
                encodingType:(OIIOImageEncodingType)encodingType;

- (NSData *)DPXRepresentationWithBitDepth:(NSInteger)bitDepth;

- (OIIOImageEncodingType)oiio_getEncodingType;

- (NSDictionary *)oiio_metadata;

- (OIIOImageRep *)oiio_findOIIOImageRep;

+ (NSArray *)oiio_imageFileTypes;

+ (NSArray *)oiio_allImageFileTypes;

+ (NSArray *)oiio_imageTypes;

+ (NSArray *)oiio_allImageTypes;

// Convenience methods for finding metadata.

+ (NSString *)oiio_stringFromEncodingType:(OIIOImageEncodingType)type;

+ (CFStringRef)dpxUTI;

@end
