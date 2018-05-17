//
//  OIIOHelper.m
//  Pods
//
//  Created by Greg Cotten on 9/20/16.
//
//

#import "OIIOHelper.h"
#include "imageio.h"
#include "DPX.h"

OIIO_NAMESPACE_USING

static inline uint32_t rotl32 (uint32_t n, unsigned int c)
{
    const unsigned int mask = (CHAR_BIT*sizeof(n) - 1);  // assumes width is a power of 2.
    
    // assert ( (c<=mask) &&"rotate by type width or more");
    c &= mask;
    return (n<<c) | (n>>( (-c)&mask ));
}

static inline uint32_t rotr32 (uint32_t n, unsigned int c)
{
    const unsigned int mask = (CHAR_BIT*sizeof(n) - 1);
    
    // assert ( (c<=mask) &&"rotate by type width or more");
    c &= mask;
    return (n>>c) | (n<<( (-c)&mask ));
}

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
            outFramerate:(double *)outFramerate
             outTimecode:(NSInteger *)outTimecode
             outMetadata:(NSDictionary **)metadata {
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return NO;
    }
    
    const ImageSpec &spec = in->spec();
    const ParamValue *tc = spec.find_attribute("smpte:TimeCode", TypeDesc::TypeTimeCode);
    
    if(tc) {
        int *timecodeSplit = (int *)tc->data();
        NSInteger timecode = 0;
        if(timecodeSplit[0] != -1){
            timecode += timecodeSplit[0];
        }
        if(timecodeSplit[1] != -1){
            timecode += timecodeSplit[1];
        }
        *outTimecode = timecode;
    }
    else{
        *outTimecode = -1;
    }
    
    *outWidth = spec.width;
    *outHeight = spec.height;
    *outChannels = spec.nchannels;
    *outPixelFormat = [self encodingTypeFromSpec:&spec];
    
    const ParamValue *fr = spec.find_attribute("dpx:FrameRate");
    
    if(fr) {
        float framerate = (*(const float *)tc->data());
        if(floor(framerate) != 0.0 && framerate != INFINITY){
            *outFramerate = (double)framerate;
        }
        else{
            *outFramerate = INFINITY;
        }
    }
    else{
        *outFramerate = INFINITY;
    }
    
    if (metadata) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        attributes[@"oiiococoa:ImageEncodingType"] = @([self encodingTypeFromSpec:&spec]);
        for (size_t i = 0;  i < spec.extra_attribs.size();  ++i) {
            
            const ParamValue &p (spec.extra_attribs[i]);
            NSString *name = [NSString stringWithCString:p.name().c_str() encoding:NSUTF8StringEncoding];
            id value = [NSNull null];
            
            if (p.type() == TypeString){
                value = @(*(const char **)p.data());
            }
            else if (p.type() == TypeFloat) {
                value = @(*(const float *)p.data());
            }
            else if (p.type() == TypeInt) {
                value = @(*(const int *)p.data());
            }
            else if (p.type() == TypeUInt){
                value = @(*(const unsigned int *)p.data());
            }
            else if (p.type() == TypeTimeCode){
                int *timecodeSplit = (int *)p.data();
                NSInteger timecode = 0;
                if(timecodeSplit[0] != -1){
                    timecode += timecodeSplit[0];
                }
                if(timecodeSplit[1] != -1){
                    timecode += timecodeSplit[1];
                }
                value = @(timecode);
            }
            else{
                value = [NSString stringWithCString:tostring(p.type(), p.data()).c_str() encoding:NSUTF8StringEncoding];
            }
            
            attributes[name] = value;
            
        }
        
        *metadata = [NSDictionary dictionaryWithDictionary: attributes];
    }
    
    in->close();
    
    delete(in);
    
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
    @autoreleasepool{
        NSMutableData *pixelData = [NSMutableData dataWithLength:spec.width*spec.height*3];
        
        if(spec.nchannels == 3){
            in->read_image(TypeDesc::UINT8, pixelData.mutableBytes);
        }
        else{
            in->read_image(TypeDesc::UINT8, pixelData.mutableBytes, 3);
        }
        
        *outWidth = spec.width;
        *outHeight = spec.height;
        
        in->close();
        delete(in);
        
        return pixelData;
    }
    
}

+ (nullable NSData *)RGBA16UBitmapFromURL:(NSURL *)url
                             outPixelWidth:(NSInteger *)outWidth
                            outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    @autoreleasepool{
        NSMutableData *pixelData = [NSMutableData dataWithLength:spec.width*spec.height*2*4];

        if(spec.nchannels == 3){
            in->read_image(TypeDesc::UINT16, pixelData.mutableBytes, 2*4);
        }
        else{
            in->read_image(TypeDesc::UINT16, pixelData.mutableBytes);
        }
        
        *outWidth = spec.width;
        *outHeight = spec.height;
        
        in->close();
        delete(in);
        
        return pixelData;
    }
}

