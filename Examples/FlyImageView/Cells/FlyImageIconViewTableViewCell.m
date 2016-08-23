//
//  FlyImageIconViewTableViewCell.m
//  FlyImageView
//
//  Created by Ye Tong on 5/3/16.
//  Copyright © 2016 Augmn. All rights reserved.
//

#import "FlyImageIconViewTableViewCell.h"
#import "FlyImage.h"

@implementation FlyImageIconViewTableViewCell

- (id)imageViewWithFrame:(CGRect)frame {
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	imageView.layer.cornerRadius = 10;
	[self addSubview:imageView];
	
	return imageView;
}

- (void)renderImageView:(id)imageView url:(NSURL *)url {
	((UIImageView *)imageView).iconURL = url;
}

@end
