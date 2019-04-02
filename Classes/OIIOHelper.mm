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
#import <Accelerate/Accelerate.h>

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

+ (BOOL)canRead:(NSURL *)url {
    auto in = ImageInput::open([url.path cStringUsingEncoding:NSUTF8StringEncoding]);
    if(in) {
        return YES;
    }
    else{
        return NO;
    }
}

+ (BOOL)imageSpecFromURL:(NSURL *)url
                outWidth:(NSInteger *)outWidth
               outHeight:(NSInteger *)outHeight
             outChannels:(NSInteger *)outChannels
          outPixelFormat:(OIIOImageEncodingType *)outPixelFormat
            outFramerate:(double *)outFramerate
             outTimecode:(NSInteger *)outTimecode
             outMetadata:(NSDictionary **)metadata {
    auto in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
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
    if(!fr){
        fr = spec.find_attribute("FramesPerSecond");
    }
    
    if(fr) {
        float framerate = fr->get_float();
        if(floor(framerate) != 0.0 && framerate != INFINITY && framerate != NAN){
            *outFramerate = (double)framerate;
        }
        else{
            *outFramerate = NAN;
        }
    }
    else{
        *outFramerate = NAN;
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
    
    return YES;
}

+ (nullable NSData*)bitmapDataFromURL:(NSURL *)url
                          pixelFormat:(OIIOImagePixelFormat)pixelFormat
                             outWidth:(NSInteger *)outWidth
                            outHeight:(NSInteger *)outHeight{
    auto in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return nil;
    }
    
    const ImageSpec &spec = in->spec();
    
    NSInteger width = spec.width;
    NSInteger height = spec.height;
    
    *outWidth = width;
    *outHeight = height;
    
    NSInteger dataSize = 0;
    NSInteger bytesPerRow = 0;
    
    switch (pixelFormat) {
        case OIIOImagePixelFormatRGB8U:
            dataSize = width * height * 3 * 1;
            bytesPerRow = width * 3 * 1;
            break;
        case OIIOImagePixelFormatRGBA8U:
            dataSize = width * height * 4 * 1;
            bytesPerRow = width * 4 * 1;
            break;
        case OIIOImagePixelFormatBGRA8U:
            dataSize = width * height * 4 * 1;
            bytesPerRow = width * 4 * 1;
            break;
        case OIIOImagePixelFormatRGBA16U:
            dataSize = width * height * 4 * 2;
            bytesPerRow = width * 4 * 2;
            break;
        case OIIOImagePixelFormatRGB10A2U:
            dataSize = width * height * 4;
            bytesPerRow = width * 4;
            break;
        case OIIOImagePixelFormatRGB10A2UBigEndian:
            dataSize = width * height * 4;
            bytesPerRow = width * 4;
            break;
        case OIIOImagePixelFormatRGBAf:
            dataSize = width * height * 4 * 4;
            bytesPerRow = width * 4 * 4;
            break;
        case OIIOImagePixelFormatRGBAh:
            dataSize = width * height * 4 * 2;
            bytesPerRow = width * 4 * 2;
            break;
        default:
            return nil;
    }
    
    NSMutableData *mutableData = [NSMutableData dataWithLength:dataSize];
    
    bool success = [self loadBitmapIntoDataFromURL:url
                                       pixelFormat:pixelFormat
                                            inData:mutableData.mutableBytes
                                       bytesPerRow:bytesPerRow];
    
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
                        bytesPerRow:(NSInteger)bytesPerRow{
    switch (pixelFormat) {
        case OIIOImagePixelFormatRGB8U:
            return [self RGB8UBitmapFromURL:url inData:pixelData bytesPerRow:bytesPerRow];
        case OIIOImagePixelFormatRGBA8U:
            return [self RGBA8UBitmapFromURL:url inData:pixelData bytesPerRow:bytesPerRow];
        case OIIOImagePixelFormatBGRA8U:
            return [self BGRA8UBitmapFromURL:url inData:pixelData bytesPerRow:bytesPerRow];
        case OIIOImagePixelFormatRGBA16U:
            return [self RGBA16UBitmapFromURL:url inData:pixelData bytesPerRow:bytesPerRow];
        case OIIOImagePixelFormatRGB10A2U:
            return [self RGB10A2UBitmapFromURL:url inData:pixelData bytesPerRow:bytesPerRow];
        case OIIOImagePixelFormatRGB10A2UBigEndian:
            return [self RGB10A2UBigEndianBitmapFromURL:url inData:pixelData bytesPerRow:bytesPerRow];
        case OIIOImagePixelFormatRGBAf:
            return [self RGBAfBitmapFromURL:url inData:pixelData bytesPerRow:bytesPerRow];
        case OIIOImagePixelFormatRGBAh:
            return [self RGBAhBitmapFromURL:url inData:pixelData bytesPerRow:bytesPerRow];
        default:
            return false;
        
    }
}

+ (bool)RGB8UBitmapFromURL:(NSURL *)url
                    inData:(void *)pixelData
                        bytesPerRow:(NSInteger)bytesPerRow{
    auto in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return false;
    }
    const ImageSpec &spec = in->spec();
    
    in->read_image(TypeDesc::UINT8, pixelData, 3, bytesPerRow);
    
    return true;
}

