//
//  FlyImageIconCache.m
//  Demo
//
//  Created by Norris Tong on 4/2/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "FlyImageIconCache.h"
#import "FlyImageDataFileManager.h"
#import "FlyImageUtils.h"
#import "FlyImageEncoder.h"
#import "FlyImageDecoder.h"
#import "FlyImageRetrieveOperation.h"

static NSString* kFlyImageKeyVersion = @"v";
static NSString* kFlyImageKeyFile = @"f";
static NSString* kFlyImageKeyImages = @"i";
static NSString* kFlyImageKeyFilePointer = @"p";

#define kImageInfoIndexWidth 0
#define kImageInfoIndexHeight 1
#define kImageInfoIndexOffset 2
#define kImageInfoIndexLength 3
#define kImageInfoCount 4

@interface FlyImageIconCache ()
@property (nonatomic, strong) FlyImageEncoder* encoder;
@property (nonatomic, strong) FlyImageDecoder* decoder;
@property (nonatomic, strong) FlyImageDataFile* dataFile;
@property (nonatomic, strong) FlyImageDataFileManager* dataFileManager;
@end

@implementation FlyImageIconCache {
    NSRecursiveLock* _lock;
    NSString* _metaPath;

    NSMutableDictionary* _metas;
    NSMutableDictionary* _images;
    NSMutableDictionary* _addingImages;
    NSOperationQueue* _retrievingQueue;
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static FlyImageIconCache* __instance = nil;
    dispatch_once(&onceToken, ^{
		NSString *metaPath = [[FlyImageUtils directoryPath] stringByAppendingPathComponent:@"/__icons"];
        __instance = [[[self class] alloc] initWithMetaPath:metaPath];
    });

    return __instance;
}

