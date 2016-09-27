//
//  FlyImageIconCache.h
//  Demo
//
//  Created by Norris Tong on 4/2/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlyImageCacheProtocol.h"

/**
 *	Draw the icon in a background thread.
 *
 *  @param context	drawing context
 *  @param contextBounds  image size
 */
typedef void (^FlyImageCacheDrawingBlock)(CGContextRef context, CGRect contextBounds);

/**
 *	FlyImageIconCache will draw icons into one big file, 
 *  and will get great performace when try to render multiple icons in one screen.
 */
@interface FlyImageIconCache : NSObject <FlyImageCacheProtocol>

/**
 *  Add an icon into the FlyImageIconCache.
 *
 *  @param key          unique key
 *  @param size         image size
 *  @param drawingBlock
 *  @param completed    callback after add, can be nil
 */
- (void)addImageWithKey:(NSString*)key
                   size:(CGSize)size
           drawingBlock:(FlyImageCacheDrawingBlock)drawingBlock
              completed:(FlyImageCacheRetrieveBlock)completed;

/**
 *  FlyImageIconCache not support remove an icon from the cache, but you can replace an icon with the same key.
 *  But the new image must has the same size with the previous one.
 *
 *  @param key          unique key
 *  @param drawingBlock
 *  @param completed    callback after replace, can be nil
 */
- (void)replaceImageWithKey:(NSString*)key
               drawingBlock:(FlyImageCacheDrawingBlock)drawingBlock
                  completed:(FlyImageCacheRetrieveBlock)completed;

@end