+ (bool)RGBA16UBitmapFromURL:(NSURL *)url
                      inData:(void *)pixelData
                        bytesPerRow:(NSInteger)bytesPerRow{
    auto in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return false;
    }
    const ImageSpec &spec = in->spec();
    in->read_image(TypeDesc::UINT16, pixelData, 8, bytesPerRow);
    
    if(spec.nchannels == 3){
        vImage_Buffer src;
        src.height = spec.height;
        src.width = spec.width;
        src.rowBytes = bytesPerRow;
        src.data = pixelData;
        
        const uint16_t fill[4] = {0, 0, 0, 65535};
        
        vImageOverwriteChannelsWithPixel_ARGB16U(fill, &src, &src, 0x1, kvImageNoFlags);
    }
    
    return true;
}

+ (bool)RGBA8UBitmapFromURL:(NSURL *)url
                     inData:(void *)pixelData
                        bytesPerRow:(NSInteger)bytesPerRow{
    auto in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return false;
    }
    const ImageSpec &spec = in->spec();
    
    in->read_image(TypeDesc::UINT8, pixelData, 4, bytesPerRow);
    
    if(spec.nchannels == 3){
        vImage_Buffer src;
        src.height = spec.height;
        src.width = spec.width;
        src.rowBytes = bytesPerRow;
        src.data = pixelData;
        
        vImageOverwriteChannelsWithScalar_ARGB8888(255, &src, &src, 0x1, kvImageNoFlags);
    }
    
    return true;
}

+ (bool)BGRA8UBitmapFromURL:(NSURL *)url
                     inData:(void *)pixelData
                        bytesPerRow:(NSInteger)bytesPerRow{
    auto in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (!in) {
        return false;
    }
    
    const ImageSpec &spec = in->spec();
    
    in->read_image(TypeDesc::UINT8, pixelData, 4, bytesPerRow);
    
    vImage_Buffer src;
    src.height = spec.height;
    src.width = spec.width;
    src.rowBytes = bytesPerRow;
    src.data = pixelData;
    
    if(spec.nchannels == 3){
        vImageOverwriteChannelsWithScalar_ARGB8888(255, &src, &src, 0x1, kvImageNoFlags);
    }
    
    const uint8_t permuteMap[4] = {2, 1, 0, 3};
    
    vImagePermuteChannels_ARGB8888(&src, &src, permuteMap, kvImageNoFlags);
    
    return true;
}

