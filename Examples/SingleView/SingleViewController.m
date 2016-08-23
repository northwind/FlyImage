//
//  SingleViewController.m
//  SingleView
//
//  Created by Ye Tong on 5/9/16.
//  Copyright © 2016 Augmn. All rights reserved.
//

#import "SingleViewController.h"
#import "FlyImage.h"

@implementation SingleViewController {
	NSMutableArray *_imageViews;
	NSMutableArray *_iconViews;
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[FlyImageCache sharedInstance].autoDismissImage = YES;
	
	_imageViews = [NSMutableArray new];
	_iconViews = [NSMutableArray new];
	
	// add // remove // clear
	CGFloat fromY = self.view.bounds.size.height - 200;
	[self insertButtonWithTitle:@"AddImageView" selector:@selector(onAddImageView) point:CGPointMake(10, fromY)];
	[self insertButtonWithTitle:@"RemoveImageView" selector:@selector(onRemoveImageView) point:CGPointMake(self.view.bounds.size.width/2 - 40, fromY)];
	[self insertButtonWithTitle:@"ClearImageViews" selector:@selector(onClearImageViews) point:CGPointMake(self.view.bounds.size.width - 90, fromY)];
	
	[self insertButtonWithTitle:@"AddIconView" selector:@selector(onAddIconView) point:CGPointMake(10, fromY + 100)];
	[self insertButtonWithTitle:@"RemoveIconView" selector:@selector(onRemoveIconView) point:CGPointMake(self.view.bounds.size.width/2 - 40, fromY + 100)];
	[self insertButtonWithTitle:@"ClearIconViews" selector:@selector(onClearIconViews) point:CGPointMake(self.view.bounds.size.width - 90, fromY + 100)];
	
}

- (void)insertButtonWithTitle:(NSString *)title selector:(SEL)selector point:(CGPoint)point {
	UIButton *addButton = [UIButton buttonWithType:UIButtonTypeSystem];
	addButton.frame = CGRectMake(point.x, point.y, 80, 44);
	addButton.backgroundColor = [UIColor orangeColor];
	[addButton setTitle:title forState:UIControlStateNormal];
	[addButton addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
	addButton.titleLabel.adjustsFontSizeToFitWidth = YES;
	[self.view addSubview:addButton];
}

- (void)onAddImageView {
	static NSInteger kCount = 0;
	
	NSMutableArray *imagesInRow = [NSMutableArray new];
	CGFloat size = self.view.bounds.size.width / 5;
	NSInteger index = kCount % 100;
	
	for (NSInteger i=0; i<4; i++) {
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i * (size + 10), [_imageViews count] * (size + 10), size, size)];
		NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"http://liuliantv.oss-cn-beijing.aliyuncs.com/flyimage/%ld.jpg", (long)index]];
		imageView.imageURL = url;
		[self.view insertSubview:imageView atIndex:0];
		
		[imagesInRow addObject:imageView];
	}
	
	[_imageViews addObject:imagesInRow];
	kCount++;
}

- (void)onRemoveImageView {
	NSArray *imagesInRow = [_imageViews lastObject];
	for (UIImageView *imageView in imagesInRow) {
		[imageView removeFromSuperview];
	}
	
	[_imageViews removeLastObject];
}

- (void)onClearImageViews {
	for (NSArray *imagesInRow in _imageViews) {
		for (UIImageView *imageView in imagesInRow) {
			[imageView removeFromSuperview];
		}
	}
	
	[_imageViews removeAllObjects];
}

- (void)onAddIconView {
	static NSInteger kCount = 0;
	
	NSMutableArray *imagesInRow = [NSMutableArray new];
	CGFloat size = self.view.bounds.size.width / 5;
	NSInteger index = kCount % 100;
	
	for (NSInteger i=0; i<4; i++) {
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i * (size + 10), [_iconViews count] * (size + 10), size, size)];
		NSURL *url = [NSURL URLWithString: [NSString stringWithFormat:@"http://liuliantv.oss-cn-beijing.aliyuncs.com/flyimage/%ld_tn.jpg", (long)index]];
		imageView.iconURL = url;
		[self.view insertSubview:imageView atIndex:0];
		
		[imagesInRow addObject:imageView];
	}
	
	[_iconViews addObject:imagesInRow];
	kCount++;
}

- (void)onRemoveIconView {
	NSArray *imagesInRow = [_iconViews lastObject];
	for (UIImageView *imageView in imagesInRow) {
		[imageView removeFromSuperview];
	}
	
	[_iconViews removeLastObject];
}

- (void)onClearIconViews {
	for (NSArray *imagesInRow in _iconViews) {
		for (UIImageView *imageView in imagesInRow) {
			[imageView removeFromSuperview];
		}
	}
	
	[_iconViews removeAllObjects];
}

@end
