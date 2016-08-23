//
//  FlyImageDataFileTests.m
//  Demo
//
//  Created by Norris Tong on 16/3/20.
//  Copyright © 2016年 NorrisTong. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "FlyImageDataFile.h"
#import "FlyImageUtils.h"
#import <Metal/Metal.h>

@interface FlyImageDataFileTests : XCTestCase

@end

static FlyImageDataFile *_dataFile;
static size_t kTestLength = 4096 * 10;
static int kTestCount = 50;
static CGFloat imageWidth = 1920.0;
static CGFloat imageHeight = 1200.0;
static NSString *testDataFileName = @"testDataFile";

@implementation FlyImageDataFileTests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    if ( _dataFile == nil ) {
        
        NSString *filePath = [[FlyImageUtils directoryPath] stringByAppendingPathComponent:testDataFileName];
        BOOL isFileExist = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
        if (!isFileExist) {
            [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        }
        
        _dataFile = [[FlyImageDataFile alloc] initWithPath:filePath];
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test1Open {
	XCTAssert([_dataFile open]);
}

- (void)test20PrepareAppendDataWrongLength {
    XCTAssert( ![_dataFile prepareAppendDataWithOffset:0 length:200 * 1024 * 1024]);
}

- (void)test30AppendData {
    BOOL ret = YES;
	
	for (int i=0; i<kTestCount; i++) {
        ret &= [_dataFile prepareAppendDataWithOffset:_dataFile.pointer length:kTestLength];
		memset(_dataFile.address, 1, kTestLength);
        ret &= [_dataFile appendDataWithOffset:_dataFile.pointer length:kTestLength];
		
		if ( !ret ) {
			break;
		}
	}

    XCTAssert( ret, @"Pass" );
}

- (void)createImageAtPath:(NSString *)path {
    // generate an image with special size
    CGRect rect = CGRectMake(0.0f, 0.0f, imageWidth, imageHeight);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:path atomically:YES];
}

- (void)test50Memcpy {
	XCTestExpectation *expectation = [self expectationWithDescription:@"memcpy"];
	
    NSString *directoryPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *imagePath = [directoryPath stringByAppendingPathComponent:@"image"];
    [self createImageAtPath:imagePath];
    
	NSData *data = [NSData dataWithContentsOfFile:imagePath];
	UIImage *image = [UIImage imageWithData:data];
	CGSize imageSize = image.size;
	
	[data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
		
		size_t length = byteRange.length;
		ssize_t pageSize = [FlyImageUtils pageSize];
		size_t correctLength = ceil((length / pageSize )) * pageSize;
		
		BOOL ret = YES;
        ret &= [_dataFile prepareAppendDataWithOffset:0 length:correctLength];
		memcpy(_dataFile.address, bytes, correctLength);
        ret &= [_dataFile appendDataWithOffset:0 length:correctLength];
		
		XCTAssert( ret, @"Pass" );
		
		// Create CGImageRef whose backing store *is* the mapped image table entry. We avoid a memcpy this way.
		CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, _dataFile.address, correctLength, nil);
		
		CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host;
		NSInteger bitsPerComponent = 8;
		NSInteger bitsPerPixel = 4 * 8;
		CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
		
		static NSInteger bytesPerPixel = 4;
		static float kAlignment = 64;
		size_t bytesPerRow = ceil((imageSize.width * bytesPerPixel) / kAlignment) * kAlignment;
		
		CGImageRef imageRef = CGImageCreate(imageSize.width,
											imageSize.height,
											bitsPerComponent,
											bitsPerPixel,
											bytesPerRow,
											colorSpace,
											bitmapInfo,
											dataProvider,
											NULL,
											false,
											(CGColorRenderingIntent)0);
		
		CGDataProviderRelease(dataProvider);
		CGColorSpaceRelease(colorSpace);
		
		UIImage *revertImage = [UIImage imageWithCGImage:imageRef];
		XCTAssert( revertImage != nil, @"Pass" );
		
		CGSize revertSize = revertImage.size;
		XCTAssert( imageSize.width == revertSize.width && imageSize.height == imageSize.height, @"Pass" );
		
		[expectation fulfill];
	}];
	
	[self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
        
        XCTAssert(YES, @"Pass");
    }];
}

- (void)test99Remove {
    [_dataFile close];
	_dataFile = nil;
    
    NSString *filePath = [[FlyImageUtils directoryPath] stringByAppendingPathComponent:testDataFileName];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    
	XCTAssert(YES, @"Pass");
}

@end
