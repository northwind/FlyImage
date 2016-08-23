//
//  FlyImageDataFile.h
//  Demo
//
//  Created by Ye Tong on 3/18/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  Wrapper of data file, map the disk file to the memory.
 *
 *  Only support `append` operation, we can move the pointer to replace the data.
 *
 */
@interface FlyImageDataFile : NSObject

@property (nonatomic, assign, readonly) void* address;
@property (nonatomic, assign, readonly) off_t fileLength; // total length of the file.
@property (nonatomic, assign, readonly) off_t pointer; // append the data after the pointer. Default is 0.
@property (nonatomic, assign) size_t step; // Change the step value to increase the file length. Deafult is 1 byte.

- (instancetype)initWithPath:(NSString*)path;

- (BOOL)open;

- (void)close;

/**
 *  Check the file length, if it is not big enough, then increase the file length with step.
 *
 *  @param offset start position
 *  @param length data length
 *
 *  @return success or failed
 */
- (BOOL)prepareAppendDataWithOffset:(size_t)offset length:(size_t)length;

/**
 *  Append the data after pointer.
 *
 *  Must execute `prepareAppendDataWithOffset:length` first.
 *
 *  @param offset start position
 *  @param length data length
 *
 *  @return success or failed
 */
- (BOOL)appendDataWithOffset:(size_t)offset length:(size_t)length;

@end