+ (nullable NSData *)RGBA8UBitmapFromURL:(NSURL *)url
                           outPixelWidth:(NSInteger *)outWidth
                          outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    @autoreleasepool{
        NSMutableData *pixelData = [NSMutableData dataWithLength:spec.width*spec.height*4];
        
        if(spec.nchannels == 3){
            in->read_image(TypeDesc::UINT8, pixelData.mutableBytes, 4);
        }
        else{
            in->read_image(TypeDesc::UINT8, pixelData.mutableBytes);
        }
        
        *outWidth = spec.width;
        *outHeight = spec.height;
        
        in->close();
        delete(in);
        
        return pixelData;
    }
}

+ (nullable NSData *)BGRA8UBitmapFromURL:(NSURL *)url
                          outPixelWidth:(NSInteger *)outWidth
                         outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    @autoreleasepool{
        NSMutableData *pixelData = [NSMutableData dataWithLength:spec.width*spec.height*4];
        
        if(spec.nchannels == 3){
            in->read_image(TypeDesc::UINT8, pixelData.mutableBytes, 4);
        }
        else{
            in->read_image(TypeDesc::UINT8, pixelData.mutableBytes);
        }
        
        uint8_t *pixels = (uint8_t *)pixelData.mutableBytes;
        uint8_t temp = 0;
        for(int i = 0; i < spec.width*spec.height; i++){
            temp = pixels[i*4];
            pixels[i*4] = pixels[i*4+2];
            pixels[i*4+2] = temp;
        }
        
        *outWidth = spec.width;
        *outHeight = spec.height;
        
        in->close();
        delete(in);
        
        return pixelData;
    }
}

+ (nullable NSData *)A2BGR10BitmapFromURL:(NSURL *)url
                            outPixelWidth:(NSInteger *)outWidth
                           outPixelHeight:(NSInteger *)outHeight{
    InStream *inStream = new InStream();
    if (! inStream->Open([[url path] cStringUsingEncoding:NSUTF8StringEncoding])) {
        delete inStream;
        inStream = NULL;
        return nil;
    }
    dpx::Reader dpxReader;
    dpxReader.SetInStream(inStream);
    if (! dpxReader.ReadHeader()) {
        inStream->Close();
        delete inStream;
        inStream = NULL;
        return nil;
    }
    
    
    NSInteger bitdepth = dpxReader.header.BitDepth(0);
    NSInteger byteOffset = dpxReader.header.DataOffset(0);
    dpx::Packing packing = dpxReader.header.ImagePacking(0);
    bool requiresByteSwap = dpxReader.header.RequiresByteSwap();
    
    NSInteger width = dpxReader.header.Width();
    NSInteger height = dpxReader.header.Height();
    NSInteger pixelCount = width*height;
    
    *outWidth = width;
    *outHeight = height;
    
    if (dpxReader.header.ImageDescriptor(0) != dpx::kRGB || bitdepth != 10){
        inStream -> Close();
        delete inStream;
        inStream = NULL;
        return nil;
    }
    
    inStream -> Close();
    delete inStream;
    inStream = NULL;
    @autoreleasepool{
        NSData *dpxData = [NSData dataWithContentsOfURL:url];
        
        NSMutableData *pixelData = [NSMutableData dataWithData:[dpxData subdataWithRange:NSMakeRange(byteOffset, pixelCount*4)]];
        
        uint32_t *pixels = (uint32_t *)pixelData.mutableBytes;
        uint32_t pixel = 0;
        uint32_t redOnly = 0;
        uint32_t greenOnly = 0;
        uint32_t blueOnly = 0;
        
        uint32_t redChannelMask = 0b00111111111100000000000000000000;
        uint32_t greenChannelMask = 0b00000000000011111111110000000000;
        uint32_t blueChannelMask = 0b00000000000000000000001111111111;
        
        if(packing == dpx::kFilledMethodA){
            if(requiresByteSwap){
                for(NSInteger i = 0; i < pixelCount; i++){
                    pixel = rotr32(CFSwapInt32(pixels[i]), 2);
                    redOnly = pixel & redChannelMask;
                    greenOnly = pixel & greenChannelMask;
                    blueOnly = pixel & blueChannelMask;
                    pixels[i] = (redOnly >> 20) | (blueOnly << 20) | greenOnly;
                }
            }
            else{
                for(NSInteger i = 0; i < pixelCount; i++){
                    pixel = rotr32(pixels[i], 2);
                    redOnly = pixel & redChannelMask;
                    greenOnly = pixel & greenChannelMask;
                    blueOnly = pixel & blueChannelMask;
                    pixels[i] = (redOnly >> 20) | (blueOnly << 20) | greenOnly;
                }
            }
        }
        else if(packing == dpx::kFilledMethodB){
            if(requiresByteSwap){
                for(NSInteger i = 0; i < pixelCount; i++){
                    pixel = CFSwapInt32(pixels[i]);
                    redOnly = pixel & redChannelMask;
                    greenOnly = pixel & greenChannelMask;
                    blueOnly = pixel & blueChannelMask;
                    pixels[i] = (redOnly >> 20) | (blueOnly << 20) | greenOnly;
                }
            }
            else{
                for(NSInteger i = 0; i < pixelCount; i++){
                    pixel = pixels[i];
                    redOnly = pixel & redChannelMask;
                    greenOnly = pixel & greenChannelMask;
                    blueOnly = pixel & blueChannelMask;
                    pixels[i] = (redOnly >> 20) | (blueOnly << 20) | greenOnly;
                }
            }
        }
        else{
            return nil;
        }
        
        
        return pixelData;
    }
    
}

