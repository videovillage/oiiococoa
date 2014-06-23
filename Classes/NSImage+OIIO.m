//
//  NSImage+OIIO.m
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/9/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "NSImage+OIIO.h"

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
    if(url == nil || [[NSFileManager defaultManager] fileExistsAtPath:[url path]] == NO){
        return nil;
    }
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

+ (NSArray *)oiio_imageFileTypes{
    return @[@"DPX", @"dpx"];
}

+ (NSArray *)oiio_allImageFileTypes{
    NSMutableArray *combinedFileTypes = [[NSImage imageFileTypes] mutableCopy];
    [combinedFileTypes addObjectsFromArray:[[self class] oiio_imageFileTypes]];
    return combinedFileTypes;
}

+ (NSArray *)oiio_imageTypes{
    return @[@"org.smpte.dpx"];
}

+ (NSArray *)oiio_allImageTypes{
    NSMutableArray *combinedTypes = [[NSImage imageTypes] mutableCopy];
    [combinedTypes addObjectsFromArray:[[self class] oiio_imageTypes]];
    return combinedTypes;
}

- (OIIOImageRep *)oiio_findOIIOImageRep{
    for (NSImageRep *rep in self.representations){
        if([rep class] == [OIIOImageRep class]){
            return (OIIOImageRep *)rep;
        }
    }
    return nil;
}

- (NSDictionary *)oiio_metadata{
    OIIOImageRep *rep = [self oiio_findOIIOImageRep];
    if(rep != nil){
        return rep.oiio_metadata;
    }
    return nil;
}

- (BOOL)oiio_forceWriteToURL:(NSURL *)url
                encodingType:(OIIOImageEncodingType)encodingType{
    OIIOImageRep *imageRep = [self oiio_findOIIOImageRep] == nil ? [[OIIOImageRep alloc] initWithData:[self TIFFRepresentation]] : [self oiio_findOIIOImageRep];

    return [imageRep writeToURL:url encodingType:encodingType];
}



- (OIIOImageEncodingType)oiio_getEncodingType{
    OIIOImageRep *imageRep = [self oiio_findOIIOImageRep];
    if(imageRep != nil){
        return imageRep.encodingType;
    }
    return OIIOImageEncodingTypeNONE;
}



+ (NSString *)oiio_stringFromEncodingType:(OIIOImageEncodingType)type{
    if(type == OIIOImageEncodingTypeUINT8){
        return @"UINT8";
    }
    else if(type == OIIOImageEncodingTypeINT8){
        return @"INT8";
    }
    else if(type == OIIOImageEncodingTypeUINT10){
        return @"UINT10";
    }
    else if(type == OIIOImageEncodingTypeUINT12){
        return @"UINT12";
    }
    else if(type == OIIOImageEncodingTypeUINT16){
        return @"UINT16";
    }
    else if(type == OIIOImageEncodingTypeINT16){
        return @"INT16";
    }
    else if(type == OIIOImageEncodingTypeUINT32){
        return @"UINT32";
    }
    else if(type == OIIOImageEncodingTypeINT32){
        return @"INT32";
    }
    else if(type == OIIOImageEncodingTypeHALF){
        return @"HALF";
    }
    else if(type == OIIOImageEncodingTypeFLOAT){
        return @"FLOAT";
    }
    else if(type == OIIOImageEncodingTypeDOUBLE){
        return @"DOUBLE";
    }
    return @"NONE";
}

@end
