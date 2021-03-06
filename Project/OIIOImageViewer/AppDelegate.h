//
//  DPXAppDelegate.h
//  OIIOImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSImage+OIIO.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSImageView *imageView;

@property (strong) NSArray *urlList;
@property (strong) NSURL *selectedURL;

@end
