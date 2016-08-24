//
//  FlyImageDownloaderTests.m
//  Demo
//
//  Created by Norris Tong on 4/4/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FlyImageDownloader.h"

@interface DownloadManagerClient : NSObject <FlyImageDownloaderDelegate>
@property (nonatomic, strong) XCTestExpectation* expectation;
@end

static const NSString* kAssetHost = @"https://flyimage.oss-us-west-1.aliyuncs.com/";
static int kMultipleTimes = 15;

@implementation DownloadManagerClient
- (void)FlyImageDownloader:(FlyImageDownloader*)manager
           willSendRequest:(NSURLRequest*)request
{
    NSAssert(request != nil, nil);
}

- (void)FlyImageDownloader:(FlyImageDownloader*)manager
        didReceiveResponse:(NSURLResponse*)response
                  filePath:(NSURL*)filePath
                     error:(NSError*)error
                   request:(NSURLRequest*)request
{
    NSAssert(request != nil, nil);

    [self.expectation fulfill];
}

- (void)FlyImageDownloader:(FlyImageDownloader*)manager
         willCancelRequest:(NSURLRequest*)request
{
    NSAssert(request != nil, nil);

    [self.expectation fulfill];
}
@end

@interface FlyImageDownloaderTests : XCTestCase

@end

static FlyImageDownloader* _downloadManager;

@implementation FlyImageDownloaderTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    if (_downloadManager == nil) {
        _downloadManager = [FlyImageDownloader sharedInstance];
    }
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];

    _downloadManager.delegate = nil;
}

- (void)test10Success
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test10AddImage"];
    NSString* imagePath = [kAssetHost stringByAppendingPathComponent:@"10.jpg"];

    NSURL* url = [NSURL URLWithString:imagePath];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30;
    [_downloadManager downloadImageForURLRequest:request progress:^(float percentage) {
        XCTAssert( percentage >= 0 && percentage <= 1 );
    } success:^(NSURLRequest* request, NSURL* filePath) {
        
        NSData *data = [[NSData alloc] initWithContentsOfURL:filePath];
        UIImage *image = [UIImage imageWithData:data];
        XCTAssert( image.size.width == 1024 );
        
        [expectation fulfill];

    } failed:^(NSURLRequest* request, NSError* error) {
        XCTAssert( NO );
        
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test30Failed
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test30Failed"];
    NSString* imagePath = [kAssetHost stringByAppendingPathComponent:@"xxx"];

    NSURL* url = [NSURL URLWithString:imagePath];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30;
    [_downloadManager downloadImageForURLRequest:request progress:nil success:^(NSURLRequest* request, NSURL* filePath) {
        XCTAssert( NO );
        
        [expectation fulfill];

    } failed:^(NSURLRequest* request, NSError* error) {
        XCTAssert( error != nil );
        
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:60 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test31FailedMultiple
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test31FailedMultiple"];
    NSString* imagePath = [kAssetHost stringByAppendingPathComponent:@"xxx"];

    __block int sum = 0;
    for (int i = 0; i < kMultipleTimes; i++) {
        NSURL* url = [NSURL URLWithString:imagePath];
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
        request.timeoutInterval = 5;
        [_downloadManager downloadImageForURLRequest:request progress:nil success:^(NSURLRequest* request, NSURL* filePath) {
            XCTAssert( NO );
        } failed:^(NSURLRequest* request, NSError* error) {
            XCTAssert( error != nil );
            
            sum++;
            if ( sum == kMultipleTimes ){
                [expectation fulfill];
            }
        }];
    }

    [self waitForExpectationsWithTimeout:60 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test50CancelTask
{

    XCTestExpectation* expectation = [self expectationWithDescription:@"test90Cancel"];
    NSString* imagePath = [kAssetHost stringByAppendingPathComponent:@"11.jpg"];

    NSURL* url = [NSURL URLWithString:imagePath];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
    FlyImageDownloadHandlerId* handlerId = [_downloadManager downloadImageForURLRequest:request
        progress:nil
        success:^(NSURLRequest* request, NSURL* filePath) {
        XCTAssert( NO );
        [expectation fulfill];
        }
        failed:^(NSURLRequest* request, NSError* error) {
        XCTAssert( error != nil );
        [expectation fulfill];
        }];

    [_downloadManager cancelDownloadHandler:handlerId];

    [self waitForExpectationsWithTimeout:60 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test51CancelHandler
{

    XCTestExpectation* expectation = [self expectationWithDescription:@"test91CancelMultipleTimes"];
    NSString* imagePath = [kAssetHost stringByAppendingPathComponent:@"12.jpg"];

    NSURL* url = [NSURL URLWithString:imagePath];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
    FlyImageDownloadHandlerId* handlerId = [_downloadManager downloadImageForURLRequest:request
        progress:nil
        success:^(NSURLRequest* request, NSURL* filePath) {
                                                                                    XCTAssert( NO );
																					[expectation fulfill];
        }
        failed:^(NSURLRequest* request, NSError* error) {
																					XCTAssert( error != nil );
																					[expectation fulfill];
        }];

    for (int i = 0; i < kMultipleTimes; i++) {
        [_downloadManager downloadImageForURLRequest:request
            progress:nil
            success:^(NSURLRequest* request, NSURL* filePath) {
												 XCTAssert( NO );
												 [expectation fulfill];
            }
            failed:^(NSURLRequest* request, NSError* error) {
                                                 XCTAssert( NO );
                                                 [expectation fulfill];
            }];
    }

    [_downloadManager cancelDownloadHandler:handlerId];

    [self waitForExpectationsWithTimeout:60 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test90DelegateSend
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test50Delegate"];

    DownloadManagerClient* client = [[DownloadManagerClient alloc] init];
    client.expectation = expectation;
    _downloadManager.delegate = client;

    NSString* imagePath = [kAssetHost stringByAppendingPathComponent:@"13.jpg"];
    NSURL* url = [NSURL URLWithString:imagePath];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
    [_downloadManager downloadImageForURLRequest:request];

    [self waitForExpectationsWithTimeout:60 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test91DelegateCancel
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test50Delegate"];

    DownloadManagerClient* client = [[DownloadManagerClient alloc] init];
    client.expectation = expectation;
    _downloadManager.delegate = client;

    NSString* imagePath = [kAssetHost stringByAppendingPathComponent:@"14.jpg"];
    NSURL* url = [NSURL URLWithString:imagePath];
    NSURLRequest* request = [[NSURLRequest alloc] initWithURL:url];
    FlyImageDownloadHandlerId* handlerId = [_downloadManager downloadImageForURLRequest:request];
    [_downloadManager cancelDownloadHandler:handlerId];

    [self waitForExpectationsWithTimeout:60 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

@end
