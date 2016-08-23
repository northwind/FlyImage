//
//  FlyImageDownloader.m
//  Demo
//
//  Created by Ye Tong on 3/22/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "FlyImageDownloader.h"
#import "AFNetworking.h"
#import "FlyImageUtils.h"
#import "FlyImageDataFileManager.h"
#import "FlyImageCache.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

@interface FlyImageDownloaderResponseHandler : NSObject
@property (nonatomic, strong) NSUUID* uuid;
@property (nonatomic, strong) FlyImageDownloadProgressBlock processingBlock;
@property (nonatomic, strong) FlyImageDownloadSuccessBlock successBlock;
@property (nonatomic, strong) FlyImageDownloadFailedBlock failedBlock;
@end

@implementation FlyImageDownloaderResponseHandler

- (instancetype)initWithUUID:(NSUUID*)uuid
                    progress:(FlyImageDownloadProgressBlock)progress
                     success:(FlyImageDownloadSuccessBlock)success
                      failed:(FlyImageDownloadFailedBlock)failed
{
    if (self = [self init]) {
        self.uuid = uuid;
        self.processingBlock = progress;
        self.successBlock = success;
        self.failedBlock = failed;
    }
    return self;
}

@end

@interface FlyImageDownloaderMergedTask : NSObject
@property (nonatomic, strong) NSString* identifier;
@property (nonatomic, strong) NSMutableArray* handlers;
@property (nonatomic, strong) NSURLSessionDownloadTask* task;
@end

@implementation FlyImageDownloaderMergedTask

- (instancetype)initWithIdentifier:(NSString*)identifier task:(NSURLSessionDownloadTask*)task
{
    if (self = [self init]) {
        self.identifier = identifier;
        self.task = task;
        self.handlers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addResponseHandler:(FlyImageDownloaderResponseHandler*)handler
{
    [self.handlers addObject:handler];
}

- (void)removeResponseHandler:(FlyImageDownloaderResponseHandler*)handler
{
    [self.handlers removeObject:handler];
}

- (void)clearHandlers
{
    [self.handlers removeAllObjects];
}

@end

@interface NSString (Extension)
- (NSString*)md5;
@end

@implementation NSString (Extension)
- (NSString*)md5
{
    const char* cStr = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                                      result[0],
                                      result[1],
                                      result[2],
                                      result[3],
                                      result[4],
                                      result[5],
                                      result[6],
                                      result[7],
                                      result[8],
                                      result[9],
                                      result[10],
                                      result[11],
                                      result[12],
                                      result[13],
                                      result[14],
                                      result[15]];
}
@end

@interface FlyImageDownloader ()
@property (nonatomic, strong) NSMutableDictionary* downloadFile;
@property (nonatomic, strong) NSMutableDictionary* mergedTasks;
@property (nonatomic, strong) NSMutableArray* queuedMergedTasks;
@property (nonatomic, assign) NSInteger activeRequestCount;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@property (nonatomic, strong) dispatch_queue_t responseQueue;
@end

@implementation FlyImageDownloader {
    AFURLSessionManager* _sessionManager;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static FlyImageDownloader* __instance = nil;
    dispatch_once(&onceToken, ^{
		NSString *folderPath = [FlyImageCache sharedInstance].dataFileManager.folderPath;
		__instance = [[[self class] alloc] initWithDestinationPath:folderPath];
    });

    return __instance;
}

- (instancetype)initWithDestinationPath:(NSString*)destinationPath
{
    if (self = [self init]) {

        _maxDownloadingCount = 5;
        _mergedTasks = [[NSMutableDictionary alloc] initWithCapacity:_maxDownloadingCount];
        _queuedMergedTasks = [[NSMutableArray alloc] initWithCapacity:_maxDownloadingCount];

        _destinationPath = [destinationPath copy];

        NSString* name = [NSString stringWithFormat:@"com.flyimage.imagedownloader.synchronizationqueue-%@", [[NSUUID UUID] UUIDString]];
        self.synchronizationQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);

        name = [NSString stringWithFormat:@"com.flyimage.imagedownloader.responsequeue-%@", [[NSUUID UUID] UUIDString]];
        self.responseQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);

        NSString* configurationIdentifier = [NSString stringWithFormat:@"com.flyimage.downloadsession.%@", [[NSUUID UUID] UUIDString]];
        NSURLSessionConfiguration* configuration = [FlyImageDownloader configurationWithIdentifier:configurationIdentifier];
        _sessionManager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    }
    return self;
}

