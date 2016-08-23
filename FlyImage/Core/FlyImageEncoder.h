//
//  FlyImageEncoder.h
//  Demo
//
//  Created by Ye Tong on 3/22/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^FFlyImageEncoderDrawingBlock)(CGContextRef context, CGRect contextBounds);

/**
 *  Convert an image to bitmap format.
 */
@interface FlyImageEncoder : NSObject

/**
 *  Draw an image, and save the bitmap data into memory buffer.
 *
 *  @param size         image size
 *  @param bytes        memory buffer
 *  @param drawingBlock drawing function
 */
- (void)encodeWithImageSize:(CGSize)size
                      bytes:(void*)bytes
               drawingBlock:(FFlyImageEncoderDrawingBlock)drawingBlock;

/**
 *  Calculate buffer size with image size.
 *
 *  @param size image size
 */
+ (size_t)dataLengthWithImageSize:(CGSize)size;

@end
