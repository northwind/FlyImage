//
//  FlyImageIconCacheTests.m
//  Demo
//
//  Created by Norris Tong on 4/3/16.
//  Copyright © 2016 NorrisTong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FlyImageIconCache.h"

@interface FlyImageIconCacheTests : XCTestCase

@end

static FlyImageIconCache *_iconCache;

#define kImageWidth		30
#define kImageHeight	40

@implementation FlyImageIconCacheTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    if ( _iconCache == nil ) {
        _iconCache = [FlyImageIconCache sharedInstance];
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)drawALineInContext:(CGContextRef)context rect:(CGRect)rect {
    UIGraphicsPushContext(context);
    
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetLineWidth(context, 10.0);
    CGContextMoveToPoint(context, 0.0, 0.0);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    
    UIGraphicsPopContext();
}

- (void)test10AddImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test10AddImage"];

    [_iconCache addImageWithKey:@"10"
                           size:CGSizeMake(kImageWidth, kImageHeight)
                   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
                       [self drawALineInContext:context rect:contextBounds];
    } completed:^(NSString *key, UIImage *image) {
        XCTAssert( image.size.width == kImageWidth );
        XCTAssert( image.size.height == kImageHeight );
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test11AddMultipleTimes {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test11AddMultipleTimes"];
    
    __block int sum = 0;
    for (int i=0; i<100; i++) {
        [_iconCache addImageWithKey:@"11"
                               size:CGSizeMake(kImageWidth, kImageHeight)
                       drawingBlock:^(CGContextRef context, CGRect contextBounds) {
                           [self drawALineInContext:context rect:contextBounds];
                       } completed:^(NSString *key, UIImage *image) {
                           XCTAssert( image.size.width == kImageWidth );
                           XCTAssert( image.size.height == kImageHeight );
                           
                           sum++;
                           if ( sum == 100 ){
                               [expectation fulfill];
                           }
                       }];
    }
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test12AddSameImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test12AddSameImage"];
    
    [_iconCache addImageWithKey:@"10"
                           size:CGSizeMake(kImageWidth, kImageHeight)
                   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
                       [self drawALineInContext:context rect:contextBounds];
                   } completed:^(NSString *key, UIImage *image) {
                       XCTAssert( image.size.width == kImageWidth );
                       XCTAssert( image.size.height == kImageHeight );
                       
                       [expectation fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test13AddMultipleKeys {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test13AddMultipleKeys"];
    
    __block int sum = 0;
    for (int i=1; i<=100; i++) {
        [_iconCache addImageWithKey:[NSString stringWithFormat:@"%d", i]
                               size:CGSizeMake(kImageWidth, kImageHeight)
                       drawingBlock:^(CGContextRef context, CGRect contextBounds) {
                           [self drawALineInContext:context rect:contextBounds];
                       } completed:^(NSString *key, UIImage *image) {
                           XCTAssert( image.size.width == kImageWidth );
                           XCTAssert( image.size.height == kImageHeight );
                           
                           sum++;
                           if ( sum == 100 ){
                               [expectation fulfill];
                           }
                       }];
    }
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test20ReplaceImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test20ReplaceImage"];
    
    [_iconCache replaceImageWithKey:@"11"
                       drawingBlock:^(CGContextRef context, CGRect contextBounds) {

                           [self drawALineInContext:context rect:contextBounds];

    } completed:^(NSString *key, UIImage *image) {
        XCTAssert( image.size.width == kImageWidth );
        XCTAssert( image.size.height == kImageHeight );
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test30AsyncGetImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test30AsyncGetImage"];
    
    [_iconCache asyncGetImageWithKey:@"10" completed:^(NSString *key, UIImage *image) {
        XCTAssert( image.size.width == kImageWidth );
        XCTAssert( image.size.height == kImageHeight );
        
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test31AsyncGetImageMultipleTimes {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test31AsyncGetImageMultipleTimes"];
    
    __block int sum = 0;
    for (int i=0; i<100; i++) {
        [_iconCache asyncGetImageWithKey:@"10"
                               completed:^(NSString *key, UIImage *image) {
                           XCTAssert( image.size.width == kImageWidth );
                           XCTAssert( image.size.height == kImageHeight );
                           
                           sum++;
                           if ( sum == 100 ){
                               [expectation fulfill];
                           }
                       }];
    }
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test70RemoveImage {
    [_iconCache removeImageWithKey:@"11"];
    XCTAssert( ![_iconCache isImageExistWithKey:@"11"] );
}

- (void)test80ChangeImageKey {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test80ChangeImageKey"];
    
    [_iconCache changeImageKey:@"10" newKey:@"newKey"];
    XCTAssert( ![_iconCache isImageExistWithKey:@"10"] );
    XCTAssert( [_iconCache isImageExistWithKey:@"newKey"] );
    
    [_iconCache asyncGetImageWithKey:@"newKey" completed:^(NSString *key, UIImage *image) {
        XCTAssert( image.size.width == kImageWidth );
        XCTAssert( image.size.height == kImageHeight );
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test90Purge {
    [_iconCache purge];
    XCTAssert( ![_iconCache isImageExistWithKey:@"10"] );
}

- (void)test91Dealloc {
    _iconCache = nil;
    XCTAssert( YES );
}

@end
