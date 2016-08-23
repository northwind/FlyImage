//
//  FlyImageIconLayerTableViewCell.m
//  FlyImageView
//
//  Created by Ye Tong on 4/27/16.
//  Copyright © 2016 Augmn. All rights reserved.
//

#import "FlyImageIconLayerTableViewCell.h"
#import "FlyImage.h"

@implementation FlyImageIconLayerTableViewCell

- (id)imageViewWithFrame:(CGRect)frame {
	CALayer *imageLayer = [[CALayer alloc] init];
	imageLayer.frame = frame;
	imageLayer.contentsGravity = kCAGravityResizeAspectFill;
	imageLayer.cornerRadius = 10;
	[self.layer addSublayer:imageLayer];
	
	return imageLayer;
}

- (void)renderImageView:(id)imageView url:(NSURL *)url {
	((CALayer *)imageView).iconURL = url;
}

@end
