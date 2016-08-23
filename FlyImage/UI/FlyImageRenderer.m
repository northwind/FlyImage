//
//  FlyImageRenderer.m
//  Demo
//
//  Created by Norris Tong on 4/11/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "FlyImageRenderer.h"
#import "FlyImageCache.h"
#import "FlyImageUtils.h"
#import "FlyImageDownloader.h"

@implementation FlyImageRenderer {
    NSString* _placeHolderImageName;
    NSURL* _thumbnailURL;
    NSURL* _originalURL;

    CGSize _drawSize;
    NSString* _contentsGravity;
    CGFloat _cornerRadius;

    FlyImageDownloadHandlerId* _downloadHandlerId;
}

- (instancetype)init
{
    if (self = [super init]) {
        // event
        if ([FlyImageCache sharedInstance].autoDismissImage) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillEnterForeground:)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationDidEnterBackground:)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
        }
    }
    return self;
}

- (void)dealloc
{
    [self cancelDownload];

    if ([FlyImageCache sharedInstance].autoDismissImage) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
    [self cancelDownload];

    // clear image data to reduce memory
    [self renderImage:nil];
}

- (void)applicationWillEnterForeground:(UIApplication*)application
{
    // repaint
    [self render];
}

- (void)cancelDownload
{
    if (_downloadHandlerId != nil) {
        [[FlyImageDownloader sharedInstance] cancelDownloadHandler:_downloadHandlerId];
        _downloadHandlerId = nil;
    }

    // try to cancel getting image operation.
    if (_originalURL) {
        [[FlyImageCache sharedInstance] cancelGetImageWithKey:_originalURL.absoluteString];
    }

    if (_thumbnailURL) {
        [[FlyImageCache sharedInstance] cancelGetImageWithKey:_thumbnailURL.absoluteString];
    }
}

- (void)setPlaceHolderImageName:(NSString*)imageName
                   thumbnailURL:(NSURL*)thumbnailURL
                    originalURL:(NSURL*)originalURL
                       drawSize:(CGSize)drawSize
                contentsGravity:(NSString* const)contentsGravity
                   cornerRadius:(CGFloat)cornerRadius
{

    if (_originalURL != nil && [_originalURL.absoluteString isEqualToString:originalURL.absoluteString]) {
        return;
    }

    [self cancelDownload];

    _placeHolderImageName = imageName;
    _thumbnailURL = thumbnailURL;
    _originalURL = originalURL;
    _drawSize = drawSize;
    _contentsGravity = contentsGravity;
    _cornerRadius = cornerRadius;

    [self render];
}

- (void)render
{
    // 0. clear
    [self renderImage:nil];

    // if has already downloaded original image
    NSString* originalKey = _originalURL.absoluteString;
    if (originalKey != nil && [[FlyImageCache sharedInstance] isImageExistWithKey:originalKey]) {
        __weak __typeof__(self) weakSelf = self;
        [[FlyImageCache sharedInstance] asyncGetImageWithKey:originalKey
                                                    drawSize:_drawSize
                                             contentsGravity:_contentsGravity
                                                cornerRadius:_cornerRadius
                                                   completed:^(NSString* key, UIImage* image) {
														[weakSelf renderOriginalImage:image key:key];
                                                   }];
        return;
    }

    // if there is no thumbnail, then render original image
    NSString* thumbnailKey = _thumbnailURL.absoluteString;
    if (thumbnailKey != nil && [[FlyImageCache sharedInstance] isImageExistWithKey:thumbnailKey]) {
        __weak __typeof__(self) weakSelf = self;
        [[FlyImageCache sharedInstance] asyncGetImageWithKey:thumbnailKey
                                                    drawSize:_drawSize
                                             contentsGravity:_contentsGravity
                                                cornerRadius:_cornerRadius
                                                   completed:^(NSString* key, UIImage* image) {
														[weakSelf renderThumbnailImage:image key:key];
                                                   }];
        return;
    }

    if (_placeHolderImageName != nil) {
        UIImage* placeHolderImage = [UIImage imageNamed:_placeHolderImageName];
        [self renderImage:placeHolderImage];
    }

    if (_thumbnailURL == nil && _originalURL != nil) {
        [self downloadOriginal];
        return;
    }

    if (_thumbnailURL == nil) {
        return;
    }

    [self downloadThumbnail];
}

