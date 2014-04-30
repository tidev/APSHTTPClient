/**
 * Appcelerator APSHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "APSHTTPClient.h"

@implementation APSHTTPRequest
@synthesize url = _url;
@synthesize method = _method;
@synthesize response = _response;
@synthesize filePath = _filePath;
@synthesize requestPassword = _requestPassword;
@synthesize requestUsername = _requestUsername;

- (void)dealloc
{
    RELEASE_TO_NIL(_connection);
    RELEASE_TO_NIL(_request);
    RELEASE_TO_NIL(_response);
    RELEASE_TO_NIL(_url);
    RELEASE_TO_NIL(_method);
    RELEASE_TO_NIL(_filePath);
    RELEASE_TO_NIL(_requestUsername);
    RELEASE_TO_NIL(_requestPassword);
    RELEASE_TO_NIL(_postForm);
    RELEASE_TO_NIL(_operation);
    RELEASE_TO_NIL(_userInfo);
    RELEASE_TO_NIL(_headers);
    [super dealloc];
}
- (id)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

-(void)initialize
{
    [self setSendDefaultCookies:YES];
    [self setRedirects:YES];
    [self setValidatesSecureCertificate: YES];
    
    _request = [[NSMutableURLRequest alloc] init];
    [_request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    _response = [[APSHTTPResponse alloc] init];
    [_response setReadyState: APSHTTPResponseStateUnsent];
}

-(void)abort
{
    [self setCancelled:YES];
    if(_operation != nil) {
        [_operation cancel];
    } else if(_connection != nil) {
        [_connection cancel];
        [self connection:_connection didFailWithError:
         [NSError errorWithDomain:@"APSHTTPErrorDomain"
                             code:APSRequestErrorCancel
                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"The request was cancelled",NSLocalizedDescriptionKey,nil]]
         ];
    }
}

-(NSURLConnection*)connection
{
    return _connection;
}

-(void)send
{
    if([self filePath]) {
        [_response setFilePath:[self filePath]];
    }
    if([self postForm] != nil) {
        NSData *data = [[self postForm] requestData];
        if([data length] > 0) {
            [_request setHTTPBody:data];
        }
#ifdef DEBUG
        NSLog(@"Data: %@", [NSString stringWithUTF8String: [data bytes]]);
#endif
        NSDictionary *headers = [[self postForm] requestHeaders];
        for (NSString* key in headers)
        {
            [_request setValue:[headers valueForKey:key] forHTTPHeaderField:key];
#ifdef DEBUG
            NSLog(@"Header: %@: %@", key, [headers valueForKey:key]);
#endif
        }
    }
    if(_headers != nil) {
        for (NSString* key in _headers)
        {
            [_request setValue:[_headers valueForKey:key] forHTTPHeaderField:key];
#ifdef DEBUG
            NSLog(@"Header: %@: %@", key, [_headers valueForKey:key]);
#endif
        }
    }
#ifdef DEBUG
    NSLog(@"URL: %@", [self url]);
#endif
    [_request setURL: [self url]];
    
    if([self timeout] > 0) {
        [_request setTimeoutInterval:[self timeout]];
    }
    if([self method] != nil) {
        [_request setHTTPMethod: [self method]];
#ifdef DEBUG
        NSLog(@"Method: %@", [self method]);
#endif
    }
    [_request setHTTPShouldHandleCookies:[self sendDefaultCookies]];
    
    if([self synchronous]) {
        if([self requestUsername] != nil && [self requestPassword] != nil && [_request valueForHTTPHeaderField:@"Authorization"] == nil) {
            NSString *authString = [APSHTTPHelper base64encode:[[NSString stringWithFormat:@"%@:%@",[self requestUsername], [self requestPassword]] dataUsingEncoding:NSUTF8StringEncoding]];
            [_request setValue:[NSString stringWithFormat:@"Basic %@", authString] forHTTPHeaderField:@"Authorization"];
        }
        NSURLResponse *response;
        NSError *error = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:_request returningResponse:&response error:&error];
        [_response appendData:responseData];
        [_response setResponse:response];
        [_response setError:error];
        [_response setRequest:_request];
        [_response setReadyState:APSHTTPResponseStateDone];
        [_response setConnected:NO];
    } else {
        [_response setRequest:_request];
        [_response setReadyState:APSHTTPResponseStateOpened];
        if([_delegate respondsToSelector:@selector(request:onReadyStateChage:)]) {
            [_delegate request:self onReadyStateChage:_response];
        }
        
        _connection = [[NSURLConnection alloc] initWithRequest: _request
                                                      delegate: self
                                              startImmediately: NO
                               ];
        
        if([self theQueue]) {
            RELEASE_TO_NIL(_operation);
            _operation = [[APSHTTPOperation alloc] initWithConnection: self];
            [_operation setIndex:[[self theQueue] operationCount]];
            [[self theQueue] addOperation: _operation];
           
        } else {
            [_connection start];
        }
    }
    
}

-(void)setCachePolicy:(NSURLRequestCachePolicy)cache
{
    [_request setCachePolicy:cache];
}

-(void)addRequestHeader:(NSString *)key value:(NSString *)value
{
    if(_headers == nil) {
        _headers = [[NSMutableDictionary alloc] init];
    }
    [_headers setValue:value forKey:key];
}

-(BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
	if([self connectionDelegate] != nil && [[self connectionDelegate] respondsToSelector:@selector(connectionShouldUseCredentialStorage:)]) {
		return [[self connectionDelegate] connectionShouldUseCredentialStorage:connection];
	}
	return YES;
}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    BOOL useSubDelegate = ([self connectionDelegate] != nil && [[self connectionDelegate] respondsToSelector:@selector(connection:willSendRequestForAuthenticationChallenge:)]);
    
    if(useSubDelegate && [[self connectionDelegate] respondsToSelector:@selector(willHandleChallenge:forConnection:)]) {
        useSubDelegate = [[self connectionDelegate] willHandleChallenge:challenge forConnection:connection];
    }
    
    if(useSubDelegate) {
        [[self connectionDelegate] connection:connection willSendRequestForAuthenticationChallenge:challenge];
        return;
    }

    if ([challenge previousFailureCount]) {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
    
    NSString* authMethod = [[[[challenge protectionSpace] authenticationMethod] retain] autorelease];
    BOOL handled = NO;
    if ([authMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ( ([challenge.protectionSpace.host isEqualToString:[[self url] host]]) && (![self validatesSecureCertificate]) ){
            handled = YES;
            [[challenge sender] useCredential:
             [NSURLCredential credentialForTrust: [[challenge protectionSpace] serverTrust]]
                   forAuthenticationChallenge: challenge];
        }
    } else if ( [authMethod isEqualToString:NSURLAuthenticationMethodDefault] || [authMethod isEqualToString:NSURLAuthenticationMethodHTTPBasic]
               || [authMethod isEqualToString:NSURLAuthenticationMethodNTLM] || [authMethod isEqualToString:NSURLAuthenticationMethodHTTPDigest]) {
        if([self requestPassword] != nil && [self requestUsername] != nil) {
            handled = YES;
            [[challenge sender] useCredential:
             [NSURLCredential credentialWithUser:[self requestUsername]
                                        password:[self requestPassword]
                                     persistence:NSURLCredentialPersistenceForSession]
                   forAuthenticationChallenge:challenge];
        }
    }
    
    if (!handled) {
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

-(NSURLRequest*)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
#ifdef DEBUG
    NSLog(@"Code %li Redirecting from: %@ to: %@",(long)[(NSHTTPURLResponse*)response statusCode], [_request URL] ,[request URL]);
#endif
    [_response setConnected:YES];
    [_response setResponse: response];
    [_response setRequest:request];

    if([[self delegate] respondsToSelector:@selector(request:onRedirect:)])
    {
        [[self delegate] request:self onRedirect:_response];
    }
    if(![self redirects] && [_response status] != 0)
    {
        return nil;
    }
    
    //http://tewha.net/2012/05/handling-302303-redirects/
    if (response) {
        NSMutableURLRequest *r = [[_request mutableCopy] autorelease];
        [r setURL: [request URL]];
        RELEASE_TO_NIL(_request);
        _request = [r retain];
        return r;
    } else {
        return request;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    [_response setReadyState:APSHTTPResponseStateHeaders];
    [_response setConnected:YES];
    [_response setResponse: response];
    if([_response status] == 0) {
        [self connection:connection
        didFailWithError:[NSError errorWithDomain: [_response location]
                                             code: [_response status]
                                         userInfo: @{NSLocalizedDescriptionKey: [NSHTTPURLResponse localizedStringForStatusCode:[(NSHTTPURLResponse*)response statusCode]]}
                          ]];
        return;
    }
    _expectedDownloadResponseLength = [response expectedContentLength];
    
    if([_delegate respondsToSelector:@selector(request:onReadyStateChage:)]) {
        [_delegate request:self onReadyStateChage:_response];
    }

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    if([_response readyState] != APSHTTPResponseStateLoading) {
        [_response setReadyState:APSHTTPResponseStateLoading];
        if([_delegate respondsToSelector:@selector(request:onReadyStateChage:)]) {
            [_delegate request:self onReadyStateChage:_response];
        }
    }
    [_response appendData:data];
    [_response setDownloadProgress: (float)[_response responseLength] / (float)_expectedDownloadResponseLength];
    if([_delegate respondsToSelector:@selector(request:onDataStream:)]) {
        [_delegate request:self onDataStream:_response];
    }
    
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    if([_response readyState] != APSHTTPResponseStateLoading) {
        [_response setReadyState:APSHTTPResponseStateLoading];
        if([_delegate respondsToSelector:@selector(request:onReadyStateChage:)]) {
            [_delegate request:self onReadyStateChage:_response];
        }
    }
    [_response setUploadProgress: (float)totalBytesWritten / (float)totalBytesExpectedToWrite];
    if([_delegate respondsToSelector:@selector(request:onSendStream:)]) {
        [_delegate request:self onSendStream:_response];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if(_operation != nil) {
        [_operation setFinished:YES];
    }
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    [_response setDownloadProgress:1.f];
    [_response setUploadProgress:1.f];
    [_response setReadyState:APSHTTPResponseStateDone];
    [_response setConnected:NO];
     
    if([_delegate respondsToSelector:@selector(request:onReadyStateChage:)]) {
        [_delegate request:self onReadyStateChage:_response];
    }
    if([_delegate respondsToSelector:@selector(request:onSendStream:)]) {
        [_delegate request:self onSendStream:_response];
    }
    if([_delegate respondsToSelector:@selector(request:onDataStream:)]) {
        [_delegate request:self onDataStream:_response];
    }
    if([_delegate respondsToSelector:@selector(request:onLoad:)]) {
        [_delegate request:self onLoad:_response];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if([self connectionDelegate] != nil && [[self connectionDelegate] respondsToSelector:@selector(connection:didFailWithError:)]) {
		[[self connectionDelegate] connection:connection didFailWithError:error];
	}
    if(_operation != nil) {
        [_operation setFinished:YES];
    }
#ifdef DEBUG
    NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
    [_response setReadyState:APSHTTPResponseStateDone];
    if([_delegate respondsToSelector:@selector(request:onReadyStateChage:)]) {
        [_delegate request:self onReadyStateChage:_response];
    }
    [_response setConnected:NO];
    [_response setError:error];
    if([_delegate respondsToSelector:@selector(request:onError:)]) {
        [_delegate request:self onError:_response];
    }
}

@end