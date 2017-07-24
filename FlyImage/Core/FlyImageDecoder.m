//
//  FlyImageDecoder.m
//  Demo
//
//  Created by Ye Tong on 3/22/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "FlyImageDecoder.h"
#ifdef FLYIMAGE_WEBP
#import "webp/decode.h"
#endif

static void __ReleaseAsset(void* info, const void* data, size_t size)
{
    if (info != NULL) {
        CFRelease(info); // will cause dealloc of FlyImageDataFile
    }
}

#ifdef FLYIMAGE_WEBP
// This gets called when the UIImage gets collected and frees the underlying image.
static void free_image_data(void* info, const void* data, size_t size)
{
    if (info != NULL) {
        WebPFreeDecBuffer(&(((WebPDecoderConfig*)info)->output));
        free(info);
    }

    if (data != NULL) {
        free((void*)data);
    }
}
#endif

@implementation FlyImageDecoder

- (UIImage*)iconImageWithBytes:(void*)bytes
                        offset:(size_t)offset
                        length:(size_t)length
                      drawSize:(CGSize)drawSize
{

    // Create CGImageRef whose backing store *is* the mapped image table entry. We avoid a memcpy this way.
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, bytes + offset, length, __ReleaseAsset);

    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
    NSInteger bitsPerComponent = 8;
    NSInteger bitsPerPixel = 4 * 8;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    static NSInteger bytesPerPixel = 4;
    static float kAlignment = 64;
    CGFloat screenScale = [FlyImageUtils contentsScale];
    size_t bytesPerRow = ceil((drawSize.width * screenScale * bytesPerPixel) / kAlignment) * kAlignment;

    CGImageRef imageRef = CGImageCreate(drawSize.width * screenScale,
                                        drawSize.height * screenScale,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpace,
                                        bitmapInfo,
                                        dataProvider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault);

    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(colorSpace);

    if (imageRef == nil) {
        return nil;
    }

    UIImage* image = [[UIImage alloc] initWithCGImage:imageRef
                                                scale:screenScale
                                          orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);

    return image;
}

- (CGImageRef)imageRefWithFile:(void*)file
                   contentType:(ImageContentType)contentType
                         bytes:(void*)bytes
                        length:(size_t)length
{
    if (contentType == ImageContentTypeUnknown || contentType == ImageContentTypeGif || contentType == ImageContentTypeTiff) {
        return nil;
    }

    // Create CGImageRef whose backing store *is* the mapped image table entry. We avoid a memcpy this way.
    CGDataProviderRef dataProvider = nil;
    CGImageRef imageRef = nil;
    if (contentType == ImageContentTypeJPEG) {
        CFRetain(file);
        dataProvider = CGDataProviderCreateWithData(file, bytes, length, __ReleaseAsset);
        imageRef = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, YES, kCGRenderingIntentDefault);

    } else if (contentType == ImageContentTypePNG) {
        CFRetain(file);
        dataProvider = CGDataProviderCreateWithData(file, bytes, length, __ReleaseAsset);
        imageRef = CGImageCreateWithPNGDataProvider(dataProvider, NULL, YES, kCGRenderingIntentDefault);

    } else if (contentType == ImageContentTypeWebP) {
#ifdef FLYIMAGE_WEBP
        // `WebPGetInfo` weill return image width and height
        int width = 0, height = 0;
        if (!WebPGetInfo(bytes, length, &width, &height)) {
            return nil;
        }

        WebPDecoderConfig* config = malloc(sizeof(WebPDecoderConfig));
        if (!WebPInitDecoderConfig(config)) {
            return nil;
        }

        config->options.no_fancy_upsampling = 1;
        config->options.bypass_filtering = 1;
        config->options.use_threads = 1;
        config->output.colorspace = MODE_RGBA;

        // Decode the WebP image data into a RGBA value array
        VP8StatusCode decodeStatus = WebPDecode(bytes, length, config);
        if (decodeStatus != VP8_STATUS_OK) {
            return nil;
        }

        // Construct UIImage from the decoded RGBA value array
        uint8_t* data = WebPDecodeRGBA(bytes, length, &width, &height);
        dataProvider = CGDataProviderCreateWithData(config, data, config->options.scaled_width * config->options.scaled_height * 4, free_image_data);

        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

        imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, dataProvider, NULL, YES, renderingIntent);
#endif
    }

    if (dataProvider != nil) {
        CGDataProviderRelease(dataProvider);
    }

    return imageRef;
}

