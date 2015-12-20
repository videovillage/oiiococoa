//
//  OIIOImageRep.m
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "OIIOImageRep.h"
#include "imageio.h"

#include <sys/time.h>
#include <mach/mach_time.h>  // for mach_absolute_time() and friends

void OIIOTimer(NSString *message, OIIOTimerBlockType block) {
    NSDate *methodStart = [NSDate date];
    block();
    NSTimeInterval executionTime = [[NSDate date] timeIntervalSinceDate:methodStart];
    NSLog(@"%@: %fs", message, executionTime);
}

//encapsulate the code to be time in the block and this will return the execution time in seconds.(or fractions thereof...)
Float32 timerBlock (void (^block)(void))
{
	mach_timebase_info_data_t info;
	if (mach_timebase_info(&info) != KERN_SUCCESS)
		return - 1.0;
	
	uint64_t start = mach_absolute_time ();
	block ();
	uint64_t end = mach_absolute_time ();
	uint64_t elapsed = end - start;
	__block uint64_t nanos = elapsed * info.numer / info.denom;
	return (Float32)nanos / NSEC_PER_SEC;
}


OIIO_NAMESPACE_USING

@interface OIIOImageRep (){
    ImageIOParameterList extra_attribs;
}

@end

@implementation OIIOImageRep

//+ (void)load {
//    [NSImageRep registerImageRepClass:self];
//}


+ (BOOL)canInitWithData:(NSData *)data {
    return NO;
}

+ (NSArray *)imageUnfilteredTypes {
    return @[@"org.smpte.dpx"];
}

- (instancetype)init{
    if(self = [super init]){
        self.oiio_metadata = [NSDictionary dictionary];
        self.encodingType = OIIOImageEncodingTypeNONE;
    }
    return self;
}

- (void)setExtraAttribs:(ImageIOParameterList)attribs{
    extra_attribs = attribs;
}

+ (CGImageRef)newCGImageWithContentsOfURL:(NSURL *)url metadata:(NSDictionary **)metadata{
	ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
	if (!in) {
		return nil;
	}
	const ImageSpec &spec = in->spec();
    
    NSInteger pixelCount = spec.width * spec.height * spec.nchannels;
    
    NSMutableData *pixelData = [NSMutableData dataWithLength:pixelCount*sizeof(unsigned short)];
	
	in->read_image (TypeDesc::UINT16, pixelData.mutableBytes);
	in->close ();

    if (metadata) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        attributes[@"oiiococoa:ImageEncodingType"] = @([self encodingTypeFromSpec:&spec]);
        for (size_t i = 0;  i < spec.extra_attribs.size();  ++i) {

            const ParamValue &p (spec.extra_attribs[i]);
            NSString *name = [NSString stringWithCString:p.name().c_str() encoding:NSUTF8StringEncoding];
            id value = [NSNull null];

            if (p.type() == TypeDesc::TypeString){
                value = @(*(const char **)p.data());
            }
            else if (p.type() == TypeDesc::TypeFloat) {
                value = @(*(const float *)p.data());
            }
            else if (p.type() == TypeDesc::TypeInt) {
                value = @(*(const int *)p.data());
            }
            else if (p.type() == TypeDesc::UINT){
                value = @(*(const unsigned int *)p.data());
            }
            if(value != nil){
                attributes[name] = value;
            }
            
        }
        
        *metadata = [NSDictionary dictionaryWithDictionary: attributes];
    }

	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, pixelData.mutableBytes, 2*pixelCount, NULL);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGImageRef image = CGImageCreate(spec.width,
									 spec.height,
									 16,
									 16*spec.nchannels,
									 2*spec.nchannels*spec.width,
									 colorspace,
									 spec.nchannels>3 ? kCGBitmapByteOrder16Little | kCGImageAlphaLast : kCGBitmapByteOrder16Little | kCGImageAlphaNone,
									 provider,
									 NULL,
									 YES,
									 kCGRenderingIntentDefault);
	
	CGColorSpaceRelease(colorspace);

	delete in;
	CGDataProviderRelease(provider);
	
	return image;
}

+ (id) imageRepWithContentsOfURL:(NSURL *)url{
    NSDictionary *attributes = nil;
    CGImageRef image = [self newCGImageWithContentsOfURL:url metadata:&attributes];
	
    NSMutableData *mutableData = [NSMutableData data];

    CGImageDestinationRef dest = CGImageDestinationCreateWithData((CFMutableDataRef)mutableData, (CFStringRef)@"public.tiff", 1, NULL);

    CGImageDestinationAddImage(dest,image,NULL);
    CGImageDestinationFinalize(dest);
    CFRelease(dest);

    CGImageRelease(image);

    OIIOImageRep *oiioImageRep = [[self.class alloc] initWithData:mutableData];

    oiioImageRep.encodingType = (OIIOImageEncodingType)[attributes[@"oiiococoa:ImageEncodingType"] integerValue];
    
    oiioImageRep.oiio_metadata = [attributes copy];
    
    //[oiioImageRep setExtraAttribs:(ImageSpec(spec).extra_attribs)];

    return oiioImageRep;
}

