/**
 * Appcelerator APSHTTPClient Library
 * Copyright (c) 2014-2015 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "APSHTTPClient.h"

typedef NS_ENUM(NSInteger, APSHTTPCallbackState) {
    APSHTTPCallbackStateReadyState = 0,
    APSHTTPCallbackStateLoad       = 1,
    APSHTTPCallbackStateSendStream = 2,
    APSHTTPCallbackStateDataStream = 3,
    APSHTTPCallbackStateError      = 4,
    APSHTTPCallbackStateRedirect   = 5
};

@interface APSHTTPRequest () <NSURLSessionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDelegate>

@property(nonatomic, strong, readwrite ) NSMutableURLRequest *request;
@property(nonatomic, assign, readwrite) long long           expectedDownloadResponseLength;
@property(nonatomic, strong, readwrite) NSURLSession        *session;
@property(nonatomic, strong, readonly ) NSMutableDictionary *headers;
@property(nonatomic, strong, readwrite) NSURLSessionDataTask *task;

@end


@implementation APSHTTPRequest

- (id)init
{
    self = [super init];
    if (self) {
        _sendDefaultCookies = YES;
        _redirects = YES;
        _validatesSecureCertificate = YES;
        _headers = [[NSMutableDictionary alloc] init];
        _runModes = @[NSDefaultRunLoopMode];
        _request = [[NSMutableURLRequest alloc] init];
        [_request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
        _response = [[APSHTTPResponse alloc] init];
        [_response setReadyState: APSHTTPResponseStateUnsent];
    }
    return self;
}

-(void)abort
{
    self.cancelled = YES;
    if (self.session != nil) {
       [self.session invalidateAndCancel];
       [self URLSession:self.session didBecomeInvalidWithError:
       [NSError errorWithDomain:@"APSHTTPErrorDomain"
                                 code:APSRequestErrorCancel
                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"The request was cancelled",NSLocalizedDescriptionKey,nil]]];
      }
    return;
}


-(void)send
{
#if TARGET_OS_SIMULATOR
    assert(self.url != nil);
    assert(self.method != nil);
    assert(self.response != nil);
    assert(self.response.readyState == APSHTTPResponseStateUnsent);
#endif

    if (!(self.url != nil)) {
        DebugLog(@"[ERROR] Missing required parameter URL. Ignoring call");
        return;
    }
    
    if (!(self.method != nil)) {
        DebugLog(@"[ERROR] Missing required parameter method. Ignoring call");
        return;
    }
    
    if (!(self.response.readyState == APSHTTPResponseStateUnsent)) {
        DebugLog(@"[ERROR] APSHTTPRequest does not support reuse of connection. Ignoring call.");
        return;
    }

    if (self.filePath != nil) {
        self.response.filePath = self.filePath;
    }
    if (self.postForm != nil) {
        NSData *data = self.postForm.requestData;
        if(data.length > 0) {
            [self.request setHTTPBody:data];
        }
        DebugLog(@"Data: %@", [NSString stringWithUTF8String: [data bytes]]);
        NSDictionary *headers = self.postForm.requestHeaders;
        for (NSString* key in headers)
        {
            [self.request setValue:[headers valueForKey:key] forHTTPHeaderField:key];
            DebugLog(@"Header: %@: %@", key, [headers valueForKey:key]);
        }
    }

    for (NSString* key in self.headers) {
            [self.request setValue:self.headers[key] forHTTPHeaderField:key];
            DebugLog(@"Header: %@: %@", key, self.headers[key]);
    }
    
    DebugLog(@"URL: %@", self.url);
    self.request.URL = self.url;
    
    if(self.timeout > 0) {
        self.request.timeoutInterval = self.timeout;
    }
    
    [self.request setHTTPMethod: self.method];
    DebugLog(@"Method: %@", self.method);
    
    [self.request setHTTPShouldHandleCookies:self.sendDefaultCookies];
    [self.request setCachePolicy:self.cachePolicy];
    
    if(self.synchronous) {
        if(self.requestUsername != nil && self.requestPassword != nil && [self.request valueForHTTPHeaderField:@"Authorization"] == nil) {
            NSString *authString = [APSHTTPHelper base64encode:[[NSString stringWithFormat:@"%@:%@",self.requestUsername, self.requestPassword] dataUsingEncoding:NSUTF8StringEncoding]];
            [self.request setValue:[NSString stringWithFormat:@"Basic %@", authString] forHTTPHeaderField:@"Authorization"];
        }
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:self.theQueue];
        self.task = [self.session dataTaskWithRequest:self.request completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error) {
              [self.response appendData:data];
              [self.response updateResponseParamaters:response];
              [self.response setError:error];
              [self.response updateRequestParamaters:self.request];
              [self.response setReadyState:APSHTTPResponseStateDone];
              [self.response setConnected:NO];
                
              [self responseFinished];
              dispatch_semaphore_signal(semaphore);
          }];
          [self.task resume];
          dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    } else {
        [self.response updateRequestParamaters:self.request];
        [self.response setReadyState:APSHTTPResponseStateOpened];
        [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];
        
        self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
        self.task = [self.session dataTaskWithRequest:self.request];
        [self.task resume];
    }
}

-(void)addRequestHeader:(NSString *)key value:(NSString *)value
{
    if (key == nil) {
        DebugLog(@"Ignore request to %s. key is nil.", __PRETTY_FUNCTION__);
        return;
    }
    if (value == nil) {
        DebugLog(@"Remove header for key %@.", key);
        [self.headers removeObjectForKey:key];
    } else {
        NSString *oldValue = [self.headers objectForKey:key];
        //check if key already contain a value
        if (oldValue != nil) {
            //only for cookie we use ';', otherwise ','
            if ([[key lowercaseString] isEqualToString:@"cookie"]) {
                self.headers[key] = [NSString stringWithFormat:@"%@; %@",oldValue,value];
            }
            else {
                self.headers[key] = [NSString stringWithFormat:@"%@, %@",oldValue,value];
            }
            DebugLog(@"Multiple headers set. header values %@.", self.headers[key]);
            return;

        }
        self.headers[key] = value;
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    BOOL useSubDelegate = (self.connectionDelegate != nil && [self.connectionDelegate respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)]);
    
    if (useSubDelegate && [self.connectionDelegate respondsToSelector:@selector(willHandleChallenge:forSession:)]) {
        useSubDelegate = [self.connectionDelegate willHandleChallenge:challenge forSession:session];
    }
    
    if (useSubDelegate) {
        @try {
            [self.connectionDelegate URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
        }
        @catch (NSException *exception) {
            if (self.task != nil) {
                [self.task cancel];
                
                NSMutableDictionary *dictionary = nil;
                if (exception.userInfo) {
                    dictionary = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
                } else {
                    dictionary = [NSMutableDictionary dictionary];
                }
                if (exception.reason != nil) {
                    [dictionary setObject:exception.reason forKey:NSLocalizedDescriptionKey];
                }
                
                NSError* error = [NSError errorWithDomain:@"APSHTTPErrorDomain"
                                                     code:APSRequestErrorConnectionDelegateFailed
                                                 userInfo:dictionary];
                
                [self URLSession:self.session didBecomeInvalidWithError:error];
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
        }
        @finally {
            //Do nothing
        }
        return;
    }
    
    if (challenge.previousFailureCount) {
        [challenge.sender cancelAuthenticationChallenge:challenge];
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
    
    NSString* authMethod = challenge.protectionSpace.authenticationMethod;
    BOOL handled = NO;
    if ([authMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (([challenge.protectionSpace.host isEqualToString:self.url.host]) && (!self.validatesSecureCertificate)){
            handled = YES;
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            //NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengeUseCredential;
            completionHandler(disposition, credential);
        }
    } else if ( [authMethod isEqualToString:NSURLAuthenticationMethodDefault] || [authMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]
               || [authMethod isEqualToString:NSURLAuthenticationMethodNTLM] || [authMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]) {
        if(self.requestPassword != nil && self.requestUsername != nil) {
            handled = YES;
            NSURLCredential *credential = [NSURLCredential credentialWithUser:self.requestUsername
                                                                     password:self.requestPassword                                                                  persistence:NSURLCredentialPersistenceForSession];
            
            [challenge.sender useCredential: credential forAuthenticationChallenge:challenge];
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengeUseCredential;
            completionHandler(disposition, credential);
        }
    }
    
    if (!handled) {
        if ([challenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)]) {
            [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            completionHandler(disposition, nil);
        } else {
            [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengeUseCredential;
            completionHandler(disposition, nil);
        }
    }
    
}

-(void)URLSession:(nonnull NSURLSession *)session didReceiveChallenge:(nonnull NSURLAuthenticationChallenge *)challenge completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * __nullable))completionHandler
{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    
    BOOL useSubDelegate = (self.connectionDelegate != nil && [self.connectionDelegate respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)]);
    
    if (useSubDelegate && [self.connectionDelegate respondsToSelector:@selector(willHandleChallenge:forSession:)]) {
        useSubDelegate = [self.connectionDelegate willHandleChallenge:challenge forSession:session];
    }
    
    if (useSubDelegate) {
        @try {
            [self.connectionDelegate URLSession:session task:self.task didReceiveChallenge:challenge completionHandler:completionHandler];
        }
        @catch (NSException *exception) {
            if (self.task != nil) {
                [self.task cancel];
                
                NSMutableDictionary *dictionary = nil;
                if (exception.userInfo) {
                    dictionary = [NSMutableDictionary dictionaryWithDictionary:exception.userInfo];
                } else {
                    dictionary = [NSMutableDictionary dictionary];
                }
                if (exception.reason != nil) {
                    [dictionary setObject:exception.reason forKey:NSLocalizedDescriptionKey];
                }
                
                NSError* error = [NSError errorWithDomain:@"APSHTTPErrorDomain"
                                                     code:APSRequestErrorConnectionDelegateFailed
                                                 userInfo:dictionary];
                
                [self URLSession:self.session didBecomeInvalidWithError:error];
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            }
        }
        @finally {
            //Do nothing
        }
        return;
    }
    
    if (challenge.previousFailureCount) {
        [challenge.sender cancelAuthenticationChallenge:challenge];
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
    
    NSString* authMethod = challenge.protectionSpace.authenticationMethod;
    BOOL handled = NO;
    if ([authMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (([challenge.protectionSpace.host isEqualToString:self.url.host]) && (!self.validatesSecureCertificate)){
            handled = YES;
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            //NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengeUseCredential;
            completionHandler(disposition, credential);
        }
    } else if ([authMethod isEqualToString:NSURLAuthenticationMethodDefault] || [authMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]
               || [authMethod isEqualToString:NSURLAuthenticationMethodNTLM] || [authMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]) {
        if (self.requestPassword != nil && self.requestUsername != nil) {
            handled = YES;
            NSURLCredential *credential = [NSURLCredential credentialWithUser:self.requestUsername
                                                                     password:self.requestPassword persistence:NSURLCredentialPersistenceForSession];
            
            [challenge.sender useCredential: credential forAuthenticationChallenge:challenge];
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengeUseCredential;
            completionHandler(disposition, credential);
        }
    }
    
    if (!handled) {
        if ([challenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)]) {
            [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            completionHandler(disposition, nil);
        } else {
            [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengeUseCredential;
            completionHandler(disposition, nil);
        }
    }
}

-(void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task willPerformHTTPRedirection:(nonnull NSHTTPURLResponse *)response newRequest:(nonnull NSURLRequest *)request completionHandler:(nonnull void (^)(NSURLRequest * __nullable))completionHandler
{
    DebugLog(@"Code %li Redirecting from: %@ to: %@",(long)[(NSHTTPURLResponse*)response statusCode], [self.request URL] ,[request URL]);
    self.response.connected = YES;
    [self.response updateResponseParamaters:response];
    if (!self.redirects && self.response.status != 0) {
        completionHandler(nil);
        return;
    }
    [self.response updateRequestParamaters:request];
    [self invokeCallbackWithState:APSHTTPCallbackStateRedirect];
    if (response) {
        NSMutableURLRequest *r = [self.request mutableCopy];
        r.URL = request.URL;
        self.request = r;
    } else {
        self.request = [request mutableCopy];
    }
    completionHandler(self.request);
}

- (void) URLSession:(nonnull NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveResponse:(nonnull NSURLResponse *)response completionHandler:(nonnull void (^)(NSURLSessionResponseDisposition))completionHandler
{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    self.response.readyState = APSHTTPResponseStateHeaders;
    self.response.connected = YES;
    [self.response updateResponseParamaters:response];
    if(self.response.status == 0) {
        [self URLSession:self.session didBecomeInvalidWithError:
         [NSError errorWithDomain:self.response.location
                             code:self.response.status
                         userInfo:@{NSLocalizedDescriptionKey: [NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse*)response statusCode]]}
          ]];
        return;
    }
    self.expectedDownloadResponseLength = response.expectedContentLength;
    [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    completionHandler(disposition);
}

-(void)URLSession:(nonnull NSURLSession *)session dataTask:(nonnull NSURLSessionDataTask *)dataTask didReceiveData:(nonnull NSData *)data
{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    if([self.response readyState] != APSHTTPResponseStateLoading) {
        [self.response setReadyState:APSHTTPResponseStateLoading];
        [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];
    }
    [self.response appendData:data];
    self.response.downloadProgress = (float)self.response.responseLength / (float)self.expectedDownloadResponseLength;
    [self invokeCallbackWithState:APSHTTPCallbackStateDataStream];
}

-(void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    if(self.response.readyState != APSHTTPResponseStateLoading) {
        self.response.readyState = APSHTTPResponseStateLoading;
        [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];
        
    }
    self.response.uploadProgress = (float)totalBytesSent / (float)totalBytesExpectedToSend;
    [self invokeCallbackWithState:APSHTTPCallbackStateSendStream];
}

-(void)responseFinished
{
    [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];
    
    [self invokeCallbackWithState:APSHTTPCallbackStateSendStream];
    
    [self invokeCallbackWithState:APSHTTPCallbackStateDataStream];
    
    [self invokeCallbackWithState:APSHTTPCallbackStateLoad];
}

-(void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    if (error != NULL) {
        DebugLog(@"%s", __PRETTY_FUNCTION__);
        self.response.readyState = APSHTTPResponseStateDone;
        [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];
        
        self.response.connected = NO;
        self.response.error = error;
        [self invokeCallbackWithState:APSHTTPCallbackStateError];
        return;
    }
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    self.response.downloadProgress = 1.f;
    self.response.uploadProgress = 1.f;
    self.response.readyState = APSHTTPResponseStateDone;
    self.response.connected = NO;
    
    [self responseFinished];
}

- (void)URLSession:(nonnull NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    self.response.readyState = APSHTTPResponseStateDone;
    [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];
    
    self.response.connected = NO;
    self.response.error = error;
    [self invokeCallbackWithState:APSHTTPCallbackStateError];
    
}

-(void)invokeCallbackWithState:(APSHTTPCallbackState)state
{
    switch (state) {
        case APSHTTPCallbackStateReadyState:
            if([self.delegate respondsToSelector:@selector(request:onReadyStateChange:)]) {
                [self.delegate request:self onReadyStateChange:self.response];
            }
            break;
        case APSHTTPCallbackStateLoad:
            if([self.delegate respondsToSelector:@selector(request:onLoad:)]) {
                [self.delegate request:self onLoad:self.response];
            }
            break;
        case APSHTTPCallbackStateSendStream:
            if([self.delegate respondsToSelector:@selector(request:onSendStream:)]) {
                [self.delegate request:self onSendStream:self.response];
            }
            break;
        case APSHTTPCallbackStateDataStream:
            if([self.delegate respondsToSelector:@selector(request:onDataStream:)]) {
                [self.delegate request:self onDataStream:self.response];
            }
            break;
        case APSHTTPCallbackStateError:
            if([self.delegate respondsToSelector:@selector(request:onError:)]) {
                [self.delegate request:self onError:self.response];
            }
            break;
        case APSHTTPCallbackStateRedirect:
            if([self.delegate respondsToSelector:@selector(request:onRedirect:)]) {
                [self.delegate request:self onRedirect:self.response];
            }
            break;
        default:
            break;
    }
}
@end
