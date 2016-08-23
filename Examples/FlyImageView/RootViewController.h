//
//  RootViewController.h
//  Demo
//
//  Created by Ye Tong on 3/24/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootViewController : UIViewController

@property (nonatomic, strong) NSArray *cells;
@property (nonatomic, assign) CGFloat heightOfCell;
@property (nonatomic, assign) NSInteger cellsPerRow;
@property (nonatomic, assign) NSInteger activeIndex;
@property (nonatomic, copy) NSString *suffix;

@end
