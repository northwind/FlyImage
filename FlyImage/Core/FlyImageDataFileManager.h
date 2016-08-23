//
//  FlyImageDataFileManager.h
//  Demo
//
//  Created by Ye Tong on 3/22/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlyImageDataFile.h"

/**
 *  Manager of FlyImageDataFile. In charge of creating and deleting data file.
 */
@interface FlyImageDataFileManager : NSObject

@property (nonatomic, strong, readonly) NSString* folderPath; // folder saved data files.
@property (nonatomic, assign, readonly) BOOL isDiskFull; // Default is NO.

- (instancetype)initWithFolderPath:(NSString*)folderPath;

/**
 *  Create a `FlyImageDataFile` if it doesn't exist.
 */
- (FlyImageDataFile*)createFileWithName:(NSString*)name;

/**
 *  Add an exist file.
 */
- (void)addExistFileName:(NSString*)name;

/**
 *  Check the file whether exist or not, no delay.
 */
- (BOOL)isFileExistWithName:(NSString*)name;

/**
 *  Get a `FlyImageDataFile` if it exists.
 */
- (FlyImageDataFile*)retrieveFileWithName:(NSString*)name;

/**
 *  Remove data file
 */
- (void)removeFileWithName:(NSString*)name;

/**
 *  Create a `FlyImageDataFile` async.
 */
- (void)asyncCreateFileWithName:(NSString*)name completed:(void (^)(FlyImageDataFile* dataFile))completed;

/**
 *  Remove all the data files, except some special files.
 *
 *  @param names     except files' names
 *  @param toSize    expected size of the folder
 *  @param completed callback
 */
- (void)purgeWithExceptions:(NSArray*)names
                     toSize:(NSUInteger)toSize
                  completed:(void (^)(NSUInteger fileCount, NSUInteger totalSize))completed;

/**
 *  Calculate the folder size.
 */
- (void)calculateSizeWithCompletionBlock:(void (^)(NSUInteger fileCount, NSUInteger totalSize))block;

/**
 *  Free space left in the system space.
 */
- (void)freeDiskSpaceWithCompletionBlock:(void (^)(NSUInteger freeSize))block;

@end
