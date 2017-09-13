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

+ (BOOL)imageSpecFromURL:(NSURL *)url
                outWidth:(NSInteger *)outWidth
               outHeight:(NSInteger *)outHeight
             outChannels:(NSInteger *)outChannels
          outPixelFormat:(OIIOImageEncodingType *)outPixelFormat
            outFramerate:(double *)outFramerate{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return NO;
    }
    
    const ImageSpec &spec = in->spec();
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    *outChannels = spec.nchannels;
    *outPixelFormat = [self encodingTypeFromSpec:&spec];
    *outFramerate = 23.976;
    
    in->close();
    return YES;
}

+ (nullable NSData *)RGB8UBitmapFromURL:(NSURL *)url
                          outPixelWidth:(NSInteger *)outWidth
                         outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    
    NSMutableData *pixelData = [NSMutableData dataWithLength:spec.width*spec.height*spec.nchannels];
    
    in->read_image(TypeDesc::UINT8, pixelData.mutableBytes);
    in->close();
    
    NSData *processedPixelData = pixelData;
    
    if(spec.nchannels == 4){
        NSMutableData *newPixelData = [NSMutableData dataWithLength:spec.width*spec.height*3];
        uint8_t *bitmap = (uint8_t*)pixelData.mutableBytes;
        uint8_t *processedBitmap = (uint8_t*)newPixelData.mutableBytes;
        for(int i = 0; i < spec.width * spec.height; i++){
            processedBitmap[i*3] = bitmap[i*4];
            processedBitmap[i*3+1] = bitmap[i*4+1];
            processedBitmap[i*3+2] = bitmap[i*4+2];
        }
        processedPixelData = newPixelData;
    }
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    
    return processedPixelData;
}

+ (nullable NSData *)RGBA8UBitmapFromURL:(NSURL *)url
                           outPixelWidth:(NSInteger *)outWidth
                          outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    
    NSMutableData *pixelData = [NSMutableData dataWithLength:spec.width*spec.height*spec.nchannels];
    
    in->read_image(TypeDesc::UINT8, pixelData.mutableBytes);
    in->close();
    
    NSData *processedPixelData = pixelData;
    
    if(spec.nchannels == 3){
        NSMutableData *newPixelData = [NSMutableData dataWithLength:spec.width*spec.height*4];
        uint8_t *bitmap = (uint8_t*)pixelData.mutableBytes;
        uint8_t *processedBitmap = (uint8_t*)newPixelData.mutableBytes;
        for(int i = 0; i < spec.width * spec.height; i++){
            processedBitmap[i*4] = bitmap[i*3];
            processedBitmap[i*4+1] = bitmap[i*3+1];
            processedBitmap[i*4+2] = bitmap[i*3+2];
            processedBitmap[i*4+3] = 0;
        }
        processedPixelData = newPixelData;
    }
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    
    return processedPixelData;
}

+ (nullable NSData *)BGRA8UBitmapFromURL:(NSURL *)url
                          outPixelWidth:(NSInteger *)outWidth
                         outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    
    NSMutableData *pixelData = [NSMutableData dataWithLength:spec.width*spec.height*spec.nchannels];
    
    in->read_image(TypeDesc::UINT8, pixelData.mutableBytes);
    in->close();
    
    NSData *processedPixelData;
    
    if(spec.nchannels == 4){
        uint8_t *bitmap = (uint8_t*)pixelData.mutableBytes;
        uint8_t redTemp = 0;
        for(int i = 0; i < spec.width * spec.height; i++){
            //swap channels
            redTemp = bitmap[i*4];
            bitmap[i*4] = bitmap[i*4 + 2];
            bitmap[i*4 + 2] = redTemp;
        }
        processedPixelData = pixelData;
    }
    else{
        NSMutableData *newPixelData = [NSMutableData dataWithLength:spec.width*spec.height*4];
        uint8_t *bitmap = (uint8_t*)pixelData.mutableBytes;
        uint8_t *processedBitmap = (uint8_t*)newPixelData.mutableBytes;
        for(int i = 0; i < spec.width * spec.height; i++){
            processedBitmap[i*4] = bitmap[i*3+2];
            processedBitmap[i*4+1] = bitmap[i*3+1];
            processedBitmap[i*4+2] = bitmap[i*3];
            processedBitmap[i*4+3] = 0;
        }
        processedPixelData = newPixelData;
    }
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    
    return processedPixelData;
}