- (instancetype)initWithMetaPath:(NSString*)metaPath
{
    if (self = [self init]) {

        _lock = [[NSRecursiveLock alloc] init];
        _addingImages = [[NSMutableDictionary alloc] init];
        _retrievingQueue = [NSOperationQueue new];
        _retrievingQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        _retrievingQueue.maxConcurrentOperationCount = 6;

        _metaPath = [metaPath copy];
        NSString* folderPath = [[_metaPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"/files"];
        self.dataFileManager = [[FlyImageDataFileManager alloc] initWithFolderPath:folderPath];
        [self loadMetadata];

        _decoder = [[FlyImageDecoder alloc] init];
        _encoder = [[FlyImageEncoder alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillTerminate)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - LifeCircle
- (void)onWillTerminate
{
    // 取消内存映射
    _dataFile = nil;
    [_retrievingQueue cancelAllOperations];
}

- (void)dealloc
{
    _dataFile = nil;
    [_retrievingQueue cancelAllOperations];
}

#pragma mark - APIs
- (void)addImageWithKey:(NSString*)key
                   size:(CGSize)size
           drawingBlock:(FlyImageCacheDrawingBlock)drawingBlock
              completed:(FlyImageCacheRetrieveBlock)completed
{

    NSParameterAssert(key != nil);
    NSParameterAssert(drawingBlock != nil);

    if ([self isImageExistWithKey:key]) {
        [self asyncGetImageWithKey:key completed:completed];
        return;
    }

    size_t bytesToAppend = [FlyImageEncoder dataLengthWithImageSize:size];
    [self doAddImageWithKey:key
                       size:size
                     offset:-1
                     length:bytesToAppend
               drawingBlock:drawingBlock
                  completed:completed];
}

- (void)doAddImageWithKey:(NSString*)key
                     size:(CGSize)size
                   offset:(size_t)offset
                   length:(size_t)length
             drawingBlock:(FlyImageCacheDrawingBlock)drawingBlock
                completed:(FlyImageCacheRetrieveBlock)completed
{

    NSParameterAssert(completed != nil);

    if (_dataFile == nil) {
        if (completed != nil) {
            completed(key, nil);
        }
        return;
    }

    if (completed != nil) {
        @synchronized(_addingImages)
        {
            if ([_addingImages objectForKey:key] == nil) {
                [_addingImages setObject:[NSMutableArray arrayWithObject:completed] forKey:key];
            } else {
                NSMutableArray* blocks = [_addingImages objectForKey:key];
                [blocks addObject:completed];
                return;
            }
        }
    }

    static dispatch_queue_t __drawingQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		NSString *name = [NSString stringWithFormat:@"com.flyimage.drawicon.%@", [[NSUUID UUID] UUIDString]];
        __drawingQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    });

    // 使用dispatch_sync 代替 dispatch_async，防止大规模写入时出现异常
    dispatch_async(__drawingQueue, ^{
		
		size_t newOffset = offset == -1 ? (size_t)_dataFile.pointer : offset;
        if ( ![_dataFile prepareAppendDataWithOffset:newOffset length:length] ) {
            [self afterAddImage:nil key:key];
            return;
        }
        
        [_encoder encodeWithImageSize:size bytes:_dataFile.address + newOffset drawingBlock:drawingBlock];
        
        BOOL success = [_dataFile appendDataWithOffset:newOffset length:length];
        if ( !success ) {
            // TODO: consider rollback
            [self afterAddImage:nil key:key];
            return;
        }
        
        // number of dataFile, width of image, height of image, offset, length
        @synchronized (_images) {
            NSArray *imageInfo = @[ @(size.width),
                                    @(size.height),
                                    @(newOffset),
                                    @(length) ];
            
            [_images setObject:imageInfo forKey:key];
        }
        
        // callback with image
        UIImage *image = [_decoder iconImageWithBytes:_dataFile.address
                                                 offset:newOffset
                                                 length:length
											   drawSize:size];
        [self afterAddImage:image key:key];
        
        // save meta
        [self saveMetadata];
    });
}

- (void)afterAddImage:(UIImage*)image key:(NSString*)key
{
    NSArray* blocks = nil;
    @synchronized(_addingImages)
    {
        blocks = [[_addingImages objectForKey:key] copy];
        [_addingImages removeObjectForKey:key];
    }

    dispatch_main_sync_safe(^{
        for ( FlyImageCacheRetrieveBlock block in blocks) {
            block( key, image );
        }
    });
}

- (void)replaceImageWithKey:(NSString*)key
               drawingBlock:(FlyImageCacheDrawingBlock)drawingBlock
                  completed:(FlyImageCacheRetrieveBlock)completed
{

    NSParameterAssert(key != nil);
    NSParameterAssert(drawingBlock != nil);

    id imageInfo = nil;
    @synchronized(_images)
    {
        imageInfo = _images[key];
    }
    if (imageInfo == nil) {
        if (completed != nil) {
            completed(key, nil);
        }
        return;
    }

    // width of image, height of image, offset, length
    CGFloat imageWidth = [[imageInfo objectAtIndex:kImageInfoIndexWidth] floatValue];
    CGFloat imageHeight = [[imageInfo objectAtIndex:kImageInfoIndexHeight] floatValue];
    size_t imageOffset = [[imageInfo objectAtIndex:kImageInfoIndexOffset] unsignedLongValue];
    size_t imageLength = [[imageInfo objectAtIndex:kImageInfoIndexLength] unsignedLongValue];

    CGSize size = CGSizeMake(imageWidth, imageHeight);
    [self doAddImageWithKey:key
                       size:size
                     offset:imageOffset
                     length:imageLength
               drawingBlock:drawingBlock
                  completed:completed];
}

- (void)removeImageWithKey:(NSString*)key
{
    @synchronized(_images)
    {
        [_images removeObjectForKey:key];
    }
}

- (void)changeImageKey:(NSString*)oldKey newKey:(NSString*)newKey
{
    @synchronized(_images)
    {

        id imageInfo = [_images objectForKey:oldKey];
        if (imageInfo == nil) {
            return;
        }

        [_images setObject:imageInfo forKey:newKey];
        [_images removeObjectForKey:oldKey];
    }
}

- (BOOL)isImageExistWithKey:(NSString*)key
{
    @synchronized(_images)
    {
        return [_images objectForKey:key] != nil;
    }
}

- (void)asyncGetImageWithKey:(NSString*)key completed:(FlyImageCacheRetrieveBlock)completed
{
    NSParameterAssert(key != nil);
    NSParameterAssert(completed != nil);

    if (_dataFile == nil) {
        completed(key, nil);
        return;
    }

    NSArray* imageInfo;
    @synchronized(_images)
    {
        imageInfo = _images[key];
    }

    if (imageInfo == nil || [imageInfo count] < kImageInfoCount) {
        completed(key, nil);
        return;
    }

    // width of image, height of image, offset, length
    CGFloat imageWidth = [[imageInfo objectAtIndex:kImageInfoIndexWidth] floatValue];
    CGFloat imageHeight = [[imageInfo objectAtIndex:kImageInfoIndexHeight] floatValue];
    size_t imageOffset = [[imageInfo objectAtIndex:kImageInfoIndexOffset] unsignedLongValue];
    size_t imageLength = [[imageInfo objectAtIndex:kImageInfoIndexLength] unsignedLongValue];

    __weak __typeof__(self) weakSelf = self;
    FlyImageRetrieveOperation* operation = [[FlyImageRetrieveOperation alloc] initWithRetrieveBlock:^UIImage * {
		return [weakSelf.decoder iconImageWithBytes:weakSelf.dataFile.address
									 offset:imageOffset
									 length:imageLength
								   drawSize:CGSizeMake(imageWidth, imageHeight)];

    }];
    operation.name = key;
    [operation addBlock:completed];
    [_retrievingQueue addOperation:operation];
}

- (void)cancelGetImageWithKey:(NSString*)key
{
    NSParameterAssert(key != nil);

    for (FlyImageRetrieveOperation* operation in _retrievingQueue.operations) {
        if (!operation.cancelled && !operation.finished && [operation.name isEqualToString:key]) {
            [operation cancel];
            return;
        }
    }
}

- (void)purge
{
    [self removeImages];

    _dataFile = nil;
    NSString* fileName = [_metas objectForKey:kFlyImageKeyFile];
    if (fileName != nil) {
        [self.dataFileManager removeFileWithName:fileName];
        [self createDataFile:fileName];
    }

    [self saveMetadata];
}

- (void)removeImages
{
    @synchronized(_images)
    {
        [_images removeAllObjects];
    }

    [_retrievingQueue cancelAllOperations];

    @synchronized(_addingImages)
    {
        for (NSString* key in _addingImages) {
            NSArray* blocks = [_addingImages objectForKey:key];
            dispatch_main_sync_safe(^{
                for ( FlyImageCacheRetrieveBlock block in blocks) {
                    block( key, nil );
                }
            });
        }

        [_addingImages removeAllObjects];
    }
}

#pragma mark - Working with Metadata
- (void)saveMetadata
{
    static dispatch_queue_t __metadataQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
		NSString *name = [NSString stringWithFormat:@"com.flyimage.iconmeta.%@", [[NSUUID UUID] UUIDString]];
        __metadataQueue = dispatch_queue_create([name cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    });

    dispatch_async(__metadataQueue, ^{
        [_lock lock];
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:[_metas copy] options:kNilOptions error:NULL];
        BOOL fileWriteResult = [data writeToFile:_metaPath atomically:NO];
        if (fileWriteResult == NO) {
            FlyImageErrorLog(@"couldn't save metadata");
        }
        
        [_lock unlock];
    });
}

- (void)loadMetadata
{
    // load content from index file
    NSError* error;
    NSData* metadataData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:_metaPath] options:NSDataReadingMappedAlways error:&error];
    if (error != nil || metadataData == nil) {
        [self createMetadata];
        return;
    }

    NSDictionary* parsedObject = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:metadataData options:kNilOptions error:&error];
    if (error != nil || parsedObject == nil) {
        [self createMetadata];
        return;
    }

    // 客户端升级后，图标极有可能发生变化，为了适应这种变化，自动清理本地缓存，所有图标都重新生成
    NSString* lastVersion = [parsedObject objectForKey:kFlyImageKeyVersion];
    NSString* currentVersion = [FlyImageUtils clientVersion];
    if (lastVersion != nil && ![lastVersion isEqualToString:currentVersion]) {
        [self purge];
        [self createMetadata];
        return;
    }

    // load infos
    _metas = [NSMutableDictionary dictionaryWithDictionary:parsedObject];

    _images = [NSMutableDictionary dictionaryWithDictionary:[_metas objectForKey:kFlyImageKeyImages]];
    [_metas setObject:_images forKey:kFlyImageKeyImages];

    NSString* fileName = [_metas objectForKey:kFlyImageKeyFile];
    [self createDataFile:fileName];
}

- (void)createMetadata
{
    _metas = [NSMutableDictionary dictionaryWithCapacity:100];

    // 记录当前版本号
    NSString* currentVersion = [FlyImageUtils clientVersion];
    if (currentVersion != nil) {
        [_metas setObject:currentVersion forKey:kFlyImageKeyVersion];
    }

    // images
    _images = [NSMutableDictionary dictionary];
    [_metas setObject:_images forKey:kFlyImageKeyImages];

    // file
    NSString* fileName = [[NSUUID UUID] UUIDString];
    [_metas setObject:fileName forKey:kFlyImageKeyFile];

    [self createDataFile:fileName];
}

- (void)createDataFile:(NSString*)fileName
{
    _dataFile = [self.dataFileManager createFileWithName:fileName];
    _dataFile.step = [FlyImageUtils pageSize] * 128; // 512KB
    [_dataFile open];
}

@end
