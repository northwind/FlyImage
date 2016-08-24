//
//  FlyImageIconRenderer.m
//  FlyImage
//
//  Created by Ye Tong on 4/27/16.
//  Copyright © 2016 Ye Tong. All rights reserved.
//

#import "FlyImageIconRenderer.h"
#import "FlyImageUtils.h"
#import "FlyImageCache.h"
#import "FlyImageDownloader.h"

@interface FlyImageIconRenderer ()
@property (nonatomic, strong) NSURL* iconURL;
@end

@implementation FlyImageIconRenderer {
    CGSize _drawSize;

    FlyImageDownloadHandlerId* _downloadHandlerId;
}

- (void)dealloc
{
    [self cancelDownload];
}

- (void)cancelDownload
{
    if (_downloadHandlerId != nil) {
        [[FlyImageDownloader sharedInstance] cancelDownloadHandler:_downloadHandlerId];
        _downloadHandlerId = nil;
    }
}

- (void)setPlaceHolderImageName:(NSString*)imageName
                        iconURL:(NSURL*)iconURL
                       drawSize:(CGSize)drawSize
{

    if (_iconURL != nil && [_iconURL.absoluteString isEqualToString:iconURL.absoluteString]) {
        return;
    }

    [self cancelDownload];

    _iconURL = iconURL;
    _drawSize = CGSizeMake(round(drawSize.width), round(drawSize.height));

    [self renderWithPlaceHolderImageName:imageName];
}

- (void)renderWithPlaceHolderImageName:(NSString*)imageName
{
    NSString* key = _iconURL.absoluteString;

    // if has already downloaded image
    if (key != nil && [[FlyImageIconCache sharedInstance] isImageExistWithKey:key]) {
        __weak __typeof__(self) weakSelf = self;
        [[FlyImageIconCache sharedInstance] asyncGetImageWithKey:key
                                                       completed:^(NSString* key, UIImage* image) {
			[weakSelf renderImage:image key:key ];
                                                       }];

        return;
    }

    if (imageName != nil) {
        UIImage* placeHolderImage = [UIImage imageNamed:imageName];
        [self doRenderImage:placeHolderImage];
    } else if (key != nil) {
        // clear
        [self doRenderImage:nil];
    }

    if (key == nil) {
        return;
    }

    if ([[FlyImageCache sharedInstance] isImageExistWithKey:key]) {
        NSString* imagePath = [[FlyImageCache sharedInstance] imagePathWithKey:key];
        if (imagePath != nil) {
            NSURL* url = [NSURL fileURLWithPath:imagePath];
            [self drawIconWithKey:key url:url];
            return;
        }
    }

    [self downloadImage];
}

- (void)downloadImage
{
    __weak __typeof__(self) weakSelf = self;

	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:_iconURL];
	request.timeoutInterval = 30;	// Default 30 seconds
    _downloadHandlerId = [[FlyImageDownloader sharedInstance]
        downloadImageForURLRequest:request
        success:^(NSURLRequest* request, NSURL* filePath) {
							  
							  NSString *downloadedKey = request.URL.absoluteString;
							  [[FlyImageCache sharedInstance] addImageWithKey:downloadedKey
																	 filename:[filePath lastPathComponent]
																	completed:nil];
							  
							  // In case downloaded image is not equal with the new url
							  if ( ![downloadedKey isEqualToString:weakSelf.iconURL.absoluteString] ) {
								  return;
							  }
							  
							  _downloadHandlerId = nil;
							  [weakSelf drawIconWithKey:downloadedKey url:filePath];

        }
        failed:^(NSURLRequest* request, NSError* error) {
							  _downloadHandlerId = nil;
        }];
}

- (void)drawIconWithKey:(NSString*)key url:(NSURL*)url
{
    __weak __typeof__(self) weakSelf = self;
    [[FlyImageIconCache sharedInstance] addImageWithKey:key
        size:_drawSize
        drawingBlock:^(CGContextRef context, CGRect contextBounds) {
											   
											   NSData *data = [NSData dataWithContentsOfURL:url];
											   UIImage *image = [UIImage imageWithData:data];
											   
											   [weakSelf.delegate flyImageIconRenderer:weakSelf
																			 drawImage:image
																			   context:context
																				bounds:contextBounds];

        }
        completed:^(NSString* key, UIImage* image) {
											   [weakSelf renderImage:image key:key];
        }];
}

- (void)renderImage:(UIImage*)image key:(NSString*)key
{
    dispatch_main_sync_safe(^{
		if ( ![_iconURL.absoluteString isEqualToString:key] ) {
			return;
		}
		
		[self doRenderImage:image];
    });
}

- (void)doRenderImage:(UIImage*)image
{
    [_delegate flyImageIconRenderer:self willRenderImage:image];
}

@end
