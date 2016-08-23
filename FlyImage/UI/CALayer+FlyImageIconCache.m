//
//  CALayer+FlyImageIconCache.m
//  FlyImage
//
//  Created by Ye Tong on 4/27/16.
//  Copyright © 2016 Ye Tong. All rights reserved.
//

#import "CALayer+FlyImageIconCache.h"
#import "FlyImageIconRenderer.h"
#import "FlyImageUtils.h"
#import "objc/runtime.h"

@interface CALayer (__FlyImageIconCache) <FlyImageIconRendererDelegate>
@end

@implementation CALayer (FlyImageIconCache)

static char kRendererKey;
static char kDrawingBlockKey;

- (void)setIconURL:(NSURL*)iconURL
{
    [self setPlaceHolderImageName:nil iconURL:iconURL];
}

- (void)setPlaceHolderImageName:(NSString*)imageName
                        iconURL:(NSURL*)iconURL
{
    FlyImageIconRenderer* renderer = objc_getAssociatedObject(self, &kRendererKey);

    if (renderer == nil) {
        renderer = [[FlyImageIconRenderer alloc] init];
        renderer.delegate = self;

        self.contentsScale = [FlyImageUtils contentsScale];
        self.drawsAsynchronously = YES;

        objc_setAssociatedObject(self, &kRendererKey, renderer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [renderer setPlaceHolderImageName:imageName
                              iconURL:iconURL
                             drawSize:self.bounds.size];
}

- (void)setIconDrawingBlock:(FlyImageIconDrawingBlock)block
{
    objc_setAssociatedObject(self, &kDrawingBlockKey, block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)drawImage:(UIImage*)image inContext:(CGContextRef)context bounds:(CGRect)contextBounds
{
    FlyImageIconDrawingBlock block = objc_getAssociatedObject(self, &kDrawingBlockKey);
    if (block != nil) {
        block(image, context, contextBounds);
        return;
    }

    // Clip to a rounded rect
    if (self.cornerRadius > 0) {
        CGPathRef path = _FICDCreateRoundedRectPath(contextBounds, self.cornerRadius * [FlyImageUtils contentsScale]);
        CGContextAddPath(context, path);
        CFRelease(path);
        CGContextEOClip(context);
    }

    UIGraphicsPushContext(context);
    CGRect drawRect = _FlyImageCalcDrawBounds(image.size, contextBounds.size, self.contentsGravity);
    [image drawInRect:drawRect];
    UIGraphicsPopContext();
}

#pragma mark - FlyImageIconRendererDelegate
- (void)flyImageIconRenderer:(FlyImageIconRenderer*)render
                   drawImage:(UIImage*)image
                     context:(CGContextRef)context
                      bounds:(CGRect)contextBounds
{
    [self drawImage:image inContext:context bounds:contextBounds];
}

- (void)flyImageIconRenderer:(FlyImageIconRenderer*)render willRenderImage:(UIImage*)image
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

@end