+ (bool)RGB10A2UBitmapFromURL:(NSURL *)url
                      inData:(void *)pixelData
                   bytesPerRow:(NSInteger)bytesPerRow{
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
    
    if(bytesPerRow == 4 * width){
        inStream -> Read(pixelData, imageDataSize);
    }
    else{
        uint8_t* pixelBytes = (uint8_t *)pixelData;
        NSInteger bytesPerScanline = 4*width;
        for(int y = 0; y < height; y++){
            inStream -> Read((void *)(&pixelBytes[y * bytesPerRow]), bytesPerScanline);
        }
    }
    
    inStream -> Close();
    delete inStream;
    inStream = NULL;
    
    uint32_t *pixels = (uint32_t *)pixelData;
    uint32_t pixel = 0;
    uint32_t redOnly = 0;
    uint32_t greenOnly = 0;
    uint32_t blueOnly = 0;
    
    uint32_t redChannelMask = 0b00111111111100000000000000000000;
    uint32_t greenChannelMask = 0b00000000000011111111110000000000;
    uint32_t blueChannelMask = 0b00000000000000000000001111111111;
    
    uint32_t pixelOffset = 0;
    
    if(packing == dpx::kFilledMethodA){
        if(requiresByteSwap){
            for(NSInteger y = 0; y < height * bytesPerRow; y += bytesPerRow) {
                pixelOffset = y / 4;
                for(NSInteger x = 0; x < width; x++){
                    pixel = rotr32(CFSwapInt32(pixels[x + pixelOffset]), 2);
                    redOnly = pixel & redChannelMask;
                    greenOnly = pixel & greenChannelMask;
                    blueOnly = pixel & blueChannelMask;
                    pixels[x + pixelOffset] = (redOnly >> 20) | (blueOnly << 20) | greenOnly;
                }
            }
        }
        else{
            for(NSInteger y = 0; y < height * bytesPerRow; y += bytesPerRow) {
                pixelOffset = y / 4;
                for(NSInteger x = 0; x < width; x++){
                    pixel = rotr32(pixels[x + pixelOffset], 2);
                    redOnly = pixel & redChannelMask;
                    greenOnly = pixel & greenChannelMask;
                    blueOnly = pixel & blueChannelMask;
                    pixels[x + pixelOffset] = (redOnly >> 20) | (blueOnly << 20) | greenOnly;
                }
            }
        }
    }
    else if(packing == dpx::kFilledMethodB){
        if(requiresByteSwap){
            for(NSInteger y = 0; y < height * bytesPerRow; y += bytesPerRow) {
                pixelOffset = y / 4;
                for(NSInteger x = 0; x < width; x++){
                    pixel = CFSwapInt32(pixels[x + pixelOffset]);
                    redOnly = pixel & redChannelMask;
                    greenOnly = pixel & greenChannelMask;
                    blueOnly = pixel & blueChannelMask;
                    pixels[x + pixelOffset] = (redOnly >> 20) | (blueOnly << 20) | greenOnly;
                }
            }
        }
        else{
            for(NSInteger y = 0; y < height * bytesPerRow; y += bytesPerRow) {
                pixelOffset = y / 4;
                for(NSInteger x = 0; x < width; x++){
                    pixel = pixels[x + pixelOffset];
                    redOnly = pixel & redChannelMask;
                    greenOnly = pixel & greenChannelMask;
                    blueOnly = pixel & blueChannelMask;
                    pixels[x + pixelOffset] = (redOnly >> 20) | (blueOnly << 20) | greenOnly;
                }
            }
        }
    }
    else{
        return false;
    }
    
    
    return true;
    
}

