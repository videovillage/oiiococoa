//
//  OIIOImageRep.h
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void (^OIIOTimerBlockType)();
void OIIOTimer(NSString *message, OIIOTimerBlockType block);

@interface OIIOImageRep : NSBitmapImageRep

@property (strong) NSDictionary *ooio_metadata;

@end
