//
//  BaseTableViewCell.m
//  Demo
//
//  Created by Norris Tong on 4/15/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "BaseTableViewCell.h"

@implementation BaseTableViewCell {
    NSMutableArray *_imageViews;
    NSArray *_photos;
}

- (void)displayImageWithPhotos:(NSArray *)photos {
    
    if ( _imageViews == nil ) {
        NSInteger photoCount = [photos count];
        _imageViews = [[NSMutableArray alloc] initWithCapacity:photoCount];
        
        CGRect frame = self.frame;
        CGFloat itemWidth = floor(frame.size.width / photoCount);
        CGFloat padding = 2;
        for (int i=0; i<photoCount; i++) {
            id imageView = [self imageViewWithFrame:CGRectMake(i * itemWidth + padding, padding, itemWidth-padding*2, frame.size.height - padding*2)];
            [_imageViews addObject:imageView];
        }
    }
    
    _photos = photos;
    [self setNeedsLayout];
}

- (id)imageViewWithFrame:(CGRect)frame {
    return nil;
}

- (void)renderImageView:(id)imageView url:(NSURL *)url {
}

#pragma mark - Configuring the View Hierarchy
- (void)layoutSubviews {
    [super layoutSubviews];
    
    for (int i=0; i<MIN([_photos count], [_imageViews count]); i++) {
        id imageView = [_imageViews objectAtIndex:i];
        NSURL *url = [_photos objectAtIndex:i];
        [self renderImageView:imageView url:url];
    }
}

@end
