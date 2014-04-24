/**
 * Appcelerator APSHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "APSHTTPClient.h"

@implementation APSHTTPOperation

- (void)dealloc
{
    [super dealloc];
}

- (id)initWithConnection:(APSHTTPRequest *)request
{
    self = [self init];
    if (self) {
        // Assign it! it will be released with the request itself
        _request = request;
        _cancelled = NO;
        _executing = NO;
        _finished = NO;
        _ready = NO;
        [self willChangeValueForKey: @"isReady"];
        _ready = YES;
        [self didChangeValueForKey: @"isReady"];
    }

    return self;
}

- (void)start
{
    [self willChangeValueForKey: @"isExecuting"];
    _executing = YES;
    [self didChangeValueForKey: @"isExecuting"];

    if(!_cancelled) {
        [[[self request] connection] start];
        // Keep running the run loop until all asynchronous operations are completed
        while (![self isFinished]) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
}

- (void)cancel
{
    [self willChangeValueForKey: @"isCancelled"];
    _cancelled = YES;
    [self didChangeValueForKey: @"isCancelled"];
    
    if(_executing) {
        [[self request] setCancelled:YES];
        [[[self request] connection] cancel];
        [[self request] connection:[[self request] connection] didFailWithError:
         [NSError errorWithDomain:@"APSHTTPErrorDomain"
                             code:APSRequestErrorCancel
                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"The request was cancelled",NSLocalizedDescriptionKey,nil]]
         ];
    } else {
        [self start];
    }
    
    [self setFinished:YES];
    [super cancel];
}

-(void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey: @"isFinished"];
    _finished = finished;
    [self didChangeValueForKey: @"isFinished"];

}
-(BOOL)isReady
{
    return _ready;
}
- (BOOL)isCancelled
{
    return _cancelled;
}
- (BOOL)isExecuting
{
    return _executing;
}
- (BOOL)isFinished
{
    return _finished;
}
-(BOOL)isConcurrent
{
    return NO;
}

@end
