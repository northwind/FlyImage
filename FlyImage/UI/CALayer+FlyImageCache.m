//
//  CALayer+FlyImageCache.m
//  Demo
//
//  Created by Ye Tong on 3/17/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "CALayer+FlyImageCache.h"
#import "FlyImageRenderer.h"
#import "FlyImageUtils.h"
#import "objc/runtime.h"

@interface CALayer (__FlyImageCache) <FlyImageRendererDelegate>
@end

@implementation CALayer (FlyImageCache)

static char kRendererKey;

- (void)setImageURL:(NSURL*)url
{
    [self setPlaceHolderImageName:nil thumbnailURL:nil originalURL:url];
}

- (void)setPlaceHolderImageName:(NSString*)imageName
                   thumbnailURL:(NSURL*)thumbnailURL
                    originalURL:(NSURL*)originalURL
{
    FlyImageRenderer* renderer = objc_getAssociatedObject(self, &kRendererKey);

    if (renderer == nil) {
        renderer = [[FlyImageRenderer alloc] init];
        renderer.delegate = self;

        self.contentsScale = [FlyImageUtils contentsScale];
        self.drawsAsynchronously = YES;

        objc_setAssociatedObject(self, &kRendererKey, renderer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [renderer setPlaceHolderImageName:imageName
                         thumbnailURL:thumbnailURL
                          originalURL:originalURL
                             drawSize:self.bounds.size
                      contentsGravity:self.contentsGravity
                         cornerRadius:self.cornerRadius];
}

- (NSURL*)downloadingURL
{
    return objc_getAssociatedObject(self, @selector(downloadingURL));
}

- (void)setDownloadingURL:(NSURL*)url
{
    objc_setAssociatedObject(self, @selector(downloadingURL), url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (float)downloadingPercentage
{
    return [objc_getAssociatedObject(self, @selector(downloadingPercentage)) floatValue];
}

- (void)setDownloadingPercentage:(float)progress
{
    objc_setAssociatedObject(self, @selector(downloadingPercentage), @(progress), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - FlyImageRendererDelegate
- (void)flyImageRenderer:(FlyImageRenderer*)render willRenderImage:(UIImage*)image
{
    if (image == nil && self.contents == nil) {
        return;
    }

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    self.contents = (__bridge id _Nullable)(image.CGImage);
    [CATransaction commit];

    [self setNeedsLayout];
}

- (void)flyImageRenderer:(FlyImageRenderer*)render didDownloadImageURL:(NSURL*)url progress:(float)progress
{
    self.downloadingURL = url;
    self.downloadingPercentage = progress;
}

@end
