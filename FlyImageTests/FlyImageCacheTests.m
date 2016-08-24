//
//  FlyImageCacheTests.m
//  Demo
//
//  Created by Norris Tong on 4/3/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FlyImageCache.h"
#import "FlyImageDataFIleManager.h"

@interface FlyImageCacheTests : XCTestCase

@end

static FlyImageCache* _imageCache;
static CGFloat imageWidth = 1920.0;
static CGFloat imageHeight = 1200.0;
static FlyImageDataFileManager* _fileManager;
static int kMultipleTimes = 15;

@implementation FlyImageCacheTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    if (_imageCache == nil) {
        _imageCache = [FlyImageCache sharedInstance];
        _fileManager = [_imageCache valueForKey:@"dataFileManager"];
    }
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)addImageFile:(NSString*)name
{
    // generate an image with special size
    CGRect rect = CGRectMake(0.0f, 0.0f, imageWidth, imageHeight);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    NSData* imageData = UIImagePNGRepresentation(image);
    NSString* directoryPath = [_fileManager folderPath];
    NSString* imagePath = [directoryPath stringByAppendingPathComponent:name];
    [imageData writeToFile:imagePath atomically:YES];

    [_fileManager addExistFileName:name];
}

- (void)drawALineInContext:(CGContextRef)context rect:(CGRect)rect
{
    UIGraphicsPushContext(context);

    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetLineWidth(context, 10.0);
    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);

    UIGraphicsPopContext();
}

- (void)test10AddImage
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test10AddImage"];

    NSString* filename = @"10";
    [self addImageFile:filename];

    [_imageCache addImageWithKey:filename
                        filename:filename
                       completed:^(NSString* key, UIImage* image) {
                           XCTAssert( image.size.width == imageWidth );
                           XCTAssert( image.size.height == imageHeight );
                           
                           [expectation fulfill];
                       }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test11AddMultipleTimes
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test11AddMultipleTimes"];

    NSString* filename = @"11";
    [self addImageFile:filename];

    __block int sum = 0;
    for (int i = 0; i < kMultipleTimes; i++) {

        [_imageCache addImageWithKey:filename
                            filename:filename
                           completed:^(NSString* key, UIImage* image) {
                               XCTAssert( image.size.width == imageWidth );
                               XCTAssert( image.size.height == imageHeight );
                               
                               sum++;
                               if ( sum == kMultipleTimes ){
                                   [expectation fulfill];
                               }
                           }];
    }

    [self waitForExpectationsWithTimeout:30 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test13AddMultipleKeys
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test13AddMultipleKeys"];

    __block int sum = 0;
    for (int i = 1; i <= kMultipleTimes; i++) {

        NSString* filename = [NSString stringWithFormat:@"%d", i];
        [self addImageFile:filename];

        [_imageCache addImageWithKey:filename
                            filename:filename
                           completed:^(NSString* key, UIImage* image) {
                               XCTAssert( image.size.width == imageWidth );
                               XCTAssert( image.size.height == imageHeight );
                               
                               sum++;
                               if ( sum == kMultipleTimes ){
                                   [expectation fulfill];
                               }
                           }];
    }

    [self waitForExpectationsWithTimeout:100 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test30AsyncGetImage
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test30AsyncGetImage"];

    [_imageCache asyncGetImageWithKey:@"10"
                            completed:^(NSString* key, UIImage* image) {
        XCTAssert( image.size.width == imageWidth );
        XCTAssert( image.size.height == imageHeight );
        
        [expectation fulfill];
                            }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test30AsyncGetImageMultipleTimes
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test30AsyncGetImageMultipleTimes"];

    NSString* filename = @"10";

    __block int sum = 0;
    for (int i = 0; i < kMultipleTimes; i++) {
        [_imageCache asyncGetImageWithKey:filename
                                 drawSize:CGSizeMake(500, 800)
                          contentsGravity:kCAGravityResizeAspect
                             cornerRadius:0
                                completed:^(NSString* key, UIImage* image) {
                               XCTAssert( image.size.width == 500 );
                               XCTAssert( image.size.height == 800 );
                               
                               sum++;
                               if ( sum == kMultipleTimes ){
                                   [expectation fulfill];
                               }
                                }];
    }

    [self waitForExpectationsWithTimeout:30 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test50RemoveImage
{
    NSString* imageKey = @"11";
    [_imageCache removeImageWithKey:imageKey];
    XCTAssert(![_imageCache isImageExistWithKey:imageKey]);
}

- (void)test60ImagePath
{
    XCTAssert([_imageCache imagePathWithKey:@"10"] != nil);
    XCTAssert([_imageCache imagePathWithKey:@"11"] == nil);
}

- (void)test80ChangeImageKey
{
    XCTestExpectation* expectation = [self expectationWithDescription:@"test80ChangeImageKey"];

    [_imageCache changeImageKey:@"10" newKey:@"newKey"];
    XCTAssert(![_imageCache isImageExistWithKey:@"10"]);
    XCTAssert([_imageCache isImageExistWithKey:@"newKey"]);

    [_imageCache asyncGetImageWithKey:@"newKey" completed:^(NSString* key, UIImage* image) {
        XCTAssert( image.size.width == imageWidth );
        XCTAssert( image.size.height == imageHeight );
        
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test90Purge
{
    [_imageCache purge];
    XCTAssert(![_imageCache isImageExistWithKey:@"10"]);
}

@end
