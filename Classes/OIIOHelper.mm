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

+ (nullable NSData*)bitmapDataFromURL:(NSURL *)url
                          pixelFormat:(OIIOImagePixelFormat)pixelFormat
                             outWidth:(NSInteger *)outWidth
                            outHeight:(NSInteger *)outHeight{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return nil;
    }
    
    const ImageSpec &spec = in->spec();
    
    NSInteger width = spec.width;
    NSInteger height = spec.height;
    
    *outWidth = width;
    *outHeight = height;
    
    in->close();
    delete(in);
    
    NSInteger dataSize = 0;
    
    switch (pixelFormat) {
        case OIIOImagePixelFormatRGB8U:
            dataSize = width * height * 3 * 1;
            break;
        case OIIOImagePixelFormatRGBA8U:
            dataSize = width * height * 4 * 1;
            break;
        case OIIOImagePixelFormatBGRA8U:
            dataSize = width * height * 4 * 1;
            break;
        case OIIOImagePixelFormatRGBA16U:
            dataSize = width * height * 4 * 2;
            break;
        case OIIOImagePixelFormatA2BGR10:
            dataSize = width * height * 4 * 1;
            break;
        case OIIOImagePixelFormatRGB10A2UBigEndian:
            dataSize = width * height * 4 * 1;
            break;
        case OIIOImagePixelFormatRGBAf:
            dataSize = width * height * 4 * 4;
            break;
        case OIIOImagePixelFormatRGBAh:
            dataSize = width * height * 4 * 2;
            break;
        default:
            return nil;
    }
    
    NSMutableData *mutableData = [NSMutableData dataWithLength:dataSize];
    
    bool success = [self loadBitmapIntoDataFromURL:url
                                       pixelFormat:pixelFormat
                                            inData:mutableData.mutableBytes
                                         rowStride:0];
    
    if(success){
        return mutableData;
    }
    else{
        return nil;
    }
}

+ (bool)loadBitmapIntoDataFromURL:(NSURL *)url
                      pixelFormat:(OIIOImagePixelFormat)pixelFormat
                           inData:(void *)pixelData
                        rowStride:(NSInteger)rowStride{
    switch (pixelFormat) {
        case OIIOImagePixelFormatRGB8U:
            return [self RGB8UBitmapFromURL:url inData:pixelData rowStride:rowStride];
        case OIIOImagePixelFormatRGBA8U:
            return [self RGBA8UBitmapFromURL:url inData:pixelData rowStride:rowStride];
        case OIIOImagePixelFormatBGRA8U:
            return [self BGRA8UBitmapFromURL:url inData:pixelData rowStride:rowStride];
        case OIIOImagePixelFormatRGBA16U:
            return [self RGBA16UBitmapFromURL:url inData:pixelData rowStride:rowStride];
        case OIIOImagePixelFormatA2BGR10:
            return [self A2BGR10BitmapFromURL:url inData:pixelData rowStride:rowStride];
        case OIIOImagePixelFormatRGB10A2UBigEndian:
            return [self RGB10A2UBigEndianBitmapFromURL:url inData:pixelData rowStride:rowStride];
        case OIIOImagePixelFormatRGBAf:
            return [self RGBAfBitmapFromURL:url inData:pixelData rowStride:rowStride];
        case OIIOImagePixelFormatRGBAh:
            return [self RGBAhBitmapFromURL:url inData:pixelData rowStride:rowStride];
        default:
            return false;
        
    }
}

+ (bool)RGB8UBitmapFromURL:(NSURL *)url
                    inData:(void *)pixelData
                        rowStride:(NSInteger)rowStride{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return false;
    }
    const ImageSpec &spec = in->spec();
    @autoreleasepool{
        if(spec.nchannels == 3){
            in->read_image(TypeDesc::UINT8, pixelData);
        }
        else{
            in->read_image(TypeDesc::UINT8, pixelData, 3);
        }
        
        in->close();
        delete(in);
        
        return true;
    }
    
}

+ (bool)RGBA16UBitmapFromURL:(NSURL *)url
                      inData:(void *)pixelData
                        rowStride:(NSInteger)rowStride{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return false;
    }
    const ImageSpec &spec = in->spec();
    @autoreleasepool{
        if(spec.nchannels == 3){
            in->read_image(TypeDesc::UINT16, pixelData, 2*4);
        }
        else{
            in->read_image(TypeDesc::UINT16, pixelData);
        }
        
        in->close();
        delete(in);
        
        return true;
    }
}

+ (bool)RGBA8UBitmapFromURL:(NSURL *)url
                     inData:(void *)pixelData
                        rowStride:(NSInteger)rowStride{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return false;
    }
    const ImageSpec &spec = in->spec();
    @autoreleasepool{
        if(spec.nchannels == 3){
            in->read_image(TypeDesc::UINT8, pixelData, 4);
        }
        else{
            in->read_image(TypeDesc::UINT8, pixelData);
        }
        
        in->close();
        delete(in);
        
        return true;
    }
}

