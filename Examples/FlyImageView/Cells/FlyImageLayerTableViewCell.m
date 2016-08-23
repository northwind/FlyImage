//
//  FlyImageLayerTableViewCell.m
//  Demo
//
//  Created by Ye Tong on 4/18/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "FlyImageLayerTableViewCell.h"
#import "FlyImage.h"

@implementation FlyImageLayerTableViewCell

- (id)imageViewWithFrame:(CGRect)frame {
	CALayer *imageView = [[CALayer alloc] init];
	imageView.frame = frame;
	imageView.contentsGravity = kCAGravityResizeAspectFill;
	imageView.cornerRadius = 10;
	[self.layer addSublayer:imageView];
	
	return imageView;
}

- (void)renderImageView:(id)imageView url:(NSURL *)url {
	((CALayer *)imageView).imageURL = url;
}

@end
