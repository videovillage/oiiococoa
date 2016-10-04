//
//  DPXAppDelegate.m
//  OIIOImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "AppDelegate.h"
#import "OIIOImageRep.h"
#import "NSImage+OIIO.h"


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
//    // Setup drag and drop.
    [self.imageView unregisterDraggedTypes];
    [self.imageView.window registerForDraggedTypes:@[NSFilenamesPboardType]];
    [self.imageView.window setDelegate:self];
//
//
//    // Find data of image in bundle
    NSURL *file = [[NSBundle mainBundle] URLForResource:@"Digital_LAD_2048x1556" withExtension:@"dpx"];
//    NSString *unexpandedFilePathToFolder = @"~/Downloads/oiio-images-master/";
//    
//    NSURL *folder = [NSURL fileURLWithPath:unexpandedFilePathToFolder.stringByExpandingTildeInPath isDirectory:YES];
//    
//    // Initialize an image from URL. Always use OpenImageIO.
//    NSArray * dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:folder
//                              includingPropertiesForKeys:@[]
//                                                 options:NSDirectoryEnumerationSkipsHiddenFiles
//                                                   error:nil];
//    
//    NSMutableArray *allFiles = [NSMutableArray array];
//    
//    for (NSURL *url in dirContents) {
//        NSNumber *isDirectory;
//        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
//        if (![isDirectory boolValue] && [[NSImage oiio_imageFileTypes] containsObject:[url pathExtension]]) {
//            [allFiles addObject:url];
//        }
//    }
//    
//    [self addObserver:self
//           forKeyPath:@"selectedURL"
//              options:NSKeyValueObservingOptionNew
//              context:nil];
//    
//    self.urlList = [NSArray arrayWithArray:allFiles];
//    if(allFiles.count != 0){
//        self.selectedURL = allFiles[0];
//    }

    
    
    NSImage *image = [NSImage oiio_imageWithContentsOfURL:[file filePathURL]];
    
    [self setImage:image];
//    NSURL *saveURL = [NSURL fileURLWithPath:@"/Users/gregcotten/Desktop/test.dpx"];
//    NSData *imageData = [image DPXRepresentationWithBitDepth:10];
//    if (!imageData) {
//        NSLog(@"Failed to create destination image data");
//    }
//    BOOL success = [imageData writeToURL:saveURL atomically:YES];
//    
//    if(!success){
//        NSLog(@"Failed to write.");
//    }
//    else{
//        NSLog(@"Write Success.");
//    }

    // Display it
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    if([keyPath isEqualToString:@"selectedURL"]){
        NSImage *image = [NSImage oiio_forceImageWithContentsOfURL:self.selectedURL];
        [self setImage:image];
        
    }
    
}

- (void)setImage:(NSImage *)image {
    self.imageView.image = image;
    
    NSLog(@"Image: %@", image);
    NSLog(@"Image Metadata: %@", image.oiio_metadata);
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
