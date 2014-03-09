//
//  OIIOImageRep.h
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OIIOImageRep : NSImageRep

+ (NSImage *)imageFromURL:(NSURL *)url;

@end