+ (nullable NSData *)RGBAhBitmapFromURL:(NSURL *)url
                 outPixelWidth:(NSInteger *)outWidth
                outPixelHeight:(NSInteger *)outHeight{
    
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    
    NSMutableData *pixelData = [NSMutableData dataWithLength:spec.nchannels*spec.width*spec.height*2];
    
    in->read_image (TypeDesc::HALF, pixelData.mutableBytes);
    in->close ();
    
    NSData *processedPixelData;
    
    if(spec.nchannels == 4){
        processedPixelData = pixelData;
    }
    else{
        NSMutableData *newPixelData = [NSMutableData dataWithLength:spec.width*spec.height*4*2];
        __fp16 *bitmap = (__fp16*)pixelData.mutableBytes;
        __fp16 *processedBitmap = (__fp16*)newPixelData.mutableBytes;
        for(int i = 0; i < spec.width * spec.height; i++){
            processedBitmap[i*4] = bitmap[i*3];
            processedBitmap[i*4+1] = bitmap[i*3+1];
            processedBitmap[i*4+2] = bitmap[i*3+2];
            processedBitmap[i*4+3] = 0;
        }
        processedPixelData = newPixelData;
    }
    
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    
    return processedPixelData;
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
    
    NSData *processedPixelData;
    
    if(spec.nchannels == 4){
        processedPixelData = pixelData;
    }
    else{
        NSMutableData *newPixelData = [NSMutableData dataWithLength:spec.width*spec.height*4*4];
        float *bitmap = (float*)pixelData.mutableBytes;
        float *processedBitmap = (float*)newPixelData.mutableBytes;
        for(int i = 0; i < spec.width * spec.height; i++){
            processedBitmap[i*4] = bitmap[i*3];
            processedBitmap[i*4+1] = bitmap[i*3+1];
            processedBitmap[i*4+2] = bitmap[i*3+2];
            processedBitmap[i*4+3] = 0;
        }
        processedPixelData = newPixelData;
    }
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    
    return processedPixelData;
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

+ (OIIOImageEncodingType)encodingTypeFromSpec:(const ImageSpec *)spec{
    if(spec->format == TypeDesc::UINT8){
        return OIIOImageEncodingTypeUINT8;
    }
    else if(spec->format == TypeDesc::INT8){
        return OIIOImageEncodingTypeINT8;
    }
    else if(spec->format == TypeDesc::UINT16){
        if(spec->get_int_attribute("oiio:BitsPerSample") == 10){
            return OIIOImageEncodingTypeUINT10;
        }
        else if(spec->get_int_attribute("oiio:BitsPerSample") == 12){
            return OIIOImageEncodingTypeUINT12;
        }
        else{
            return OIIOImageEncodingTypeUINT16;
        }
    }
    else if(spec->format == TypeDesc::INT16){
        return OIIOImageEncodingTypeINT16;
    }
    else if(spec->format == TypeDesc::UINT32){
        return OIIOImageEncodingTypeUINT32;
    }
    else if(spec->format == TypeDesc::INT32){
        return OIIOImageEncodingTypeINT32;
    }
    else if(spec->format == TypeDesc::HALF){
        return OIIOImageEncodingTypeHALF;
    }
    else if(spec->format == TypeDesc::FLOAT){
        return OIIOImageEncodingTypeFLOAT;
    }
    else if(spec->format == TypeDesc::DOUBLE){
        return OIIOImageEncodingTypeDOUBLE;
    }
    return OIIOImageEncodingTypeNONE;
    
}

@end
