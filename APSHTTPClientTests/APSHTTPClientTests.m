//
//  APSHTTPClientTests.m
//  APSHTTPClientTests
//
//  Created by Matt Langston on 5/30/14.
//  Copyright (c) 2014 Appcelerator. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "APSHTTPClient.h"

@interface APSHTTPClientTests : XCTestCase <APSHTTPRequestDelegate>
@property(nonatomic, strong, readwrite) APSHTTPRequest *request;
@property(nonatomic, strong, readwrite) NSThread       *asyncThread;
@property(nonatomic, strong, readwrite) NSTimer        *dummyTimer;
@end

@implementation APSHTTPClientTests

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

- (void)testExample
{
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
}

- (void) testSynchronous
{
    self.request = [[APSHTTPRequest alloc] init];
    
    self.request.url = [NSURL URLWithString:@"http://www.appcelerator.com/"];
    self.request.method = @"GET";
    self.request.synchronous = YES;
    
    XCTAssertNotNil(self.request, @"APSHTTPRequest Object is nil");
    XCTAssertNotNil(self.request.response, @"APSHTTPRequest.response Object is nil");
    XCTAssertEqual(self.request.response.readyState, APSHTTPResponseStateUnsent, @"Response state must be APSHTTPResponseStateUnsent before send is called");
    [self.request send];
    XCTAssertEqual(self.request.response.readyState, APSHTTPResponseStateDone, @"Response state must be APSHTTPResponseStateDone when send returns for a synchronous call.");
    self.request = nil;
    
}

- (void) testAsynchronous
{
    self.request = [[APSHTTPRequest alloc] init];
    
    self.request.url = [NSURL URLWithString:@"http://www.appcelerator.com/"];
    self.request.method = @"GET";
    self.request.delegate = self;
    
    XCTAssertNotNil(self.request, @"APSHTTPRequest Object is nil");
    XCTAssertNotNil(self.request.response, @"APSHTTPRequest.response Object is nil");
    XCTAssertEqual(self.request.response.readyState, APSHTTPResponseStateUnsent, @"Response state must be APSHTTPResponseStateUnsent before send is called");
    
    [NSThread detachNewThreadSelector:@selector(scheduleRunLoop:) toTarget:self withObject:nil];
}

- (void)scheduleRunLoop:(id)unused
{
    NSDate *distantFuture = [NSDate distantFuture];
    self.asyncThread = [NSThread currentThread];
    self.dummyTimer = [NSTimer timerWithTimeInterval:[NSDate timeIntervalSinceReferenceDate] target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.dummyTimer forMode:NSDefaultRunLoopMode];
    NSTimer* kickOff = [NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:kickOff forMode:NSDefaultRunLoopMode];
    [[NSRunLoop currentRunLoop] runUntilDate:distantFuture];
    XCTAssertEqual(self.request.response.readyState, APSHTTPResponseStateDone, @"Response state must be APSHTTPResponseStateDone when runloop ends.");
    self.asyncThread = nil;
    self.dummyTimer = nil;
    self.request = nil;
}


- (void)timerFired:(NSTimer*)timer
{
    [self.request send];
}

#pragma mark - APSHTTPRequestDelegate Callbacks
-(void)request:(APSHTTPRequest*)request onLoad:(APSHTTPResponse*)response
{
    if (self.asyncThread) {
        XCTAssertEqualObjects([NSThread currentThread], self.asyncThread, @"Asynchronous callback not on same thread as calling thread %@ %@",[NSThread currentThread], self.asyncThread);
        [self.dummyTimer invalidate];
    }
}

-(void)request:(APSHTTPRequest*)request onError:(APSHTTPResponse*)response
{
    if (self.asyncThread) {
        XCTAssertEqualObjects([NSThread currentThread], self.asyncThread, @"Asynchronous callback not on same thread as calling thread %@ %@",[NSThread currentThread], self.asyncThread);
    }
}

-(void)request:(APSHTTPRequest*)request onDataStream:(APSHTTPResponse*)response
{
    if (self.asyncThread) {
        XCTAssertEqualObjects([NSThread currentThread], self.asyncThread, @"Asynchronous callback not on same thread as calling thread %@ %@",[NSThread currentThread], self.asyncThread);
    }
}

-(void)request:(APSHTTPRequest*)request onSendStream:(APSHTTPResponse*)response
{
    if (self.asyncThread) {
        XCTAssertEqualObjects([NSThread currentThread], self.asyncThread, @"Asynchronous callback not on same thread as calling thread %@ %@",[NSThread currentThread], self.asyncThread);
    }
}

-(void)request:(APSHTTPRequest*)request onReadyStateChange:(APSHTTPResponse*)response
{
    if (self.asyncThread) {
        XCTAssertEqualObjects([NSThread currentThread], self.asyncThread, @"Asynchronous callback not on same thread as calling thread %@ %@",[NSThread currentThread], self.asyncThread);
    }
}

-(void)request:(APSHTTPRequest*)request onRedirect:(APSHTTPResponse*)response
{
    if (self.asyncThread) {
        XCTAssertEqualObjects([NSThread currentThread], self.asyncThread, @"Asynchronous callback not on same thread as calling thread %@ %@",[NSThread currentThread], self.asyncThread);
    }
}

@end
