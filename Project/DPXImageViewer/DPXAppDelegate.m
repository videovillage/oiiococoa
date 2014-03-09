//
//  DPXAppDelegate.m
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "DPXAppDelegate.h"

@implementation DPXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // Find data of image in bundle
    NSURL *file = [[NSBundle mainBundle] URLForResource:@"dlad_1920x1080" withExtension:@"dpx"];

    // Initialize an image from URL.
    NSImage *image = [NSImage oiio_initWithContentsOfURL:file];
    
    // Display it
    self.imageView.image = image;
    
    NSLog(@"Image: %@", image);
    
}

@end
