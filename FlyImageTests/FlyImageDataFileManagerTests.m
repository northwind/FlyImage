//
//  FlyImageDataFileManagerTests.m
//  Demo
//
//  Created by Norris Tong on 4/2/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FlyImageDataFileManager.h"

@interface FlyImageDataFileManagerTests : XCTestCase

@end

static FlyImageDataFileManager* _fileManager;

@implementation FlyImageDataFileManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // Put setup code here. This method is called before the invocation of each test method in the class.
    if (_fileManager == nil) {
        NSString* directoryPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
        NSString* folderPath = [directoryPath stringByAppendingPathComponent:@"flyimage2/files"];

        _fileManager = [[FlyImageDataFileManager alloc] initWithFolderPath:folderPath];
    }
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test10Create
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test10Create"];

    [_fileManager asyncCreateFileWithName:@"10" completed:^(FlyImageDataFile* dataFile) {
        XCTAssert( dataFile != nil );
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test11CreateMultipleTimes
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test11CreateMultipleTimes"];

    __block int sum = 0;
    for (int i = 0; i < 100; i++) {
        [_fileManager asyncCreateFileWithName:@"11" completed:^(FlyImageDataFile* dataFile) {
            XCTAssert( dataFile != nil );
            
            sum++;
            if ( sum == 100 ){
                [expectation fulfill];
            }
        }];
    }

    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test12CreateSameName
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test12CreateSameName"];

    [_fileManager asyncCreateFileWithName:@"10" completed:^(FlyImageDataFile* dataFile) {
        XCTAssert( dataFile != nil );
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test13CreateMultipleNames
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test13CreateMultipleNames"];

    __block int sum = 0;
    for (int i = 1; i <= 100; i++) {
        [_fileManager asyncCreateFileWithName:[NSString stringWithFormat:@"%d", i] completed:^(FlyImageDataFile* dataFile) {
            XCTAssert( dataFile != nil );
            
            sum++;
            if ( sum == 100 ){
                [expectation fulfill];
            }
        }];
    }

    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test15SyncCreate
{
    id dataFile = [_fileManager createFileWithName:@"100"];
    XCTAssert(dataFile != nil);
}

- (void)test20IsExist
{
    XCTAssert([_fileManager isFileExistWithName:@"10"]);
    XCTAssert([_fileManager isFileExistWithName:@"11"]);

    XCTAssert(![_fileManager isFileExistWithName:@"NotExist"]);
}

- (void)test30Retrieve
{
    FlyImageDataFile* file10 = [_fileManager retrieveFileWithName:@"10"];
    XCTAssert(file10 != nil);

    FlyImageDataFile* file11 = [_fileManager retrieveFileWithName:@"11"];
    XCTAssert(file11 != nil);

    FlyImageDataFile* fileNotExist = [_fileManager retrieveFileWithName:@"NotExist"];
    XCTAssert(fileNotExist == nil);
}

- (void)test50Remove
{
    [_fileManager removeFileWithName:@"10"];

    XCTAssert(![_fileManager isFileExistWithName:@"10"]);
}

- (void)test90Purge
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test90Purge"];

    [_fileManager purgeWithExceptions:@[ @"11", @"10" ] toSize:0 completed:^(NSUInteger fileCount, NSUInteger totalSize) {
        XCTAssert( fileCount > 0 );
        XCTAssert( totalSize > 0 );
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test99PurgeAll
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test99PurgeAll"];

    [_fileManager purgeWithExceptions:nil toSize:0 completed:^(NSUInteger fileCount, NSUInteger totalSize) {
        XCTAssert( fileCount == 0 );
        XCTAssert( totalSize == 0 );
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:1000 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

@end
