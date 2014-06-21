//
//  OIIOImageRep.m
//  DPXImageViewer
//
//  Created by Wil Gieseler on 3/8/14.
//  Copyright (c) 2014 Wil Gieseler. All rights reserved.
//

#import "OIIOImageRep.h"
#include "imageio.h"

void OIIOTimer(NSString *message, OIIOTimerBlockType block) {
    NSDate *methodStart = [NSDate date];
    block();
    NSTimeInterval executionTime = [[NSDate date] timeIntervalSinceDate:methodStart];
    NSLog(@"%@: %fs", message, executionTime);
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

+ (id)imageRepWithContentsOfURL:(NSURL *)url {
    
    
    ImageInput *in = ImageInput::open([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!in) {
        return nil;
    }
    const ImageSpec &spec = in->spec();

    std::vector<unsigned short> pixels (spec.width * spec.height * spec.nchannels);
    
    in->read_image (TypeDesc::UINT16, &pixels[0]);
    in->close ();
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
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
        //        else if (p.type() == TypeDesc::TypeMatrix) {
        //            const float *f = (const float *)p.data();
        //            printf ("\%f \%f \%f \%f \%f \%f \%f \%f "
        //                    "\%f \%f \%f \%f \%f \%f \%f \%f",
        //                    f[0], f[1], f[2], f[3], f[4], f[5], f[6], f[7],
        //                    f[8], f[9], f[10], f[11], f[12], f[13], f[14], f[15]);
        //        } else
        //            printf ("<unknown data type>");
        attributes[name] = value;
    }
    
    NSBitmapImageRep *imageRep = [[self.class alloc] initWithBitmapDataPlanes:(unsigned char**)&pixels
                                                               pixelsWide:spec.width
                                                               pixelsHigh:spec.height
                                                            bitsPerSample:16
                                                          samplesPerPixel:spec.nchannels
                                                                 hasAlpha:spec.nchannels > 3
                                                                 isPlanar:NO
                                                           colorSpaceName:NSDeviceRGBColorSpace
                                                              bytesPerRow:NULL
                                                             bitsPerPixel:NULL];

    
    OIIOImageRep *oiioImageRep = [[OIIOImageRep alloc] initWithData:[imageRep TIFFRepresentation]];
    
    oiioImageRep.encodingType = [self encodingTypeFromSpec:&spec];
    
    oiioImageRep.oiio_metadata = [attributes copy];
    
    [oiioImageRep setExtraAttribs:(ImageSpec(spec).extra_attribs)];
    
    delete in;
    
    return oiioImageRep;
}

-(BOOL)writeToURL:(NSURL *)url
     encodingType:(OIIOImageEncodingType)encodingType{
    ImageOutput *output = ImageOutput::create ([[url path] cStringUsingEncoding:NSUTF8StringEncoding]);
    ImageSpec selfspec = ImageSpec((int)self.pixelsWide, (int)self.pixelsHigh, 3, [self.class typeDescForEncodingType:[self.class encodingTypeForBitsPerSample:(int)self.bitsPerSample]]);
    
    ImageSpec outspec = ImageSpec((int)self.pixelsWide, (int)self.pixelsHigh, 3);
    
    if(&extra_attribs != nil){
        outspec.extra_attribs = extra_attribs;
    }
    
    [self.class setSpec:&outspec withEncodingType:encodingType];
    
    
    output->open([[url path] cStringUsingEncoding:NSUTF8StringEncoding], selfspec, ImageOutput::Create);
    output->write_image(outspec.format, &(self.bitmapData[0]));
    output->close();
    delete output;
    
    
    if([[NSString stringWithCString:output->geterror().c_str() encoding:NSUTF8StringEncoding] length] > 0){
        NSLog(@"%@", [NSString stringWithCString:output->geterror().c_str() encoding:NSUTF8StringEncoding]);
        return NO;
    }
    
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
