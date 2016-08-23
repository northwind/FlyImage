//
//  FlyImageUtils.h
//  Demo
//
//  Created by Ye Tong on 3/18/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ImageContentType) { ImageContentTypeUnknown,
                                               ImageContentTypeJPEG,
                                               ImageContentTypePNG,
                                               ImageContentTypeWebP,
                                               ImageContentTypeGif,
                                               ImageContentTypeTiff };

@interface FlyImageUtils : NSObject

+ (NSString*)directoryPath;

+ (CGFloat)contentsScale;

+ (NSString*)clientVersion;

/**
 *  Memory page size, default is 4096
 */
+ (int)pageSize;

/**
 *  Compute the content type for an image data
 *
 *  @param data image data
 *
 */
+ (ImageContentType)contentTypeForImageData:(NSData*)data;

@end

/**
 *  Copy from FastImageCache.
 *
 *  @param rect         draw area
 *  @param cornerRadius
 *
 */
CGMutablePathRef _FICDCreateRoundedRectPath(CGRect rect, CGFloat cornerRadius);

/**
 *  calculate drawing bounds with original image size, target size and contentsGravity of layer.
 *
 *  @param imageSize
 *  @param targetSize
 *  @param contentsGravity layer's attribute
 */
CGRect _FlyImageCalcDrawBounds(CGSize imageSize, CGSize targetSize, NSString* const contentsGravity);

#define FlyImageErrorLog(fmt, ...) NSLog((@"FlyImage Error: " fmt), ##__VA_ARGS__)

#define dispatch_main_sync_safe(block)                   \
    if ([NSThread isMainThread]) {                       \
        block();                                         \
    } else {                                             \
        dispatch_sync(dispatch_get_main_queue(), block); \
    }

#define dispatch_main_async_safe(block)                   \
    if ([NSThread isMainThread]) {                        \
        block();                                          \
    } else {                                              \
        dispatch_async(dispatch_get_main_queue(), block); \
    }
