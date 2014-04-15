/**
 * Appcelerator AppCHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <Foundation/Foundation.h>

typedef enum {
	TiRequestAuthNone = 0,
	TiRequestAuthBasic = 1,
	TiRequestAuthDigest = 2,
    TiRequestAuthChallange = 3
} TiRequestAuth;

typedef enum {
	TiRequestErrorCancel = 0
} TiRequestError;


@class AppCHTTPResponse;
@class AppCHTTPRequest;
@class AppCHTTPPostForm;
@class AppCHTTPOperation;

@protocol AppCHTTPRequestDelegate <NSObject>
@optional
-(void)tiRequest:(AppCHTTPRequest*)request onLoad:(AppCHTTPResponse*)tiResponse;
-(void)tiRequest:(AppCHTTPRequest*)request onError:(AppCHTTPResponse*)tiResponse;
-(void)tiRequest:(AppCHTTPRequest*)request onDataStream:(AppCHTTPResponse*)tiResponse;
-(void)tiRequest:(AppCHTTPRequest*)request onSendStream:(AppCHTTPResponse*)tiResponse;
-(void)tiRequest:(AppCHTTPRequest*)request onReadyStateChage:(AppCHTTPResponse*)tiResponse;
-(void)tiRequest:(AppCHTTPRequest*)request onRedirect:(AppCHTTPResponse*)tiResponse;

@end

@interface AppCHTTPRequest : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    long long _expectedDownloadResponseLength;
    NSURLConnection *_connection;
    NSMutableDictionary *_headers;
    AppCHTTPOperation* _operation;
}

@property(nonatomic, readonly) NSMutableURLRequest *request;
@property(nonatomic, retain) NSURL *url;
@property(nonatomic, retain) NSString *method;
@property(nonatomic, retain) NSString *filePath;
@property(nonatomic, retain) NSString *requestUsername;
@property(nonatomic, retain) NSString *requestPassword;
@property(nonatomic, retain) AppCHTTPPostForm *postForm;
@property(nonatomic, readonly) AppCHTTPResponse* response;
@property(nonatomic, assign) NSObject<AppCHTTPRequestDelegate>* delegate;
@property(nonatomic) NSTimeInterval timeout;
@property(nonatomic) BOOL sendDefaultCookies;
@property(nonatomic) BOOL redirects;
@property(nonatomic) BOOL synchronous;
@property(nonatomic) BOOL validatesSecureCertificate;
@property(nonatomic) BOOL cancelled;
@property(nonatomic) TiRequestAuth authType;
@property(nonatomic, retain) NSOperationQueue *theQueue;
@property(nonatomic, retain) NSDictionary *userInfo;
-(void)send;
-(void)abort;
-(void)addRequestHeader:(NSString*)key value:(NSString*)value;
-(void)setCachePolicy:(NSURLRequestCachePolicy)cache;
-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error;
-(NSURLConnection*)connection;
@end
