/**
 * Appcelerator APSHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
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

@interface APSHTTPRequest () <NSURLConnectionDataDelegate>

@property(nonatomic, strong, readonly ) NSMutableURLRequest *request;
@property(nonatomic, assign, readwrite) long long           expectedDownloadResponseLength;
@property(nonatomic, strong, readwrite) NSURLConnection     *connection;
@property(nonatomic, strong, readonly ) NSMutableDictionary *headers;

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
    if(self.connection != nil) {
        [self.connection cancel];
        [self connection:self.connection didFailWithError:
         [NSError errorWithDomain:@"APSHTTPErrorDomain"
                             code:APSRequestErrorCancel
                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"The request was cancelled",NSLocalizedDescriptionKey,nil]]
         ];
    }
}


-(void)send
{
    assert(self.url != nil);
    assert(self.method != nil);
    assert(self.response != nil);
    assert(self.response.readyState == APSHTTPResponseStateUnsent);

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
        NSURLResponse *response;
        NSError *error = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:self.request returningResponse:&response error:&error];
        [self.response appendData:responseData];
        [self.response updateResponseParamaters:response];
        [self.response setError:error];
        [self.response updateRequestParamaters:self.request];
        [self.response setReadyState:APSHTTPResponseStateDone];
        [self.response setConnected:NO];
    } else {
        [self.response updateRequestParamaters:self.request];
        [self.response setReadyState:APSHTTPResponseStateOpened];
        [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];
        
        self.connection = [[NSURLConnection alloc] initWithRequest: self.request
                                                      delegate: self
                                              startImmediately: NO
                               ];
        
        if(self.theQueue) {
            [self.connection setDelegateQueue:[self theQueue]];
        } else {
            
            /*
             If caller specifies runModes with which to specify the connection use those,
             otherwise just configure to run in NSDefaultRunLoopMode (Default).
             It is the callers responsibility to keep calling thread and runloop alive.
            */
            if (self.runModes.count == 0) {
                self.runModes = @[NSDefaultRunLoopMode];
            }
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            for (NSString *runLoopMode in self.runModes) {
                [self.connection scheduleInRunLoop:runLoop forMode:runLoopMode];
            }
        }
        [self.connection start];
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

-(BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
	if(self.connectionDelegate != nil && [self.connectionDelegate respondsToSelector:@selector(connectionShouldUseCredentialStorage:)]) {
		return [self.connectionDelegate connectionShouldUseCredentialStorage:connection];
	}
	return YES;
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    DebugLog(@"%s", __PRETTY_FUNCTION__);

    BOOL useSubDelegate = (self.connectionDelegate != nil && [self.connectionDelegate respondsToSelector:@selector(connection:willSendRequestForAuthenticationChallenge:)]);
    
    if(useSubDelegate && [self.connectionDelegate respondsToSelector:@selector(willHandleChallenge:forConnection:)]) {
        useSubDelegate = [self.connectionDelegate willHandleChallenge:challenge forConnection:connection];
    }
    
    if(useSubDelegate) {
        @try {
            [self.connectionDelegate connection:connection willSendRequestForAuthenticationChallenge:challenge];
        }
        @catch (NSException *exception) {
            if (self.connection != nil) {
                [self.connection cancel];
                
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
                

                
                [self connection:self.connection didFailWithError:error];
            }
        }
        @finally {
            //Do nothing
        }
        return;
    }

    if (challenge.previousFailureCount) {
        [challenge.sender cancelAuthenticationChallenge:challenge];
    }
    
    NSString* authMethod = challenge.protectionSpace.authenticationMethod;
    BOOL handled = NO;
    if ([authMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ( ([challenge.protectionSpace.host isEqualToString:self.url.host]) && (!self.validatesSecureCertificate) ){
            handled = YES;
            [challenge.sender useCredential:
             [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]
                   forAuthenticationChallenge:challenge];
        }
    } else if ( [authMethod isEqualToString:NSURLAuthenticationMethodDefault] || [authMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]
               || [authMethod isEqualToString:NSURLAuthenticationMethodNTLM] || [authMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]) {
        if(self.requestPassword != nil && self.requestUsername != nil) {
            handled = YES;
            [challenge.sender useCredential:
             [NSURLCredential credentialWithUser:self.requestUsername
                                        password:self.requestPassword
                                     persistence:NSURLCredentialPersistenceForSession]
                   forAuthenticationChallenge:challenge];
        }
    }
    
    if (!handled) {
        if ([challenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)]) {
            [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
        } else {
            [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

-(NSURLRequest*)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    DebugLog(@"Code %li Redirecting from: %@ to: %@",(long)[(NSHTTPURLResponse*)response statusCode], [self.request URL] ,[request URL]);
    self.response.connected = YES;
    [self.response updateResponseParamaters:response];
    if (!self.redirects && self.response.status != 0) {
        return nil;
    }
    [self.response updateRequestParamaters:request];
    [self invokeCallbackWithState:APSHTTPCallbackStateRedirect];
    
    //http://tewha.net/2012/05/handling-302303-redirects/
    if (response) {
        NSMutableURLRequest *r = [self.request mutableCopy];
        r.URL = request.URL;
        return r;
    } else {
        return request;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    self.response.readyState = APSHTTPResponseStateHeaders;
    self.response.connected = YES;
    [self.response updateResponseParamaters:response];
    if(self.response.status == 0) {
        [self connection:connection
        didFailWithError:[NSError errorWithDomain:self.response.location
                                             code:self.response.status
                                         userInfo:@{NSLocalizedDescriptionKey: [NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse*)response statusCode]]}
                          ]];
        return;
    }
    self.expectedDownloadResponseLength = response.expectedContentLength;
    
    [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
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

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if(self.response.readyState != APSHTTPResponseStateLoading) {
        self.response.readyState = APSHTTPResponseStateLoading;
        [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];

    }
    self.response.uploadProgress = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    [self invokeCallbackWithState:APSHTTPCallbackStateSendStream];

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    DebugLog(@"%s", __PRETTY_FUNCTION__);
    self.response.downloadProgress = 1.f;
    self.response.uploadProgress = 1.f;
    self.response.readyState = APSHTTPResponseStateDone;
    self.response.connected = NO;
     
    [self invokeCallbackWithState:APSHTTPCallbackStateReadyState];

    [self invokeCallbackWithState:APSHTTPCallbackStateSendStream];

    [self invokeCallbackWithState:APSHTTPCallbackStateDataStream];

    [self invokeCallbackWithState:APSHTTPCallbackStateLoad];

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if(self.connectionDelegate != nil && [self.connectionDelegate respondsToSelector:@selector(connection:didFailWithError:)]) {
		[self.connectionDelegate connection:connection didFailWithError:error];
	}
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