// 8.0以上生成Background Session，以下默认为普通session
+ (NSURLSessionConfiguration*)configurationWithIdentifier:(NSString*)identifier
{
    NSURLSessionConfiguration* configuration;
#if (defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && __IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1100)
    configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
#else
    configuration = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
#endif

    configuration.HTTPShouldSetCookies = YES;
    configuration.HTTPShouldUsePipelining = NO;

    configuration.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
    configuration.allowsCellularAccess = YES;

    return configuration;
}

- (FlyImageDownloadHandlerId*)downloadImageForURLRequest:(NSURLRequest*)request
{
    return [self downloadImageForURLRequest:request
                                   progress:nil
                                    success:nil
                                     failed:nil];
}

- (FlyImageDownloadHandlerId*)downloadImageForURLRequest:(NSURLRequest*)request
                                                 success:(FlyImageDownloadSuccessBlock)success
                                                  failed:(FlyImageDownloadFailedBlock)failed
{
    return [self downloadImageForURLRequest:request
                                   progress:nil
                                    success:success
                                     failed:failed];
}

- (FlyImageDownloadHandlerId*)downloadImageForURLRequest:(NSURLRequest*)request
                                                progress:(FlyImageDownloadProgressBlock)progress
                                                 success:(FlyImageDownloadSuccessBlock)success
                                                  failed:(FlyImageDownloadFailedBlock)failed
{
    NSParameterAssert(request != nil);

    __block FlyImageDownloadHandlerId* handlerId = nil;
    dispatch_sync(_synchronizationQueue, ^{
        if (request.URL.absoluteString == nil) {
            if (failed) {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadURL userInfo:nil];
                dispatch_main_sync_safe(^{
                    failed(request, error);
                });
            }
            return;
        }

        NSString *identifier = [request.URL.absoluteString md5];
        handlerId = [NSUUID UUID];
        
        // 1) Append the success and failure blocks to a pre-existing request if it already exists
        FlyImageDownloaderMergedTask *existingMergedTask = self.mergedTasks[identifier];
        if (existingMergedTask != nil) {
            FlyImageDownloaderResponseHandler *handler = [[FlyImageDownloaderResponseHandler alloc]
                                                          initWithUUID:handlerId
                                                          progress:progress
                                                          success:success
                                                          failed:failed];
            [existingMergedTask addResponseHandler:handler];
            return;
        }
        
        __weak __typeof__(self) weakSelf = self;
        NSURLSessionDownloadTask *task =
        [_sessionManager downloadTaskWithRequest:request
                                        progress:^(NSProgress * _Nonnull downloadProgress) {
											dispatch_async(weakSelf.responseQueue, ^{
												FlyImageDownloaderMergedTask *existingMergedTask = weakSelf.mergedTasks[identifier];
												for (FlyImageDownloaderResponseHandler *hanlder in existingMergedTask.handlers) {
													if ( hanlder.processingBlock != nil ) {
														dispatch_main_async_safe(^{
															hanlder.processingBlock( downloadProgress.fractionCompleted );
														});
													}
												}
											});
										}
                                     destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                                         return [NSURL fileURLWithPath:[_destinationPath stringByAppendingPathComponent:identifier]];
                                     }
                               completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
								   dispatch_async(weakSelf.responseQueue, ^{
									   __strong __typeof__(weakSelf) strongSelf = weakSelf;
									   if ( [_delegate respondsToSelector:@selector(FlyImageDownloader:didReceiveResponse:filePath:error:request:)] ) {
										   dispatch_main_sync_safe(^{
											   [_delegate FlyImageDownloader:strongSelf
															   didReceiveResponse:response
																		 filePath:filePath
																			error:error
																		  request:request];
										   });
									   }
									   
									   FlyImageDownloaderMergedTask *mergedTask = strongSelf.mergedTasks[identifier];
									   if (error != nil) {
										   for (FlyImageDownloaderResponseHandler *handler in mergedTask.handlers) {
											   if (handler.failedBlock) {
												   handler.failedBlock(request, error);
											   }
										   }
										   
										   // remove error file
										   [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
									   }else{
										   for (FlyImageDownloaderResponseHandler *handler in mergedTask.handlers) {
											   if (handler.successBlock) {
												   handler.successBlock(request, filePath);
											   }
										   }
									   }
									   
									   // remove exist task
									   [strongSelf.mergedTasks removeObjectForKey:identifier];
									   
									   [strongSelf safelyDecrementActiveTaskCount];
									   [strongSelf safelyStartNextTaskIfNecessary];
								   });
                               }];
        
        // 4) Store the response handler for use when the request completes
		existingMergedTask = [[FlyImageDownloaderMergedTask alloc] initWithIdentifier:identifier task:task];
        self.mergedTasks[ identifier ] = existingMergedTask;
        
        FlyImageDownloaderResponseHandler *handler = [[FlyImageDownloaderResponseHandler alloc]
                                                      initWithUUID:handlerId
                                                      progress:progress
                                                      success:success
                                                      failed:failed];
        [existingMergedTask addResponseHandler:handler];
        
        // 5) Either start the request or enqueue it depending on the current active request count
        if ([self isActiveRequestCountBelowMaximumLimit]) {
            [self startMergedTask:existingMergedTask];
        } else {
            [self enqueueMergedTask:existingMergedTask];
        }
    });

    return handlerId;
}

