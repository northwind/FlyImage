//
//  FlyImageRetrieveOperation.m
//  FlyImage
//
//  Created by Ye Tong on 8/11/16.
//  Copyright © 2016 Ye Tong. All rights reserved.
//

#import "FlyImageRetrieveOperation.h"

@implementation FlyImageRetrieveOperation {
    NSMutableArray* _blocks;
    RetrieveOperationBlock _retrieveBlock;
}

- (instancetype)initWithRetrieveBlock:(RetrieveOperationBlock)block
{
    if (self = [self init]) {
        _retrieveBlock = block;
    }
    return self;
}

- (void)addBlock:(FlyImageCacheRetrieveBlock)block
{
    if (_blocks == nil) {
        _blocks = [NSMutableArray new];
    }

    [_blocks addObject:block];
}

- (void)executeWithImage:(UIImage*)image
{
    for (FlyImageCacheRetrieveBlock block in _blocks) {
        block(self.name, image);
    }
    [_blocks removeAllObjects];
}

- (void)main
{
    if (self.isCancelled) {
        return;
    }

    UIImage* image = _retrieveBlock();
    [self executeWithImage:image];
}

- (void)cancel
{
    if (self.isFinished)
        return;
    [super cancel];

    [self executeWithImage:nil];
}

@end
