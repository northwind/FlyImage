//
//  TriditionTableViewCell.m
//  Demo
//
//  Created by Norris Tong on 4/14/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "TriditionTableViewCell.h"
#import "FlyImageDownloader.h"
#import "FlyImageDataFileManager.h"
#import "FlyImageCache.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

@interface NSString (Extension)
- (NSString *)md5;
@end

@implementation NSString (Extension)
- (NSString *)md5 {
    const char *cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],
            result[1],
            result[2],
            result[3],
            result[4],
            result[5],
            result[6],
            result[7],
            result[8],
            result[9],
            result[10],
            result[11],
            result[12],
            result[13],
            result[14],
            result[15]];
}
@end

@implementation TriditionTableViewCell

- (id)imageViewWithFrame:(CGRect)frame {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.masksToBounds = YES;
    imageView.layer.cornerRadius = 10;
    [self addSubview:imageView];
	
    return imageView;
}

- (void)renderImageView:(id)imageView url:(NSURL *)url {
	
	NSString *key = url.absoluteString;
    if ( [[FlyImageCache sharedInstance] isImageExistWithKey:key] ) {
		
		NSString *path = [[FlyImageCache sharedInstance] imagePathWithKey:key];
        NSURL *url = [NSURL fileURLWithPath:path];
        [self doRenderImageView:imageView url:url];
        
    }else{
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [[FlyImageDownloader sharedInstance] downloadImageForURLRequest:request progress:nil success:^(NSURLRequest *request, NSURL *filePath) {
            
            [[FlyImageCache sharedInstance] addImageWithKey:key filename:[filePath lastPathComponent] completed:^(NSString *key, UIImage *image) {
				((UIImageView *)imageView).image = image;
			}];
			
        } failed:^(NSURLRequest *request, NSError *error) {
            NSLog(@"occur error = %@", error );
        }];
		
		((UIImageView *)imageView).image = nil;
    }
}

- (void)doRenderImageView:(UIImageView *)imageView url:(NSURL *)url {
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:data];
    imageView.image = image;
}

@end
