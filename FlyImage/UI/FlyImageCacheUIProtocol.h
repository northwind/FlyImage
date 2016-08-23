//
//  FlyImageCacheUIProtocol.h
//  FlyImage
//
//  Created by Ye Tong on 8/9/16.
//  Copyright © 2016 Ye Tong. All rights reserved.
//
#import <UIKit/UIKit.h>

@protocol FlyImageCacheUIProtocol <NSObject>

@property (nonatomic, strong) NSURL* downloadingURL; // may be nil/thumbnailURL/originalURL.
@property (nonatomic, assign) float downloadingPercentage; // 0-1, downloading progress per downloading URL.

/**
 *  Convenient method of setPlaceHolderImageName:thumbnailURL:originalURL
 *
 *  @param url originalURL
 */
- (void)setImageURL:(NSURL*)url;

/**
 *  Download images and render them with the below order:
 *  1. PlaceHolder
 *  2. Thumbnail Image
 *  3. Original Image
 *
 *  These images will be saved into [FlyImageCache shareInstance]
 */
- (void)setPlaceHolderImageName:(NSString*)imageName
                   thumbnailURL:(NSURL*)thumbnailURL
                    originalURL:(NSURL*)originalURL;

@end
