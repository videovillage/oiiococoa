//
//  OIIOHelper.m
//  Pods
//
//  Created by Greg Cotten on 9/20/16.
//
//

#import "OIIOHelper.h"
#include "imageio.h"

OIIO_NAMESPACE_USING

@implementation OIIOHelper

+ (NSURL *)uniqueTempFileURLWithFileExtension:(NSString *)fileExtension{
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], [NSString stringWithFormat:@"file.%@", fileExtension]];
    NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
    return fileURL;
    //remove with [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
}

+ (nullable NSData *)BGRA8UBitmapFromURL:(NSURL *)url
                          outPixelWidth:(NSInteger *)outWidth
                         outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    
    NSMutableData *pixelData = [NSMutableData dataWithLength:4*spec.width*spec.height];
    
    in->read_image (TypeDesc::UINT8, pixelData.mutableBytes);
    in->close ();
    
    uint8_t *bitmap = (uint8_t*)pixelData.mutableBytes;
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    
    uint8_t redTemp = 0;
    for(int i = 0; i < spec.width * spec.height; i++){
        //swap channels
        redTemp = bitmap[i*4];
        bitmap[i*4] = bitmap[i*4 + 2];
        bitmap[i*4 + 2] = redTemp;
    }
    
    return pixelData;
}

+ (nullable NSData *)RGBAhBitmapFromURL:(NSURL *)url
                 outPixelWidth:(NSInteger *)outWidth
                outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    
    NSMutableData *pixelData = [NSMutableData dataWithLength:4*spec.width*spec.height*2];
    
    in->read_image (TypeDesc::HALF, pixelData.mutableBytes);
    in->close ();
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    
    return pixelData;
}

+ (nullable NSData *)RGBAfBitmapFromURL:(NSURL *)url
                 outPixelWidth:(NSInteger *)outWidth
                outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    NSMutableData *pixelData = [NSMutableData dataWithLength:4*spec.width*spec.height*sizeof(float)];
    
    in->read_image (TypeDesc::FLOAT, pixelData.mutableBytes);
    in->close ();
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    
    return pixelData;
}

+ (NSData *)EXRFromRGBAfBitmap:(NSData *)bitmap
                         width:(NSInteger)width
                        height:(NSInteger)height
                   exrBitDepth:(NSInteger)exrBitDepth{
//    ImageOutput *output = ImageOutput::create ([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    NSURL *tempURL = [self.class uniqueTempFileURLWithFileExtension:@"exr"];
    
    ImageOutput *output = ImageOutput::create ([[tempURL path] cStringUsingEncoding:NSUTF8StringEncoding]);
//    
    //ImageSpec selfspec = ImageSpec(width, height, 4, TypeDesc::FLOAT);
    
    ImageSpec outspec = ImageSpec((int)width, (int)height, 4, TypeDesc::FLOAT);
    
    
    
    //outspec.set_format(TypeDesc::HALF);
    
    //outspec.attribute("oiio:Endian","little");
    outspec.attribute("compression", "none");
    outspec.attribute("openexr:lineOrder", "increasingY");
    
    //    stride_t stride = self.samplesPerPixel == 4 ? (self.bitsPerSample/8) : AutoStride;
    //    NSLog(@"%i %i", selfspec.nchannels, (int)selfspec.format.size());
    
    //NSLog(@"%@", [NSString stringWithCString:output->format_name() encoding:NSUTF8StringEncoding]);
    
    output->open([[tempURL path] cStringUsingEncoding:NSUTF8StringEncoding], outspec, ImageOutput::Create);
    output->write_image(TypeDesc::FLOAT, bitmap.bytes);
    
    if([[NSString stringWithCString:output->geterror().c_str() encoding:NSUTF8StringEncoding] length] > 0){
        NSLog(@"%@", [NSString stringWithCString:output->geterror().c_str() encoding:NSUTF8StringEncoding]);
        output->close();
        delete output;
        [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
        return nil;
    }
    
    output->close();
    delete output;
    
    NSData *data = [NSData dataWithContentsOfURL:tempURL];
    
    [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
    
    return data;

}

@end