+ (nullable NSData *)RGB10A2UBigEndianBitmapFromURL:(NSURL *)url
                                      outPixelWidth:(NSInteger *)outWidth
                                     outPixelHeight:(NSInteger *)outHeight{
    InStream *inStream = new InStream();
    if (! inStream->Open([[url path] cStringUsingEncoding:NSUTF8StringEncoding])) {
        delete inStream;
        inStream = NULL;
        return nil;
    }
    dpx::Reader dpxReader;
    dpxReader.SetInStream(inStream);
    if (! dpxReader.ReadHeader()) {
        inStream->Close();
        delete inStream;
        inStream = NULL;
        return nil;
    }
    
    
    NSInteger bitdepth = dpxReader.header.BitDepth(0);
    NSInteger byteOffset = dpxReader.header.DataOffset(0);
    dpx::Packing packing = dpxReader.header.ImagePacking(0);
    bool requiresByteSwap = dpxReader.header.RequiresByteSwap();
    
    NSInteger width = dpxReader.header.Width();
    NSInteger height = dpxReader.header.Height();
    NSInteger pixelCount = width*height;
    
    *outWidth = width;
    *outHeight = height;
    
    if (dpxReader.header.ImageDescriptor(0) != dpx::kRGB || bitdepth != 10){
        inStream -> Close();
        delete inStream;
        inStream = NULL;
        return nil;
    }
    
    inStream -> Close();
    delete inStream;
    inStream = NULL;
    @autoreleasepool{
        NSData *dpxData = [NSData dataWithContentsOfURL:url];
        
        NSMutableData *pixelData = [NSMutableData dataWithData:[dpxData subdataWithRange:NSMakeRange(byteOffset, pixelCount*4)]];
        
        uint32_t *pixels = (uint32_t *)pixelData.mutableBytes;
        
        if(packing == dpx::kFilledMethodA){
            if(!requiresByteSwap){
                for(NSInteger i = 0; i < pixelCount; i++){
                    pixels[i] = CFSwapInt32(pixels[i]);
                }
            }
        }
        else if(packing == dpx::kFilledMethodB){
            if(!requiresByteSwap){
                for(NSInteger i = 0; i < pixelCount; i++){
                    pixels[i] = CFSwapInt32(rotr32(pixels[i], 2));
                }
            }
            else{
                for(NSInteger i = 0; i < pixelCount; i++){
                    pixels[i] = CFSwapInt32(rotr32(CFSwapInt32(pixels[i]), 2));
                }
            }
        }
        
        return pixelData;
    }
    
}

+ (nullable NSData *)RGBAhBitmapFromURL:(NSURL *)url
                 outPixelWidth:(NSInteger *)outWidth
                outPixelHeight:(NSInteger *)outHeight{
    
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();
    @autoreleasepool{
        NSMutableData *pixelData = [NSMutableData dataWithLength:4*2*spec.width*spec.height];
        
        if(spec.nchannels == 4){
            in->read_image (TypeDesc::HALF, pixelData.mutableBytes);
        }
        else{
            in->read_image (TypeDesc::HALF, pixelData.mutableBytes, 4*2);
        }
        *outWidth = spec.width;
        *outHeight = spec.height;
        
        in->close ();
        delete(in);
        
        return pixelData;
    }
    
    
}

+ (nullable NSData *)RGBAfBitmapFromURL:(NSURL *)url
                 outPixelWidth:(NSInteger *)outWidth
                outPixelHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return nil;
    }
    
    const ImageSpec &spec = in->spec();
    
    @autoreleasepool{
        NSMutableData *pixelData = [NSMutableData dataWithLength:4*4*spec.width*spec.height];
        
        if(spec.nchannels == 4){
            in->read_image (TypeDesc::FLOAT, pixelData.mutableBytes);
        }
        else{
            in->read_image (TypeDesc::FLOAT, pixelData.mutableBytes, 4*4);
        }
        *outWidth = spec.width;
        *outHeight = spec.height;
        
        in->close ();
        delete(in);
        
        return pixelData;
    }
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
