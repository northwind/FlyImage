//
//  FlyImageRenderer.h
//  Demo
//
//  Created by Norris Tong on 4/11/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FlyImageRenderer;
@protocol FlyImageRendererDelegate <NSObject>

/**
 *  Callback before download image.
 */
- (void)flyImageRenderer:(FlyImageRenderer*)render willRenderImage:(UIImage*)image;

@optional
/**
 *  Callback after download image.
 *
 *  @param render
 *  @param url
 *  @param progress 0...1
 */
- (void)flyImageRenderer:(FlyImageRenderer*)render didDownloadImageURL:(NSURL*)url progress:(float)progress;

@end

/**
 *  Internal class to download, draw, and retrieve images.
 */
@interface FlyImageRenderer : NSObject

@property (nonatomic, weak) id<FlyImageRendererDelegate> delegate;

- (void)setPlaceHolderImageName:(NSString*)imageName
                   thumbnailURL:(NSURL*)thumbnailURL
                    originalURL:(NSURL*)originalURL
                       drawSize:(CGSize)drawSize
                contentsGravity:(NSString* const)contentsGravity
                   cornerRadius:(CGFloat)cornerRadius;

@end
