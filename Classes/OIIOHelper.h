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

typedef NS_ENUM(NSInteger, OIIOImagePixelFormat) {
    OIIOImagePixelFormatRGB8U,
    OIIOImagePixelFormatRGBA8U,
    OIIOImagePixelFormatBGRA8U,
    OIIOImagePixelFormatRGBA16U,
    OIIOImagePixelFormatA2BGR10,
    OIIOImagePixelFormatRGB10A2UBigEndian,
    OIIOImagePixelFormatRGBAf,
    OIIOImagePixelFormatRGBAh
};

@interface OIIOHelper : NSObject
NS_ASSUME_NONNULL_BEGIN
+ (BOOL)imageSpecFromURL:(NSURL *)url
                outWidth:(NSInteger *)outWidth
               outHeight:(NSInteger *)outHeight
             outChannels:(NSInteger *)outChannels
          outPixelFormat:(OIIOImageEncodingType *)outPixelFormat
            outFramerate:(double *)outFramerate
             outTimecode:(NSInteger *)outTimecode
             outMetadata:(NSDictionary **)metadata;

+ (nullable NSData*)bitmapDataFromURL:(NSURL *)url
                          pixelFormat:(OIIOImagePixelFormat)pixelFormat
                             outWidth:(NSInteger *)outWidth
                            outHeight:(NSInteger *)outHeight;

+ (bool)loadBitmapIntoDataFromURL:(NSURL *)url
                      pixelFormat:(OIIOImagePixelFormat)pixelFormat
                           inData:(void *)pixelData
                        rowStride:(NSInteger)rowStride;

//+ (nullable NSData *)RGB8UBitmapFromURL:(NSURL *)url
//                                 inData:(NSMutableData *)pixelData;
//
//+ (nullable NSData *)RGBA8UBitmapFromURL:(NSURL *)url
//                                  inData:(NSMutableData *)pixelData;
//
//+ (nullable NSData *)RGBAfBitmapFromURL:(nonnull NSURL *)url
//                                 inData:(NSMutableData *)pixelData;
//
//+ (nullable NSData *)BGRA8UBitmapFromURL:(NSURL *)url
//                                  inData:(NSMutableData *)pixelData;
//
//+ (nullable NSData *)RGBA16UBitmapFromURL:(NSURL *)url
//                                   inData:(NSMutableData *)pixelData;
//
//+ (nullable NSData *)A2BGR10BitmapFromURL:(NSURL *)url
//                                   inData:(NSMutableData *)pixelData;
//
//+ (nullable NSData *)RGB10A2UBigEndianBitmapFromURL:(NSURL *)url
//                                             inData:(NSMutableData *)pixelData;
//
//+ (nullable NSData *)RGBAhBitmapFromURL:(nonnull NSURL *)url
//                                 inData:(NSMutableData *)pixelData;

+ (NSData *)EXRFromRGBAfBitmap:(NSData *)bitmap
                         width:(NSInteger)width
                        height:(NSInteger)height
                   exrBitDepth:(NSInteger)exrBitDepth;
NS_ASSUME_NONNULL_END
@end
