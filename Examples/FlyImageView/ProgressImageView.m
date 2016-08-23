//
//  ProgressImageView.m
//  FlyImageView
//
//  Created by Ye Tong on 8/12/16.
//  Copyright © 2016 Augmn. All rights reserved.
//

#import "ProgressImageView.h"
#import "FlyImage.h"

@implementation ProgressImageView

- (instancetype)initWithFrame:(CGRect)frame {
	if ( self = [super initWithFrame:frame] ) {
		[self addObserver:self forKeyPath:@"downloadingPercentage" options:NSKeyValueObservingOptionNew context:nil];
	}
	
	return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"downloadingPercentage"]) {
		NSLog(@"downloadingURL : %@", self.downloadingURL );
		NSLog(@"downloadingPercentage : %f", self.downloadingPercentage );
	}
}

@end