+ (bool)BGRA8UBitmapFromURL:(NSURL *)url
                     inData:(void *)pixelData
                        rowStride:(NSInteger)rowStride{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return false;
    }
    const ImageSpec &spec = in->spec();
    @autoreleasepool{
        if(spec.nchannels == 3){
            in->read_image(TypeDesc::UINT8, pixelData, 4);
        }
        else{
            in->read_image(TypeDesc::UINT8, pixelData);
        }
        
        uint8_t *pixels = (uint8_t *)pixelData;
        uint8_t temp = 0;
        for(int i = 0; i < spec.width*spec.height; i++){
            temp = pixels[i*4];
            pixels[i*4] = pixels[i*4+2];
            pixels[i*4+2] = temp;
        }
        
        in->close();
        delete(in);
        
        return true;
    }
}

+ (bool)A2BGR10BitmapFromURL:(NSURL *)url
                      inData:(void *)pixelData
                   rowStride:(NSInteger)rowStride{
    InStream *inStream = new InStream();
    if (! inStream->Open([[url path] cStringUsingEncoding:NSUTF8StringEncoding])) {
        delete inStream;
        inStream = NULL;
        return false;
    }
    dpx::Reader dpxReader;
    dpxReader.SetInStream(inStream);
    if (! dpxReader.ReadHeader()) {
        inStream->Close();
        delete inStream;
        inStream = NULL;
        return false;
    }
    
    
    NSInteger bitdepth = dpxReader.header.BitDepth(0);
    NSInteger byteOffset = dpxReader.header.DataOffset(0);
    dpx::Packing packing = dpxReader.header.ImagePacking(0);
    bool requiresByteSwap = dpxReader.header.RequiresByteSwap();
    
    
    NSInteger width = dpxReader.header.Width();
    NSInteger height = dpxReader.header.Height();
    NSInteger pixelCount = width*height;
    
    NSInteger imageDataSize = (pixelCount * dpxReader.header.ImageElementComponentCount(0) * 4);
    
    if (dpxReader.header.ImageDescriptor(0) != dpx::kRGB || bitdepth != 10){
        inStream -> Close();
        delete inStream;
        inStream = NULL;
        return false;
    }
    
    inStream -> Seek(byteOffset, InStream::kStart);
    
    //will not work with data allocated with a row stride! bad!
    inStream -> Read(pixelData, imageDataSize);
    
    inStream -> Close();
    delete inStream;
    inStream = NULL;
    
    @autoreleasepool{
        uint32_t *pixels = (uint32_t *)pixelData;
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
            return false;
        }
        
        
        return true;
    }
    
}

+ (bool)RGB10A2UBigEndianBitmapFromURL:(NSURL *)url
                                inData:(void *)pixelData
                        rowStride:(NSInteger)rowStride{
    InStream *inStream = new InStream();
    if (! inStream->Open([[url path] cStringUsingEncoding:NSUTF8StringEncoding])) {
        delete inStream;
        inStream = NULL;
        return false;
    }
    dpx::Reader dpxReader;
    dpxReader.SetInStream(inStream);
    if (! dpxReader.ReadHeader()) {
        inStream->Close();
        delete inStream;
        inStream = NULL;
        return false;
    }
    
    
    NSInteger bitdepth = dpxReader.header.BitDepth(0);
    NSInteger byteOffset = dpxReader.header.DataOffset(0);
    dpx::Packing packing = dpxReader.header.ImagePacking(0);
    bool requiresByteSwap = dpxReader.header.RequiresByteSwap();
    
    NSInteger width = dpxReader.header.Width();
    NSInteger height = dpxReader.header.Height();
    NSInteger pixelCount = width*height;
    
    if (dpxReader.header.ImageDescriptor(0) != dpx::kRGB || bitdepth != 10){
        inStream -> Close();
        delete inStream;
        inStream = NULL;
        return false;
    }
    
    dpxReader.ReadImage(0, pixelData);
    
    inStream -> Close();
    delete inStream;
    inStream = NULL;
    @autoreleasepool{
        uint32_t *pixels = (uint32_t *)pixelData;
        
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
        
        return true;
    }
    
}

+ (bool)RGBAhBitmapFromURL:(NSURL *)url
                    inData:(void *)pixelData
                        rowStride:(NSInteger)rowStride{
    ImageSpec *configSpec = new ImageSpec();
    configSpec->attribute("raw:ColorSpace", "raw");
    configSpec->attribute("raw:Demosaic", "AMaZE");
    
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding], configSpec);
    
    if (!in) {
        return false;
    }
    const ImageSpec &spec = in->spec();
    

    if(spec.nchannels == 4){
        in->read_image (TypeDesc::HALF, pixelData);
    }
    else{
        in->read_image (TypeDesc::HALF, pixelData, 4*2);
    }
    
    in->close ();
    delete(in);
    
    return true;
}

+ (bool)RGBAfBitmapFromURL:(NSURL *)url
                    inData:(void *)pixelData
                        rowStride:(NSInteger)rowStride{
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return false;
    }
    
    const ImageSpec &spec = in->spec();
    
    @autoreleasepool{
        if(spec.nchannels == 4){
            in->read_image (TypeDesc::FLOAT, pixelData);
        }
        else{
            in->read_image (TypeDesc::FLOAT, pixelData, 4*4);
        }

        in->close ();
        delete(in);
        
        return true;
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
