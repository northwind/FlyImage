//
//  FlyImageDownloader.h
//  Demo
//
//  Created by Ye Tong on 3/22/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^FlyImageDownloadProgressBlock)(float progress);
typedef void (^FlyImageDownloadSuccessBlock)(NSURLRequest* request, NSURL* filePath);
typedef void (^FlyImageDownloadFailedBlock)(NSURLRequest* request, NSError* error);
typedef NSUUID FlyImageDownloadHandlerId; // Unique ID of handler

@class FlyImageDownloader;
@protocol FlyImageDownloaderDelegate <NSObject>

@optional
/**
 *  Callback before sending request.
 */
- (void)FlyImageDownloader:(FlyImageDownloader*)manager
           willSendRequest:(NSURLRequest*)request;

/**
 *  Callback after complete download.
 */
- (void)FlyImageDownloader:(FlyImageDownloader*)manager
        didReceiveResponse:(NSURLResponse*)response
                  filePath:(NSURL*)filePath
                     error:(NSError*)error
                   request:(NSURLRequest*)request;

/**
 *  Callback after cancel some request.
 */
- (void)FlyImageDownloader:(FlyImageDownloader*)manager
         willCancelRequest:(NSURLRequest*)request;

@end

@interface FlyImageDownloader : NSObject

@property (nonatomic, weak) id<FlyImageDownloaderDelegate> delegate;
@property (nonatomic, copy) NSString* destinationPath;
@property (nonatomic, assign) NSInteger maxDownloadingCount; // Default is 5;

/**
 *  Create a FlyImageDownloader with a default destination path.
 */
+ (instancetype)sharedInstance;

/**
 *  Create a FlyImageDownloader with a specific destination path.
 */
- (instancetype)initWithDestinationPath:(NSString*)destinationPath;

- (FlyImageDownloadHandlerId*)downloadImageForURLRequest:(NSURLRequest*)request;

- (FlyImageDownloadHandlerId*)downloadImageForURLRequest:(NSURLRequest*)request
                                                 success:(FlyImageDownloadSuccessBlock)success
                                                  failed:(FlyImageDownloadFailedBlock)failed;

/**
 *  Send a download request with callbacks
 */
- (FlyImageDownloadHandlerId*)downloadImageForURLRequest:(NSURLRequest*)request
                                                progress:(FlyImageDownloadProgressBlock)progress
                                                 success:(FlyImageDownloadSuccessBlock)success
                                                  failed:(FlyImageDownloadFailedBlock)failed;

/**
 *  Cancel a downloading request.
 *
 *  @param handlerId can't be nil
 */
- (void)cancelDownloadHandler:(FlyImageDownloadHandlerId*)handlerId;

@end
