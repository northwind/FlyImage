//
//  BaseTableViewCell.h
//  Demo
//
//  Created by Norris Tong on 4/15/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BaseTableViewCell : UITableViewCell

- (void)displayImageWithPhotos:(NSArray *)photos;

- (id)imageViewWithFrame:(CGRect)frame;

- (void)renderImageView:(id)imageView url:(NSURL *)url;

@end