+ (bool)RGB10A2UBigEndianBitmapFromURL:(NSURL *)url
                                inData:(void *)pixelData
                        bytesPerRow:(NSInteger)bytesPerRow{
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
    
    if(bytesPerRow == 4 * width){
        inStream -> Read(pixelData, imageDataSize);
    }
    else{
        uint8_t* pixelBytes = (uint8_t *)pixelData;
        NSInteger bytesPerScanline = 4*width;
        for(int y = 0; y < height; y++){
            inStream -> Read((void *)(&pixelBytes[y * bytesPerRow]), bytesPerScanline);
        }
    }
    
    inStream -> Close();
    delete inStream;
    inStream = NULL;
    
    uint32_t *pixels = (uint32_t *)pixelData;
    uint32_t pixelOffset = 0;
    if(packing == dpx::kFilledMethodA){
        if(!requiresByteSwap){
            for(NSInteger y = 0; y < height * bytesPerRow; y += bytesPerRow) {
                pixelOffset = y / 4;
                for(NSInteger x = 0; x < width; x++){
                    pixels[x + pixelOffset] = CFSwapInt32(pixels[x + pixelOffset]);
                }
            }
        }
    }
    else if(packing == dpx::kFilledMethodB){
        if(!requiresByteSwap){
            for(NSInteger y = 0; y < height * bytesPerRow; y += bytesPerRow) {
                pixelOffset = y / 4;
                for(NSInteger x = 0; x < pixelCount; x++){
                    pixels[x + pixelOffset] = CFSwapInt32(rotr32(pixels[x + pixelOffset], 2));
                }
            }
        }
        else{
            for(NSInteger y = 0; y < height * bytesPerRow; y += bytesPerRow) {
                pixelOffset = y / 4;
                for(NSInteger x = 0; x < pixelCount; x++){
                    pixels[x + pixelOffset] = CFSwapInt32(rotr32(CFSwapInt32(pixels[x + pixelOffset]), 2));
                }
            }
        }
    }
    
    return true;
}

+ (bool)RGBAhBitmapFromURL:(NSURL *)url
                    inData:(void *)pixelData
                        bytesPerRow:(NSInteger)bytesPerRow{
    ImageSpec *configSpec = new ImageSpec();
    configSpec->attribute("raw:ColorSpace", "raw");
    configSpec->attribute("raw:Demosaic", "AMaZE");
    
    auto in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding], configSpec);
    
    if (!in) {
        return false;
    }
    const ImageSpec &spec = in->spec();
    
    in->read_image (TypeDesc::HALF, pixelData, 8, bytesPerRow);
    
    if(spec.nchannels == 3) {
        vImage_Buffer src;
        src.height = spec.height;
        src.width = spec.width;
        src.rowBytes = bytesPerRow;
        src.data = pixelData;
        
        const uint16_t pixel[4] = {0, 0, 0, 15360};
        
        vImageOverwriteChannelsWithPixel_ARGB16U(pixel, &src, &src, 0x1, kvImageNoFlags);
    }
    
    return true;
}

+ (bool)RGBAfBitmapFromURL:(NSURL *)url
                    inData:(void *)pixelData
               bytesPerRow:(NSInteger)bytesPerRow{
    auto in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return false;
    }
    
    const ImageSpec &spec = in->spec();
    
    in->read_image (TypeDesc::FLOAT, pixelData, 16, bytesPerRow);
    
    if(spec.nchannels == 3) {
        vImage_Buffer src;
        src.height = spec.height;
        src.width = spec.width;
        src.rowBytes = bytesPerRow;
        src.data = pixelData;
        
        vImageOverwriteChannelsWithScalar_ARGBFFFF(1.0, &src, &src, 0x1, kvImageNoFlags);
    }
    
    return true;
}

+ (NSData *)EXRFromRGBAfBitmap:(NSData *)bitmap
                         width:(NSInteger)width
                        height:(NSInteger)height
                   exrBitDepth:(NSInteger)exrBitDepth{
//    ImageOutput *output = ImageOutput::create ([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    NSURL *tempURL = [self.class uniqueTempFileURLWithFileExtension:@"exr"];
    
    auto output = ImageOutput::create ([[tempURL path] cStringUsingEncoding:NSUTF8StringEncoding]);
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
        [[NSFileManager defaultManager] removeItemAtURL:tempURL error:nil];
        return nil;
    }
    
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
