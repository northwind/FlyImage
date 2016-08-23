//
//  FlyImageDataFileManager.m
//  Demo
//
//  Created by Ye Tong on 3/22/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import "FlyImageDataFileManager.h"
#import "FlyImageUtils.h"

@implementation FlyImageDataFileManager {
    NSFileManager* _fileManager;
    dispatch_queue_t _fileQueue;
    NSMutableDictionary* _fileNames;
    NSMutableDictionary* _creatingFiles;
}

- (instancetype)initWithFolderPath:(NSString*)folderPath
{
    if (self = [self init]) {
        _folderPath = [folderPath copy];

        // create a unique queue
        NSString* queueName = [@"com.flyimage.filemanager." stringByAppendingString:[[NSUUID UUID] UUIDString]];
        _fileQueue = dispatch_queue_create([queueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);

        dispatch_sync(_fileQueue, ^{
            _fileManager = [NSFileManager new];
            
            [self makeDirectory];
            [self listDirectory];
            [self checkDiskStatus];
        });
    }
    return self;
}

- (void)makeDirectory
{
    BOOL isFolderExist = [_fileManager fileExistsAtPath:_folderPath];
    if (!isFolderExist) {
        [_fileManager createDirectoryAtPath:_folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (void)listDirectory
{
    _creatingFiles = [[NSMutableDictionary alloc] init];

    NSArray* filenames = [_fileManager contentsOfDirectoryAtPath:_folderPath error:nil];
    _fileNames = [[NSMutableDictionary alloc] initWithCapacity:[filenames count]];
    for (NSString* filename in filenames) {
        [_fileNames setObject:@(1) forKey:filename];
    }
}

// Execute in the _fileQueue
- (void)checkDiskStatus
{
    NSDictionary* fileAttributes = [_fileManager attributesOfFileSystemForPath:@"/" error:nil];
    unsigned long long freeSize = [[fileAttributes objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];

    // set disk is full when free size is less than 20Mb
    _isDiskFull = freeSize < 1024 * 1024 * 20;
}

- (void)asyncCreateFileWithName:(NSString*)name completed:(void (^)(FlyImageDataFile* dataFile))completed
{
    NSParameterAssert(name);
    NSParameterAssert(completed);

    // already exist
    NSString* filePath = [_folderPath stringByAppendingPathComponent:name];
    if ([self isFileExistWithName:name]) {
        FlyImageDataFile* file = [[FlyImageDataFile alloc] initWithPath:filePath];
        completed(file);
        return;
    }

    // can't add more
    if (_isDiskFull) {
        completed(nil);
        return;
    }

    // save all the blocks into _creatingFiles, waiting for callback
    @synchronized(_creatingFiles)
    {
        if ([_creatingFiles objectForKey:name] == nil) {
            [_creatingFiles setObject:[NSMutableArray arrayWithObject:completed] forKey:name];
        } else {
            NSMutableArray* blocks = [_creatingFiles objectForKey:name];
            [blocks addObject:completed];
        }
    }

    dispatch_async(_fileQueue, ^{
        
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        [attributes setValue:NSFileProtectionCompleteUnlessOpen forKeyPath:NSFileProtectionKey];
        
        BOOL success = [_fileManager createFileAtPath:filePath contents:nil attributes:attributes];
        if ( !success ) {
            FlyImageErrorLog(@"can't create file at path %@", filePath);
            
			// check if the disk is full
            [self checkDiskStatus];
            
            [self afterCreateFile:nil name:name];
            return;
        }
        
        // update index
        @synchronized (_fileNames) {
            [_fileNames setObject:@(1) forKey:name];
        }
        
        FlyImageDataFile *file = [[FlyImageDataFile alloc] initWithPath:filePath];
        [self afterCreateFile:file name:name];
    });
}

- (void)afterCreateFile:(FlyImageDataFile*)file name:(NSString*)name
{

    NSArray* blocks = nil;
    @synchronized(_creatingFiles)
    {
        blocks = [[_creatingFiles objectForKey:name] copy];
        [_creatingFiles removeObjectForKey:name];
    }

    dispatch_main_sync_safe(^{
        for (  void (^block)(FlyImageDataFile *dataFile) in blocks) {
            block( file );
        }
    });
}

- (void)addExistFileName:(NSString*)name
{
    NSParameterAssert(name);

    @synchronized(_fileNames)
    {
        [_fileNames setObject:@(1) forKey:name];
    }
}

- (FlyImageDataFile*)createFileWithName:(NSString*)name
{
    NSParameterAssert(name);

    // already exist
    NSString* filePath = [_folderPath stringByAppendingPathComponent:name];
    if ([self isFileExistWithName:name]) {
        return [[FlyImageDataFile alloc] initWithPath:filePath];
    }

    // can't add more
    if (_isDiskFull) {
        return nil;
    }

    NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
    [attributes setValue:NSFileProtectionCompleteUnlessOpen forKeyPath:NSFileProtectionKey];

    BOOL success = [_fileManager createFileAtPath:filePath contents:nil attributes:attributes];
    if (!success) {
        FlyImageErrorLog(@"can't create file at path %@", filePath);

        // check if the disk is full
        [self checkDiskStatus];

        return nil;
    }

    // update index
    @synchronized(_fileNames)
    {
        [_fileNames setObject:@(1) forKey:name];
    }

    return [[FlyImageDataFile alloc] initWithPath:filePath];
}

- (BOOL)isFileExistWithName:(NSString*)name
{
    NSParameterAssert(name);

    return [_fileNames objectForKey:name] != nil;
}

- (FlyImageDataFile*)retrieveFileWithName:(NSString*)name
{
    NSParameterAssert(name);

    if (![self isFileExistWithName:name]) {
        return nil;
    }

    NSString* filePath = [_folderPath stringByAppendingPathComponent:name];
    FlyImageDataFile* file = [[FlyImageDataFile alloc] initWithPath:filePath];

    return file;
}

- (void)removeFileWithName:(NSString*)name
{
    NSParameterAssert(name);

    if (![self isFileExistWithName:name]) {
        return;
    }

    // remove from the indexes first
    @synchronized(_fileNames)
    {
        [_fileNames removeObjectForKey:name];
    }

    // delete file
    dispatch_async(_fileQueue, ^{
        [_fileManager removeItemAtPath:[_folderPath stringByAppendingPathComponent:name] error:nil];
        
        [self checkDiskStatus];
    });
}

- (void)purgeWithExceptions:(NSArray*)names
                     toSize:(NSUInteger)toSize
                  completed:(void (^)(NSUInteger fileCount, NSUInteger totalSize))completed
{
    dispatch_async(_fileQueue, ^{
        
        // from array to dictionary
        NSMutableDictionary *exceptions = [[NSMutableDictionary alloc] initWithCapacity:[names count]];
        for (NSString *name in names) {
            [exceptions setObject:@(1) forKey:name];
        }
        
        NSUInteger totalSize = (NSUInteger)[[_fileManager attributesOfItemAtPath:_folderPath error:nil] fileSize];
        
        NSURL *folderURL = [NSURL fileURLWithPath:_folderPath isDirectory:YES];
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLNameKey, NSURLTotalFileAllocatedSizeKey];
        
        // This enumerator prefetches useful properties for our cache files.
        NSDirectoryEnumerator *enumerator = [_fileManager enumeratorAtURL:folderURL
                                               includingPropertiesForKeys:resourceKeys
                                                                  options:NSDirectoryEnumerationSkipsHiddenFiles
                                                             errorHandler:NULL];
        
        // TODO SORT
        NSMutableArray *urlsToDelete = [[NSMutableArray alloc] init];
        NSMutableArray *namesToDelete = [[NSMutableArray alloc] init];
        for (NSURL *fileURL in enumerator) {
            NSNumber *isDirectory;
            [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:nil];
            
            if ([isDirectory boolValue]) {
                continue;
            }
            
            NSString *fileName;
            [fileURL getResourceValue:&fileName forKey:NSURLNameKey error:nil];
            
            // dont remove file in exceptions
            if ( [exceptions objectForKey:fileName] != nil ) {
                continue;
            }
            
            NSNumber *fileSize;
            [fileURL getResourceValue:&fileSize forKey:NSURLTotalFileAllocatedSizeKey error:nil];
            
            // dont remove more files
            totalSize -= [fileSize unsignedLongValue];
            if ( totalSize <= toSize ) {
                break;
            }
            
            [urlsToDelete addObject:fileURL];
            [namesToDelete addObject:fileName];
        }
        
        // remove file and index
        for (NSURL *fileURL in urlsToDelete) {
            [_fileManager removeItemAtURL:fileURL error:nil];
        }
        @synchronized (_fileNames) {
            for (NSString *fileName in namesToDelete) {
                [_fileNames removeObjectForKey:fileName];
            }
        }
        
        [self checkDiskStatus];
        
        if ( completed != nil ) {
            NSUInteger fileCount = [_fileNames count];
            completed( fileCount, fileCount == 0 ? 0 : totalSize );
        }
    });
}

- (void)calculateSizeWithCompletionBlock:(void (^)(NSUInteger fileCount, NSUInteger totalSize))block
{
    NSParameterAssert(block);

    dispatch_async(_fileQueue, ^{
        // dont count self folder
        NSUInteger fileCount = MAX(0, [[[_fileManager enumeratorAtPath:_folderPath] allObjects] count] - 1);
        NSUInteger totalSize = (NSUInteger)[[_fileManager attributesOfItemAtPath:_folderPath error:nil] fileSize];
        
        dispatch_main_async_safe(^{
            block( fileCount, fileCount == 0 ? 0 : totalSize );
        });
    });
}

- (void)freeDiskSpaceWithCompletionBlock:(void (^)(NSUInteger freeSize))block
{
    NSParameterAssert(block);

    dispatch_async(_fileQueue, ^{
        NSDictionary *fileAttributes = [_fileManager attributesOfFileSystemForPath:@"/" error:nil];
        NSUInteger freeSize = (NSUInteger)[[fileAttributes objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
        
        dispatch_main_async_safe(^{
            block( freeSize );
        });
    });
}

@end
