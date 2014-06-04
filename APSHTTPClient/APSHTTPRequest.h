/**
 * Appcelerator APSHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, APSRequestAuth) {
	APSRequestAuthNone = 0,
	APSRequestAuthBasic = 1,
	APSRequestAuthDigest = 2,
    APSRequestAuthChallange = 3
};

typedef NS_ENUM(NSInteger, APSRequestError) {
	APSRequestErrorCancel = 0
};


@class APSHTTPResponse;
@class APSHTTPRequest;
@class APSHTTPPostForm;

@protocol APSConnectionDelegate <NSURLConnectionDelegate>
@optional
-(BOOL)willHandleChallenge:(NSURLAuthenticationChallenge *)challenge forConnection:(NSURLConnection *)connection;
@end

@protocol APSHTTPRequestDelegate <NSObject>
@optional
-(void)request:(APSHTTPRequest*)request onLoad:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onError:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onDataStream:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onSendStream:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onReadyStateChage:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onRedirect:(APSHTTPResponse*)response;

@end

@interface APSHTTPRequest : NSObject

@property(nonatomic, strong, readonly) NSMutableURLRequest *request;
@property(nonatomic, strong) NSURL *url;
@property(nonatomic, strong) NSString *method;
@property(nonatomic, strong) NSString *filePath;
@property(nonatomic, strong) NSString *requestUsername;
@property(nonatomic, strong) NSString *requestPassword;
@property(nonatomic, strong) APSHTTPPostForm *postForm;
@property(nonatomic, strong, readonly) APSHTTPResponse* response;
@property(nonatomic, weak) NSObject<APSHTTPRequestDelegate>* delegate;
@property(nonatomic, weak) NSObject<APSConnectionDelegate>* connectionDelegate;
@property(nonatomic) NSTimeInterval timeout;
@property(nonatomic) BOOL sendDefaultCookies;
@property(nonatomic) BOOL redirects;
@property(nonatomic) BOOL synchronous;
@property(nonatomic) BOOL validatesSecureCertificate;
@property(nonatomic) BOOL cancelled;
@property(nonatomic) APSRequestAuth authType;
@property(nonatomic, strong) NSOperationQueue *theQueue;
@property(nonatomic, strong) NSDictionary *userInfo;
-(void)send;
-(void)abort;
-(void)addRequestHeader:(NSString*)key value:(NSString*)value;
-(void)setCachePolicy:(NSURLRequestCachePolicy)cache;
-(void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error;
-(NSURLConnection*)connection;
@end