- (void)cancelDownloadHandler:(FlyImageDownloadHandlerId*)handlerId
{
    NSParameterAssert(handlerId != nil);

    dispatch_sync(_synchronizationQueue, ^{
        
        FlyImageDownloaderMergedTask *matchedTask = nil;
        FlyImageDownloaderResponseHandler *matchedHandler = nil;
        
        for (NSString *URLIdentifier in self.mergedTasks) {
            FlyImageDownloaderMergedTask *mergedTask = self.mergedTasks[ URLIdentifier ];
            for (FlyImageDownloaderResponseHandler *handler in mergedTask.handlers) {
                if ( [handler.uuid isEqual:handlerId] ) {
                    matchedHandler = handler;
                    matchedTask = mergedTask;
                    break;
                }
            }
        }
        
        if ( matchedTask == nil ) {
            for (FlyImageDownloaderMergedTask *mergedTask in _queuedMergedTasks) {
                for (FlyImageDownloaderResponseHandler *handler in mergedTask.handlers) {
                    if ( [handler.uuid isEqual:handlerId] ) {
                        matchedHandler = handler;
                        matchedTask = mergedTask;
                        break;
                    }
                }
            }
        }
        
        if ( matchedTask == nil || matchedHandler == nil ) {
            return;
        }
        [matchedTask removeResponseHandler:matchedHandler];
        
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
        dispatch_main_sync_safe(^{
            if ( matchedHandler.failedBlock != nil ){
                matchedHandler.failedBlock(nil, error);
            }
        });
        
        // remove this task from both merged and queued tasks
        if (matchedTask.handlers.count == 0) {
			
			if ( [_delegate respondsToSelector:@selector(FlyImageDownloader:willCancelRequest:)] ) {
				dispatch_main_sync_safe(^{
					[_delegate FlyImageDownloader:self willCancelRequest:matchedTask.task.originalRequest];
				});
			}
			
            [matchedTask.task cancel];
            
            [self.mergedTasks removeObjectForKey:matchedTask.identifier];
            [_queuedMergedTasks removeObject:matchedTask];
        }
    });
}

- (BOOL)isActiveRequestCountBelowMaximumLimit
{
    return self.activeRequestCount < self.maxDownloadingCount;
}

- (void)startMergedTask:(FlyImageDownloaderMergedTask*)mergedTask
{
    if ([_delegate respondsToSelector:@selector(FlyImageDownloader:willSendRequest:)]) {
        dispatch_main_sync_safe(^{
			[_delegate FlyImageDownloader:self willSendRequest:mergedTask.task.originalRequest];
        });
    }

    [mergedTask.task resume];
    ++self.activeRequestCount;
}

- (void)enqueueMergedTask:(FlyImageDownloaderMergedTask*)mergedTask
{
    // default is AFImageDownloadPrioritizationLIFO
    [_queuedMergedTasks insertObject:mergedTask atIndex:0];
}

- (FlyImageDownloaderMergedTask*)dequeueMergedTask
{
    FlyImageDownloaderMergedTask* mergedTask = nil;
    mergedTask = [_queuedMergedTasks lastObject];
    [self.queuedMergedTasks removeObject:mergedTask];
    return mergedTask;
}

- (void)safelyDecrementActiveTaskCount
{
    dispatch_sync(_synchronizationQueue, ^{
        if (self.activeRequestCount > 0) {
            self.activeRequestCount -= 1;
        }
    });
}

- (void)safelyStartNextTaskIfNecessary
{
    dispatch_sync(_synchronizationQueue, ^{
        while ([self isActiveRequestCountBelowMaximumLimit] && [_queuedMergedTasks count] > 0 ) {
            FlyImageDownloaderMergedTask *mergedTask = [self dequeueMergedTask];
            [self startMergedTask:mergedTask];
        }
    });
}

@end
