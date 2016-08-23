//
//  FlyImageIconRenderer.h
//  FlyImage
//
//  Created by Ye Tong on 4/27/16.
//  Copyright © 2016 Ye Tong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlyImageIconCache.h"

@class FlyImageIconRenderer;
@protocol FlyImageIconRendererDelegate <NSObject>

- (void)flyImageIconRenderer:(FlyImageIconRenderer*)render willRenderImage:(UIImage*)image;

- (void)flyImageIconRenderer:(FlyImageIconRenderer*)render
                   drawImage:(UIImage*)image
                     context:(CGContextRef)context
                      bounds:(CGRect)contextBounds;

@end

/**
 *  Internal class to download, draw, and retrieve icons.
 */
@interface FlyImageIconRenderer : NSObject

@property (nonatomic, weak) id<FlyImageIconRendererDelegate> delegate;

- (void)setPlaceHolderImageName:(NSString*)imageName
                        iconURL:(NSURL*)iconURL
                       drawSize:(CGSize)drawSize;

@end