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
//    NSData *data = [NSData dataWithContentsOfURL:file];
    
    // Initialize an image
//    NSImage *image = [[NSImage alloc] initWithData:data];
//    NSLog(@"Image: %@", image);
    
    NSImage *image = [OIIOImageRep imageFromURL:file];
    
//    [@"" cStringUsingEncoding:NSUTF8StringEncoding];

    // Display it
    self.imageView.image = image;
    
}

@end
