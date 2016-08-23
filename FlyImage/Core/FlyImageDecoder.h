//
//  FlyImageDecoder.h
//  Demo
//
//  Created by Ye Tong on 3/22/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlyImageUtils.h"

/**
 *  Decode image file.
 */
@interface FlyImageDecoder : NSObject

/**
 *  Convert memory buffer to icon.
 *
 *  @param bytes    memory file
 *  @param offset   offset position at the memory file
 *  @param length   size of memory buffer
 *  @param drawSize render size
 */
- (UIImage*)iconImageWithBytes:(void*)bytes
                        offset:(size_t)offset
                        length:(size_t)length
                      drawSize:(CGSize)drawSize;

/**
 *  Decode a single image file.
 *
 *  @param file            FlyImageDataFile instance
 *  @param contentType     only support PNG/JPEG
 *  @param bytes           address of the memory
 *  @param length          file size
 *  @param drawSize        drawing size, not image  size
 *  @param contentsGravity contentsGravity of the image
 *  @param cornerRadius    cornerRadius of the image
 */
- (UIImage*)imageWithFile:(void*)file
              contentType:(ImageContentType)contentType
                    bytes:(void*)bytes
                   length:(size_t)length
                 drawSize:(CGSize)drawSize
          contentsGravity:(NSString* const)contentsGravity
             cornerRadius:(CGFloat)cornerRadius;

#ifdef FlyImage_WebP
- (UIImage*)imageWithWebPData:(NSData*)imageData hasAlpha:(BOOL*)hasAlpha;
#endif

@end
