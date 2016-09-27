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

#define kImageWidth 30
#define kImageHeight 40

@implementation FlyImageIconCacheTests

- (void)setUp
{
	[super setUp];
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
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
	
	[[FlyImageIconCache sharedInstance] addImageWithKey:@"10"
												   size:CGSizeMake(kImageWidth, kImageHeight)
										   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
											   [self drawALineInContext:context rect:contextBounds];
										   }
											  completed:^(NSString* key, UIImage* image) {
												  XCTAssert( image.size.width == kImageWidth );
												  XCTAssert( image.size.height == kImageHeight );
												  
												  [expectation fulfill];
											  }];
	
	[self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test11AddMultipleTimes
{
	XCTestExpectation* expectation = [self expectationWithDescription:@"test11AddMultipleTimes"];
	
	__block int sum = 0;
	for (int i = 0; i < 100; i++) {
		[[FlyImageIconCache sharedInstance] addImageWithKey:@"11"
													   size:CGSizeMake(kImageWidth, kImageHeight)
											   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
												   [self drawALineInContext:context rect:contextBounds];
											   }
												  completed:^(NSString* key, UIImage* image) {
													  XCTAssert( image.size.width == kImageWidth );
													  XCTAssert( image.size.height == kImageHeight );
													  
													  sum++;
													  if ( sum == 100 ){
														  [expectation fulfill];
													  }
												  }];
	}
	
	[self waitForExpectationsWithTimeout:30 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test12AddSameImage
{
	XCTestExpectation* expectation = [self expectationWithDescription:@"test12AddSameImage"];
	
	[[FlyImageIconCache sharedInstance] addImageWithKey:@"10"
												   size:CGSizeMake(kImageWidth, kImageHeight)
										   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
											   [self drawALineInContext:context rect:contextBounds];
										   }
											  completed:^(NSString* key, UIImage* image) {
												  
												  
												  [[FlyImageIconCache sharedInstance] addImageWithKey:@"10"
																								 size:CGSizeMake(kImageWidth, kImageHeight)
																						 drawingBlock:^(CGContextRef context, CGRect contextBounds) {
																							 [self drawALineInContext:context rect:contextBounds];
																						 }
																							completed:^(NSString* key, UIImage* image) {
																								
																								XCTAssert( image.size.width == kImageWidth );
																								XCTAssert( image.size.height == kImageHeight );
																								
																								[expectation fulfill];
																								
																							}];
											  }];
	
	[self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test13AddMultipleKeys
{
	XCTestExpectation* expectation = [self expectationWithDescription:@"test13AddMultipleKeys"];
	
	__block int sum = 0;
	for (int i = 1; i <= 100; i++) {
		[[FlyImageIconCache sharedInstance] addImageWithKey:[NSString stringWithFormat:@"%d", i]
													   size:CGSizeMake(kImageWidth, kImageHeight)
											   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
												   [self drawALineInContext:context rect:contextBounds];
											   }
												  completed:^(NSString* key, UIImage* image) {
													  XCTAssert( image.size.width == kImageWidth );
													  XCTAssert( image.size.height == kImageHeight );
													  
													  sum++;
													  if ( sum == 100 ){
														  [expectation fulfill];
													  }
												  }];
	}
	
	[self waitForExpectationsWithTimeout:30 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test20ReplaceImage
{
	XCTestExpectation* expectation = [self expectationWithDescription:@"test20ReplaceImage"];
	
	[[FlyImageIconCache sharedInstance] addImageWithKey:@"20"
												   size:CGSizeMake(kImageWidth, kImageHeight)
										   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
											   [self drawALineInContext:context rect:contextBounds];
										   }
											  completed:^(NSString* key, UIImage* image) {
												  
												  [[FlyImageIconCache sharedInstance] replaceImageWithKey:@"20"
																							 drawingBlock:^(CGContextRef context, CGRect contextBounds) {
																								 [self drawALineInContext:context rect:contextBounds];
																							 }
																								completed:^(NSString* key, UIImage* image) {
																									XCTAssert( image.size.width == kImageWidth );
																									XCTAssert( image.size.height == kImageHeight );
																									
																									[expectation fulfill];
																								}];
											  }];
	
	[self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test30AsyncGetImage
{
	XCTestExpectation* expectation = [self expectationWithDescription:@"test30AsyncGetImage"];
	
	[[FlyImageIconCache sharedInstance] addImageWithKey:@"30"
												   size:CGSizeMake(kImageWidth, kImageHeight)
										   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
											   [self drawALineInContext:context rect:contextBounds];
										   }
											  completed:^(NSString* key, UIImage* image) {
												  
												  [[FlyImageIconCache sharedInstance] asyncGetImageWithKey:@"30" completed:^(NSString* key, UIImage* image) {
													  XCTAssert( image.size.width == kImageWidth );
													  XCTAssert( image.size.height == kImageHeight );
													  
													  [expectation fulfill];
												  }];
												  
											  }];
	
	[self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test31AsyncGetImageMultipleTimes
{
	XCTestExpectation* expectation = [self expectationWithDescription:@"test31AsyncGetImageMultipleTimes"];
	
	[[FlyImageIconCache sharedInstance] addImageWithKey:@"31"
												   size:CGSizeMake(kImageWidth, kImageHeight)
										   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
											   [self drawALineInContext:context rect:contextBounds];
										   }
											  completed:^(NSString* key, UIImage* image) {
												  
												  __block int sum = 0;
												  for (int i = 0; i < 100; i++) {
													  [[FlyImageIconCache sharedInstance] asyncGetImageWithKey:@"31"
																									 completed:^(NSString* key, UIImage* image) {
                           XCTAssert( image.size.width == kImageWidth );
                           XCTAssert( image.size.height == kImageHeight );
                           
                           sum++;
                           if ( sum == 100 ){
							   [expectation fulfill];
						   }
																									 }];
												  }
												  
											  }];
	
	[self waitForExpectationsWithTimeout:30 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test40DifferentSize
{
	XCTestExpectation* expectation = [self expectationWithDescription:@"test40DifferentSize"];
	
	[[FlyImageIconCache sharedInstance] addImageWithKey:@"400"
												   size:CGSizeMake(27, 57)
										   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
											   [self drawALineInContext:context rect:contextBounds];
										   }
											  completed:^(NSString* key, UIImage* image) {
												  XCTAssert( image.size.width == 27 );
												  XCTAssert( image.size.height == 57 );
												  
												  [[FlyImageIconCache sharedInstance] addImageWithKey:@"401"
																								 size:CGSizeMake(88, 99)
																						 drawingBlock:^(CGContextRef context, CGRect contextBounds) {
																							 [self drawALineInContext:context rect:contextBounds];
																						 }
																							completed:^(NSString* key, UIImage* image) {
																								XCTAssert( image.size.width == 88 );
																								XCTAssert( image.size.height == 99 );
																								
																								[expectation fulfill];
																							}];
											  }];
	
	[self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test70RemoveImage
{
	XCTestExpectation* expectation = [self expectationWithDescription:@"test70RemoveImage"];
	
	[[FlyImageIconCache sharedInstance] addImageWithKey:@"70"
												   size:CGSizeMake(kImageWidth, kImageHeight)
										   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
											   [self drawALineInContext:context rect:contextBounds];
										   }
											  completed:^(NSString* key, UIImage* image) {
												  
												  [[FlyImageIconCache sharedInstance] removeImageWithKey:@"70"];
												  XCTAssert(![[FlyImageIconCache sharedInstance] isImageExistWithKey:@"70"]);
												  
												  [expectation fulfill];
											  }];
	
	[self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test80ChangeImageKey
{
	XCTestExpectation* expectation = [self expectationWithDescription:@"test80ChangeImageKey"];
	
	[[FlyImageIconCache sharedInstance] addImageWithKey:@"70"
												   size:CGSizeMake(kImageWidth, kImageHeight)
										   drawingBlock:^(CGContextRef context, CGRect contextBounds) {
											   [self drawALineInContext:context rect:contextBounds];
										   }
											  completed:^(NSString* key, UIImage* image) {
												  
												  [[FlyImageIconCache sharedInstance] changeImageKey:@"80" newKey:@"newKey"];
												  XCTAssert(![[FlyImageIconCache sharedInstance] isImageExistWithKey:@"80"]);
												  XCTAssert([[FlyImageIconCache sharedInstance] isImageExistWithKey:@"newKey"]);
												  
												  [[FlyImageIconCache sharedInstance] asyncGetImageWithKey:@"newKey" completed:^(NSString* key, UIImage* image) {
													  XCTAssert( image.size.width == kImageWidth );
													  XCTAssert( image.size.height == kImageHeight );
													  
													  [expectation fulfill];
												  }];
												  
											  }];
	
	[self waitForExpectationsWithTimeout:10 handler:^(NSError* error) { XCTAssert(YES, @"Pass"); }];
}

- (void)test90Purge
{
	[[FlyImageIconCache sharedInstance] purge];
	XCTAssert(![[FlyImageIconCache sharedInstance] isImageExistWithKey:@"10"]);
}

@end
