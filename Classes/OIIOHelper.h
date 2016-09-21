//
//  OIIOHelper.h
//  Pods
//
//  Created by Greg Cotten on 9/20/16.
//
//

#import <Foundation/Foundation.h>

@interface OIIOHelper : NSObject

+ (NSData *)RGBAfBitmapFromURL:(NSURL *)url
                 outPixelWidth:(NSInteger *)outWidth
                outPixelHeight:(NSInteger *)outHeight;

+ (NSData *)EXRFromRGBAfBitmap:(NSData *)bitmap
                         width:(NSInteger)width
                        height:(NSInteger)height
                   exrBitDepth:(NSInteger)exrBitDepth;

@end
