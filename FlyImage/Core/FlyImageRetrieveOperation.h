//
//  FlyImageRetrieveOperation.h
//  FlyImage
//
//  Created by Ye Tong on 8/11/16.
//  Copyright © 2016 Ye Tong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlyImageCacheProtocol.h"

typedef UIImage* (^RetrieveOperationBlock)(void);

/**
 *  Internal class. In charge of retrieving and sending UIImage.
 */
@interface FlyImageRetrieveOperation : NSOperation

/**
 *  When the operation start running, the block will be executed, 
 *  and require an uncompressed UIImage.
 */
- (instancetype)initWithRetrieveBlock:(RetrieveOperationBlock)block;

/**
 *  Allow to add multiple blocks
 *
 *  @param block
 */
- (void)addBlock:(FlyImageCacheRetrieveBlock)block;

/**
 *  Callback with result image, which can be nil.
 */
- (void)executeWithImage:(UIImage*)image;

@end
