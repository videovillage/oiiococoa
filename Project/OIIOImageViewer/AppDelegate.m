//
//  DPXAppDelegate.m
//  OIIOImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    // Find data of image in bundle
    NSURL *file = [[NSBundle mainBundle] URLForResource:@"Digital_LAD_2048x1556" withExtension:@"dpx"];
//    NSURL *file = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"png"];

    // Initialize an image from URL.
    NSImage *image = [NSImage oiio_initWithContentsOfURL:file];

    // Display it
    self.imageView.image = image;

    NSLog(@"Image: %@", image);
    NSLog(@"Image Metadata: %@", image.ooio_metadata);

}

@end
