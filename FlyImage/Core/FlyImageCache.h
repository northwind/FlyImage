//
//  FlyImageCache.h
//  Demo
//
//  Created by Ye Tong on 3/17/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FlyImageCacheProtocol.h"
@class FlyImageDataFileManager;

/**
 *	Manage image files in one folder.
 */
@interface FlyImageCache : NSObject <FlyImageCacheProtocol>

@property (nonatomic, assign) CGFloat maxCachedBytes; // Default is 512Mb.
@property (nonatomic, assign) BOOL autoDismissImage; // If you want to reduce memory when the app enter background, set this flag as YES. Default is NO.
@property (nonatomic, strong) FlyImageDataFileManager* dataFileManager;

#ifdef FlyImage_WebP
@property (nonatomic, assign) BOOL autoConvertWebP; // Should convert WebP file to JPEG file automaticlly. Default is NO. If yes, it will speed up retrieving operation for the next time.
@property (nonatomic, assign) CGFloat compressionQualityForWebP; // Default is 0.8.
#endif

- (void)addImageWithKey:(NSString*)key
               filename:(NSString*)filename
              completed:(FlyImageCacheRetrieveBlock)completed;

- (void)addImageWithKey:(NSString*)key
               filename:(NSString*)filename
               drawSize:(CGSize)drawSize
        contentsGravity:(NSString* const)contentsGravity
           cornerRadius:(CGFloat)cornerRadius
              completed:(FlyImageCacheRetrieveBlock)completed;

/**
 *  Get image with customize parameters from cache asynchronously.
 *  Avoid executing `CGDataProviderCreateWithCopyOfData`.
 *
 *  @param key             image key
 *  @param drawSize        render size
 *  @param contentsGravity contentMode of render view
 *  @param cornerRadius    cornerRadius of render view
 *  @param completed       callback
 */
- (void)asyncGetImageWithKey:(NSString*)key
                    drawSize:(CGSize)drawSize
             contentsGravity:(NSString* const)contentsGravity
                cornerRadius:(CGFloat)cornerRadius
                   completed:(FlyImageCacheRetrieveBlock)completed;

/**
 *  Get the image path saved in the disk.
 */
- (NSString*)imagePathWithKey:(NSString*)key;

/**
 *  Protect the file, which can't be removed.
 *
 *  @param key image key
 */
- (void)protectFileWithKey:(NSString*)key;

/**
 *  Don't protect the file, which can be removed.
 *
 *  @param key image key
 */
- (void)unProtectFileWithKey:(NSString*)key;

@end
