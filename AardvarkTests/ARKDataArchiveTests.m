//
//  ARKDataArchiveTests.m
//  Aardvark
//
//  Created by Peter Westen on 3/17/15.
//  Copyright (c) 2015 Square, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ARKDataArchive.h"


@interface ARKFaultyUnarchivingObject : NSObject <NSSecureCoding>
@end


@implementation ARKFaultyUnarchivingObject

+ (BOOL)supportsSecureCoding;
{
    return YES;
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)aCoder;
{
}

@end


@interface ARKDataArchiveTests : XCTestCase

@property (nonatomic) ARKDataArchive *dataArchive;

@end


@implementation ARKDataArchiveTests

- (void)setUp {
    [super setUp];
    
    self.dataArchive = [[ARKDataArchive alloc] initWithApplicationSupportFilename:@"archive.data" maximumObjectCount:8 trimmedObjectCount:5];
}

- (void)tearDown {
    [self.dataArchive saveArchiveAndWait:YES];
    
    NSURL *fileURL = self.dataArchive.archiveFileURL;
    self.dataArchive = nil;
    [[NSFileManager defaultManager] removeItemAtURL:fileURL error:NULL];
    
    [super tearDown];
}

- (void)testBasics {
    XCTestExpectation *expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertNotNil(unarchivedObjects, @"-[ARKDataArchive readObjectsFromArchiveWithCompletionHandler:] should never return nil!");
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not initially empty!");
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

- (void)testReopenedArchive {
    XCTestExpectation *expectation0 = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not initially empty!");
        
        [expectation0 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@"One"];
    [self.dataArchive appendArchiveOfObject:@"Two"];
    [self.dataArchive appendArchiveOfObject:@"Three"];
    [self.dataArchive appendArchiveOfObject:@"Four"];
    
    [self.dataArchive saveArchiveAndWait:YES];
    self.dataArchive = nil;
    
    self.dataArchive = [[ARKDataArchive alloc] initWithApplicationSupportFilename:@"archive.data" maximumObjectCount:10 trimmedObjectCount:5];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-1", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"One", @"Two", @"Three", @"Four" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Re-opened archive didn't have expected objects!");
        
        [expectation1 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@"Five"];
    [self.dataArchive appendArchiveOfObject:@"Six"];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-2", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"One", @"Two", @"Three", @"Four", @"Five", @"Six" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Re-appended archive didn't have expected objects!");
        
        [expectation2 fulfill];
    }];
    
    [self.dataArchive saveArchiveAndWait:YES];
    self.dataArchive = nil;
    
    self.dataArchive = [[ARKDataArchive alloc] initWithApplicationSupportFilename:@"archive.data" maximumObjectCount:5 trimmedObjectCount:4];
    XCTestExpectation *expectation3 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-3", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"Three", @"Four", @"Five", @"Six" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Re-opened archive didn't trim to new values!");
        
        [expectation3 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testArchiveTrimming;
{
    XCTestExpectation *expectation0 = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not initially empty!");
        
        [expectation0 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@1];
    [self.dataArchive appendArchiveOfObject:@2];
    [self.dataArchive appendArchiveOfObject:@3];
    [self.dataArchive appendArchiveOfObject:@4];
    [self.dataArchive appendArchiveOfObject:@5];
    [self.dataArchive appendArchiveOfObject:@6];
    [self.dataArchive appendArchiveOfObject:@7];
    [self.dataArchive appendArchiveOfObject:@8];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-1", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @1, @2, @3, @4, @5, @6, @7, @8 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected initial maximum number of objects!");
        
        [expectation1 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@9];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-2", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @5, @6, @7, @8, @9 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected initial trimmed objects!");
        
        [expectation2 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@10];
    [self.dataArchive appendArchiveOfObject:@11];
    [self.dataArchive appendArchiveOfObject:@12];
    
    XCTestExpectation *expectation3 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-3", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @5, @6, @7, @8, @9, @10, @11, @12 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected second maximum number objects!");
        
        [expectation3 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@13];
    
    XCTestExpectation *expectation4 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-4", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @9, @10, @11, @12, @13 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected second trimmed objects!");
        
        [expectation4 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@14];
    [self.dataArchive appendArchiveOfObject:@15];
    [self.dataArchive appendArchiveOfObject:@16];
    [self.dataArchive appendArchiveOfObject:@17];
    [self.dataArchive appendArchiveOfObject:@18];
    [self.dataArchive appendArchiveOfObject:@19];
    
    XCTestExpectation *expectation5 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-5", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @13, @14, @15, @16, @17, @18, @19 ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected final objects!");
        
        [expectation5 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testArchiveCorruptionDetection;
{
    XCTestExpectation *expectation0 = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not initially empty!");
        
        [expectation0 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@[ @1, @2 ]];
    [self.dataArchive appendArchiveOfObject:@[ @3, @4 ]];
    [self.dataArchive appendArchiveOfObject:@[ @5, @6 ]];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-1", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @[ @1, @2 ], @[ @3, @4 ], @[ @5, @6 ] ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected objects!");
        
        [expectation1 fulfill];
    }];
    
    [self.dataArchive saveArchiveAndWait:YES];
    NSURL *fileURL = self.dataArchive.archiveFileURL;
    self.dataArchive = nil;
    
    NSData *fileData = [[NSData dataWithContentsOfURL:fileURL] subdataWithRange:NSMakeRange(0, 300)];
    [fileData writeToURL:fileURL atomically:YES];
    
    self.dataArchive = [[ARKDataArchive alloc] initWithApplicationSupportFilename:@"archive.data" maximumObjectCount:10 trimmedObjectCount:5];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-2", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not empty after re-initializing with invalid data!");
        
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testUnarchivingProtection;
{
    XCTestExpectation *expectation0 = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        XCTAssertEqual(unarchivedObjects.count, 0, @"Archive not initially empty!");
        
        [expectation0 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@"First"];
    [self.dataArchive appendArchiveOfObject:@"Second"];
    [self.dataArchive appendArchiveOfObject:@"Third"];
    [self.dataArchive appendArchiveOfObject:[ARKFaultyUnarchivingObject new]];
    [self.dataArchive appendArchiveOfObject:@"Fifth"];
    [self.dataArchive appendArchiveOfObject:@"Sixth"];
    [self.dataArchive appendArchiveOfObject:@"Seventh"];
    [self.dataArchive appendArchiveOfObject:@"Eighth"];
    
    XCTestExpectation *expectation1 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-1", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"First", @"Second", @"Third", @"Fifth", @"Sixth", @"Seventh", @"Eighth" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected objects omitted failed unarchiver!");
        
        [expectation1 fulfill];
    }];
    
    [self.dataArchive appendArchiveOfObject:@"Ninth"];
    [self.dataArchive appendArchiveOfObject:@"Tenth"];
    [self.dataArchive appendArchiveOfObject:@"Eleventh"];
    [self.dataArchive appendArchiveOfObject:@"Twelfth"];
    
    XCTestExpectation *expectation2 = [self expectationWithDescription:[NSString stringWithFormat:@"%@-2", NSStringFromSelector(_cmd)]];
    [self.dataArchive readObjectsFromArchiveWithCompletionHandler:^(NSArray *unarchivedObjects) {
        NSArray *expectedObjects = @[ @"Fifth", @"Sixth", @"Seventh", @"Eighth", @"Ninth", @"Tenth", @"Eleventh", @"Twelfth" ];
        XCTAssertEqualObjects(unarchivedObjects, expectedObjects, @"Archive didn't have expected objects after trimming out failed unarchiver!");
        
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