-(BOOL)writeToURL:(NSURL *)url
     encodingType:(OIIOImageEncodingType)encodingType{
    ImageOutput *output = ImageOutput::create ([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    
    ImageSpec selfspec = ImageSpec((int)self.pixelsWide, (int)self.pixelsHigh, (int)self.samplesPerPixel, [self.class typeDescForEncodingType:[self.class encodingTypeForBitsPerSample:(int)self.bitsPerSample]]);

    ImageSpec outspec = ImageSpec((int)self.pixelsWide, (int)self.pixelsHigh, 3);
    
    if(&extra_attribs != nil){
        outspec.extra_attribs = extra_attribs;
    }
    
    [self.class setSpec:&outspec withEncodingType:encodingType];

    outspec.attribute("oiio:Endian","little");

//    stride_t stride = self.samplesPerPixel == 4 ? (self.bitsPerSample/8) : AutoStride;
//    NSLog(@"%i %i", selfspec.nchannels, (int)selfspec.format.size());

    output->open([[url path] cStringUsingEncoding:NSUTF8StringEncoding], outspec, ImageOutput::Create);
    output->write_image(selfspec.format, &(self.bitmapData[0]), selfspec.nchannels * selfspec.format.size(), AutoStride, AutoStride);

    
    
    if([[NSString stringWithCString:output->geterror().c_str() encoding:NSUTF8StringEncoding] length] > 0){
        NSLog(@"%@", [NSString stringWithCString:output->geterror().c_str() encoding:NSUTF8StringEncoding]);
        output->close();
        delete output;
        return NO;
    }
    
    output->close();
    delete output;
    
    return YES;
}

+ (void)copyAttributes:(NSDictionary *)attributes toSpec:(ImageSpec *)spec{
//    for(NSString *key in attributes.allKeys){
//        
//    }
    return;
}

+ (OIIOImageEncodingType)encodingTypeForBitsPerSample:(long)bitsPerSample{
    if(bitsPerSample == 8){
        return OIIOImageEncodingTypeUINT8;
    }
    else if(bitsPerSample == 10){
        return OIIOImageEncodingTypeUINT10;
    }
    else if(bitsPerSample == 12){
        return OIIOImageEncodingTypeUINT12;
    }
    else if(bitsPerSample == 16){
        return OIIOImageEncodingTypeUINT16;
    }
    else if(bitsPerSample == 32){
        return OIIOImageEncodingTypeUINT32;
    }
    return OIIOImageEncodingTypeNONE;
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

+ (void)setSpec:(ImageSpec *)spec withEncodingType:(OIIOImageEncodingType)type{
    spec->set_format([self.class typeDescForEncodingType:type]);
    if(type == OIIOImageEncodingTypeUINT10){
        spec->attribute ("oiio:BitsPerSample", 10);
    }
    else if(type == OIIOImageEncodingTypeUINT12){
        spec->attribute ("oiio:BitsPerSample", 12);
    }
    
}

+(TypeDesc)typeDescForEncodingType:(OIIOImageEncodingType)type{
    if(type == OIIOImageEncodingTypeUINT8){
        return (TypeDesc::UINT8);
    }
    else if(type == OIIOImageEncodingTypeINT8){
        return (TypeDesc::INT8);
    }
    else if(type == OIIOImageEncodingTypeUINT10){
        return (TypeDesc::UINT16);
    }
    else if(type == OIIOImageEncodingTypeUINT12){
        return (TypeDesc::UINT16);
    }
    else if(type == OIIOImageEncodingTypeUINT16){
        return (TypeDesc::UINT16);
    }
    else if(type == OIIOImageEncodingTypeINT16){
        return (TypeDesc::INT16);
    }
    else if(type == OIIOImageEncodingTypeUINT32){
        return (TypeDesc::UINT32);
    }
    else if(type == OIIOImageEncodingTypeINT32){
        return (TypeDesc::INT32);
    }
    else if(type == OIIOImageEncodingTypeHALF){
        return (TypeDesc::HALF);
    }
    else if(type == OIIOImageEncodingTypeFLOAT){
        return (TypeDesc::FLOAT);
    }
    else if(type == OIIOImageEncodingTypeDOUBLE){
        return (TypeDesc::DOUBLE);
    }
    return TypeDesc::UNKNOWN;
}
    
- (BOOL)drawInRect:(NSRect)dstSpacePortionRect fromRect:(NSRect)srcSpacePortionRect operation:(NSCompositingOperation)op fraction:(CGFloat)requestedAlpha respectFlipped:(BOOL)respectContextIsFlipped hints:(NSDictionary *)hints NS_AVAILABLE_MAC(10_6) {
    
    return [super drawInRect:dstSpacePortionRect fromRect:srcSpacePortionRect operation:op fraction:requestedAlpha respectFlipped:respectContextIsFlipped hints:hints];
}



@end