- (UIImage*)imageWithFile:(void*)file
              contentType:(ImageContentType)contentType
                    bytes:(void*)bytes
                   length:(size_t)length
                 drawSize:(CGSize)drawSize
          contentsGravity:(NSString* const)contentsGravity
             cornerRadius:(CGFloat)cornerRadius
{

    CGImageRef imageRef = [self imageRefWithFile:file contentType:contentType bytes:bytes length:length];
    if (imageRef == nil) {
        return nil;
    }

    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    CGFloat contentsScale = 1;
    if (drawSize.width < imageSize.width && drawSize.height < imageSize.height) {
        contentsScale = [FlyImageUtils contentsScale];
    }
    CGSize contextSize = CGSizeMake(drawSize.width * contentsScale, drawSize.height * contentsScale);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);

    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone || infoMask == kCGImageAlphaNoneSkipFirst || infoMask == kCGImageAlphaNoneSkipLast);

    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if (cornerRadius > 0) {
        bitmapInfo &= kCGImageAlphaPremultipliedLast;
    } else if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;

        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }

    // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
    static NSInteger bytesPerPixel = 4;
    static float kAlignment = 64;
    size_t bytesPerRow = ceil((contextSize.width * bytesPerPixel) / kAlignment) * kAlignment;

    CGContextRef context = CGBitmapContextCreate(NULL, contextSize.width, contextSize.height, CGImageGetBitsPerComponent(imageRef), bytesPerRow, colorSpace, bitmapInfo);
    CGColorSpaceRelease(colorSpace);

    // If failed, return undecompressed image
    if (!context) {
        UIImage* image = [[UIImage alloc] initWithCGImage:imageRef
                                                    scale:contentsScale
                                              orientation:UIImageOrientationUp];
        CGImageRelease(imageRef);
        return image;
    }

    CGContextScaleCTM(context, contentsScale, contentsScale);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    CGRect contextBounds = CGRectMake(0, 0, drawSize.width, drawSize.height);

    // Clip to a rounded rect
    if (cornerRadius > 0) {
        CGPathRef path = _FICDCreateRoundedRectPath(contextBounds, cornerRadius);
        CGContextAddPath(context, path);
        CFRelease(path);
        CGContextEOClip(context);
    }

    CGContextDrawImage(context, _FlyImageCalcDrawBounds(imageSize,
                                                        drawSize,
                                                        contentsGravity),
                       imageRef);

    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);

    UIImage* decompressedImage = [UIImage imageWithCGImage:decompressedImageRef
                                                     scale:contentsScale
                                               orientation:UIImageOrientationUp];

    CGImageRelease(decompressedImageRef);
    CGImageRelease(imageRef);

    return decompressedImage;
}

#ifdef FLYIMAGE_WEBP
- (UIImage*)imageWithWebPData:(NSData*)imageData hasAlpha:(BOOL*)hasAlpha
{

    // `WebPGetInfo` weill return image width and height
    int width = 0, height = 0;
    if (!WebPGetInfo(imageData.bytes, imageData.length, &width, &height)) {
        return nil;
    }

    WebPDecoderConfig* config = malloc(sizeof(WebPDecoderConfig));
    if (!WebPInitDecoderConfig(config)) {
        return nil;
    }

    config->options.no_fancy_upsampling = 1;
    config->options.bypass_filtering = 1;
    config->options.use_threads = 1;
    config->output.colorspace = MODE_RGBA;

    // Decode the WebP image data into a RGBA value array
    VP8StatusCode decodeStatus = WebPDecode(imageData.bytes, imageData.length, config);
    if (decodeStatus != VP8_STATUS_OK) {
        return nil;
    }

    // set alpha value
    if (hasAlpha != nil) {
        *hasAlpha = config->input.has_alpha;
    }

    // Construct UIImage from the decoded RGBA value array
    uint8_t* data = WebPDecodeRGBA(imageData.bytes, imageData.length, &width, &height);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(config, data, config->options.scaled_width * config->options.scaled_height * 4, free_image_data);

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, dataProvider, NULL, YES, renderingIntent);
    UIImage* decodeImage = [UIImage imageWithCGImage:imageRef];

    UIGraphicsBeginImageContextWithOptions(decodeImage.size, !config->input.has_alpha, 1);
    [decodeImage drawInRect:CGRectMake(0, 0, decodeImage.size.width, decodeImage.size.height)];
    UIImage* decompressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return decompressedImage;
}
#endif

@end
