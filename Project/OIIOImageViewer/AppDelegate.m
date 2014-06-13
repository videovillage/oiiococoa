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
    
    // Setup drag and drop.
    [self.imageView unregisterDraggedTypes];
    [self.imageView.window registerForDraggedTypes:@[NSFilenamesPboardType]];
    [self.imageView.window setDelegate:self];
    

    // Find data of image in bundle
    NSURL *file = [[NSBundle mainBundle] URLForResource:@"Digital_LAD_2048x1556" withExtension:@"dpx"];

    // Initialize an image from URL. Always use OpenImageIO.
    NSImage *image = [NSImage oiio_forceImageWithContentsOfURL:file];

    // Display it
    [self setImage:image];
}

- (void)setImage:(NSImage *)image {
    self.imageView.image = image;
    
    NSLog(@"Image: %@", image);
    NSLog(@"Image Metadata: %@", image.ooio_metadata);
}

#pragma mark -
#pragma mark Window Delegate
    
-(NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
    return NSDragOperationGeneric;
}

    
-(BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender {
    return YES;
}
    
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        [NSApp activateIgnoringOtherApps:YES];
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        [self setImage:[NSImage oiio_forceImageWithContentsOfURL:[NSURL fileURLWithPath:files[0]]]];
        return YES;
    }
    return NO;
}

@end
