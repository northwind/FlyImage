//
//  SDWebImageTableViewCell.m
//  Demo
//
//  Created by Ye Tong on 4/18/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "SDWebImageTableViewCell.h"
#import "UIImageView+WebCache.h"

@implementation SDWebImageTableViewCell

- (id)imageViewWithFrame:(CGRect)frame {
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	imageView.layer.cornerRadius = 10;
	[self addSubview:imageView];
	
	return imageView;
}

- (void)renderImageView:(id)imageView url:(NSURL *)url {
	[((UIImageView *)imageView) sd_setImageWithURL:url];
}

@end
