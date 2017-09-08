//
//  OIIOHelper.h
//  Pods
//
//  Created by Greg Cotten on 9/20/16.
//
//

#import <Foundation/Foundation.h>

@interface OIIOHelper : NSObject
NS_ASSUME_NONNULL_BEGIN
+ (nullable NSData *)RGBAfBitmapFromURL:(nonnull NSURL *)url
                 outPixelWidth:(nonnull NSInteger *)outWidth
                outPixelHeight:(nonnull NSInteger *)outHeight;

+ (nullable NSData *)BGRA8UBitmapFromURL:(NSURL *)url
                            outPixelWidth:(NSInteger *)outWidth
                           outPixelHeight:(NSInteger *)outHeight;

+ (nullable NSData *)RGBAhBitmapFromURL:(nonnull NSURL *)url
                 outPixelWidth:(nonnull NSInteger *)outWidth
                outPixelHeight:(nonnull NSInteger *)outHeight;

+ (NSData *)EXRFromRGBAfBitmap:(NSData *)bitmap
                         width:(NSInteger)width
                        height:(NSInteger)height
                   exrBitDepth:(NSInteger)exrBitDepth;
NS_ASSUME_NONNULL_END
@end
