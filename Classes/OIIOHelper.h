//
//  OIIOHelper.h
//  Pods
//
//  Created by Greg Cotten on 9/20/16.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OIIOImageEncodingType) {
    OIIOImageEncodingTypeUINT8,
    OIIOImageEncodingTypeINT8,
    OIIOImageEncodingTypeUINT10,
    OIIOImageEncodingTypeUINT12,
    OIIOImageEncodingTypeUINT16,
    OIIOImageEncodingTypeINT16,
    OIIOImageEncodingTypeUINT32,
    OIIOImageEncodingTypeINT32,
    OIIOImageEncodingTypeHALF,
    OIIOImageEncodingTypeFLOAT,
    OIIOImageEncodingTypeDOUBLE,
    OIIOImageEncodingTypeNONE
};

@interface OIIOHelper : NSObject
NS_ASSUME_NONNULL_BEGIN
+ (BOOL)imageSpecFromURL:(NSURL *)url
                outWidth:(NSInteger *)outWidth
               outHeight:(NSInteger *)outHeight
             outChannels:(NSInteger *)outChannels
          outPixelFormat:(OIIOImageEncodingType *)outPixelFormat
            outFramerate:(double *)outFramerate
             outTimecode:(NSInteger *)outTimecode;

+ (nullable NSData *)RGB8UBitmapFromURL:(NSURL *)url
                          outPixelWidth:(NSInteger *)outWidth
                         outPixelHeight:(NSInteger *)outHeight;

+ (nullable NSData *)RGBA8UBitmapFromURL:(NSURL *)url
                           outPixelWidth:(NSInteger *)outWidth
                          outPixelHeight:(NSInteger *)outHeight;

+ (nullable NSData *)RGBAfBitmapFromURL:(nonnull NSURL *)url
                 outPixelWidth:(nonnull NSInteger *)outWidth
                outPixelHeight:(nonnull NSInteger *)outHeight;

+ (nullable NSData *)BGRA8UBitmapFromURL:(NSURL *)url
                            outPixelWidth:(NSInteger *)outWidth
                           outPixelHeight:(NSInteger *)outHeight;

+ (nullable NSData *)RGBA16UBitmapFromURL:(NSURL *)url
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
