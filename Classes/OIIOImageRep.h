//
//  OIIOImageRep.h
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, OIIOImageEncodingType) {
    OIIOImageEncodingTypeUINT8,
    OIIOImageEncodingTypeINT8,
    OIIOImageEncodingTypeUINT10,
    OIIOImageEncodingTypeUINT12,
    OIIOImageEncodingTypeUINT16,
    OIIOImageEncodingTypeINT16,
    OIIOImageEncodingTypeUINT32,
    OIIOImageEncodingTypeINT32,
    OIIOImageEncodingTypeHALF,
    OIIOImageEncodingTypeFLOAT,
    OIIOImageEncodingTypeDOUBLE
};

typedef void (^OIIOTimerBlockType)();
void OIIOTimer(NSString *message, OIIOTimerBlockType block);

@interface OIIOImageRep : NSBitmapImageRep

@property (strong) NSDictionary *ooio_metadata;

- (BOOL)writeToURL:(NSURL *)url
      encodingType:(OIIOImageEncodingType)encodingType;



@end
