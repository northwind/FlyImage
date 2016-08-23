//
//  FlyImageCacheProtocol.h
//  Demo
//
//  Created by Norris Tong on 4/2/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#ifndef FlyImageCacheProtocol_h
#define FlyImageCacheProtocol_h

typedef void (^FlyImageCacheRetrieveBlock)(NSString* key, UIImage* image);

/**
 *  Common API for FlyImageCache and FlyImageIconCache.
 */
@protocol FlyImageCacheProtocol <NSObject>

/**
 *  Create an image cache with default meta path.
 */
+ (instancetype)sharedInstance;

/**
 *  Create an image cache with a specific meta path.
 *
 *  @param metaPath specific meta path, all the images will be saved into folder `metaPath/files`
 */
- (instancetype)initWithMetaPath:(NSString*)metaPath;

/**
 *  Get image from cache asynchronously.
 */
- (void)asyncGetImageWithKey:(NSString*)key
                   completed:(FlyImageCacheRetrieveBlock)completed;

/**
 *  Cancel geting an image from cache if the image has not already got.
 */
- (void)cancelGetImageWithKey:(NSString*)key;

/**
 *  Check if image exists in cache synchronized. NO delay.
 */
- (BOOL)isImageExistWithKey:(NSString*)key;

/**
 *  Remove an image from cache.
 */
- (void)removeImageWithKey:(NSString*)key;

/**
 *  Change the old key with a new key
 */
- (void)changeImageKey:(NSString*)oldKey
                newKey:(NSString*)newKey;

/**
 *  Remove all the images from the cache.
 */
- (void)purge;

@end

#endif /* FlyImageCacheProtocol_h */