- (void)downloadThumbnail
{

    __weak __typeof__(self) weakSelf = self;
    __block NSURL* downloadingURL = _thumbnailURL;
    __block NSString* downloadingKey = downloadingURL.absoluteString;

    NSURLRequest* requst = [NSURLRequest requestWithURL:downloadingURL];
    _downloadHandlerId = [[FlyImageDownloader sharedInstance]
        downloadImageForURLRequest:requst
        progress:^(float progress) {
							  if ( [_delegate respondsToSelector:@selector(flyImageRenderer:didDownloadImageURL:progress:)] ){
								  [_delegate flyImageRenderer:weakSelf didDownloadImageURL:downloadingURL progress:progress];
							  }
        }
        success:^(NSURLRequest* request, NSURL* filePath) {
                              _downloadHandlerId = nil;
                              
                              [[FlyImageCache sharedInstance] addImageWithKey:downloadingKey
                                                                     filename:filePath.lastPathComponent
                                                                     drawSize:_drawSize
                                                              contentsGravity:_contentsGravity
                                                                 cornerRadius:_cornerRadius
                                                                    completed:^(NSString *key, UIImage *image) {
                                                                        [weakSelf renderThumbnailImage:image key:key];
                                                                    }];

        }
        failed:^(NSURLRequest* request, NSError* error) {
                              _downloadHandlerId = nil;
			
							  // if error code is cancelled, no need to download original image.
                              if ( error.code != NSURLErrorCancelled && _originalURL != nil ){
                                  [weakSelf downloadOriginal];
                              }
        }];
}

- (void)downloadOriginal
{

    __weak __typeof__(self) weakSelf = self;
    __block NSURL* downloadingURL = _originalURL;
    __block NSString* downloadingKey = downloadingURL.absoluteString;

    NSURLRequest* requst = [NSURLRequest requestWithURL:downloadingURL];
    _downloadHandlerId = [[FlyImageDownloader sharedInstance]
        downloadImageForURLRequest:requst
        progress:^(float progress) {
							  if ( [_delegate respondsToSelector:@selector(flyImageRenderer:didDownloadImageURL:progress:)] ){
								  [_delegate flyImageRenderer:weakSelf didDownloadImageURL:downloadingURL progress:progress];
							  }
        }
        success:^(NSURLRequest* request, NSURL* filePath) {
                              _downloadHandlerId = nil;
                              
                              [[FlyImageCache sharedInstance] addImageWithKey:downloadingKey
                                                                     filename:filePath.lastPathComponent
                                                                     drawSize:_drawSize
                                                              contentsGravity:_contentsGravity
                                                                 cornerRadius:_cornerRadius
                                                                    completed:^(NSString *key, UIImage *image) {
                                                                        [weakSelf renderOriginalImage:image key:key];
                                                                    }];

        }
        failed:^(NSURLRequest* request, NSError* error) {
                              _downloadHandlerId = nil;
        }];
}

- (void)renderThumbnailImage:(UIImage*)image key:(NSString*)key
{
    dispatch_main_sync_safe(^{
		if ( ![key isEqualToString:_thumbnailURL.absoluteString] ) {
			return;
		}
		
		[self renderImage:image];
		
		if ( _originalURL != nil ){
			[self downloadOriginal];
		}
    });
}

- (void)renderOriginalImage:(UIImage*)image key:(NSString*)key
{
    dispatch_main_sync_safe(^{
		if ( ![key isEqualToString:_originalURL.absoluteString] ) {
			return;
		}
		
		[self renderImage:image];
    });
}

- (void)renderImage:(UIImage*)image
{
    [_delegate flyImageRenderer:self willRenderImage:image];
}

@end
