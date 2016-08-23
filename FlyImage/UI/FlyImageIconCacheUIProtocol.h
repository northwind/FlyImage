//
//  FlyImageIconCacheUIProtocol.h
//  FlyImage
//
//  Created by Ye Tong on 8/9/16.
//  Copyright © 2016 Ye Tong. All rights reserved.
//
#import <UIKit/UIKit.h>

/**
 *  Draw an image in the context with specific bounds.
 */
typedef void (^FlyImageIconDrawingBlock)(UIImage* image, CGContextRef context, CGRect contextBounds);

@protocol FlyImageIconCacheUIProtocol <NSObject>

/**
 *  Convenient method of setPlaceHolderImageName:iconURL.
 */
- (void)setIconURL:(NSURL*)iconURL;

/**
 *  Download an icon, and save it using [FlyImageIconCache shareInstance].
 */
- (void)setPlaceHolderImageName:(NSString*)imageName
                        iconURL:(NSURL*)iconURL;

/**
 *  Set a customize drawing block. If not, it will use the default drawing method.
 */
- (void)setIconDrawingBlock:(FlyImageIconDrawingBlock)block;

@end
