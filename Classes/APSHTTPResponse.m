/**
 * Appcelerator APSHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "APSHTTPClient.h"

@interface APSHTTPResponse ()
@property(nonatomic,         readwrite) NSStringEncoding     encoding;
@property(nonatomic,         readwrite) BOOL                 saveToFile;
@property(nonatomic, strong, readonly ) NSURL                *url;
@end

@implementation APSHTTPResponse {
    NSMutableData *_data;
}


- (void) updateResponseParamaters:(NSURLResponse *)response
{
    _url = [response URL];
    if([response isKindOfClass:[NSHTTPURLResponse class]]) {
        _status = [(NSHTTPURLResponse*)response statusCode];
        _headers = [(NSHTTPURLResponse*)response allHeaderFields];
        NSStringEncoding encoding = [APSHTTPHelper parseStringEncodingFromHeaders: _headers];
        encoding = encoding == 0 ? NSUTF8StringEncoding : encoding;
        [self setEncoding: encoding];

    }
}

- (void) updateRequestParamaters:(NSURLRequest *)request
{
    _connectionType = [request HTTPMethod];
    _location = [[request URL] absoluteString];
}

-(void)appendData:(NSData *)data
{
    if([self saveToFile]) {
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:[self filePath]];
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
        [fileHandle closeFile];
    } else {
        if(_data == nil) {
            _data = [[NSMutableData alloc] init];
        }
        [_data appendData:data];
    }
}

-(void)setFilePath:(NSString *)filePath
{
    _filePath = [filePath copy];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL isWritable = NO;
    BOOL isDirectory = NO;
    BOOL fileExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory];
    if(isDirectory) {
        DebugLog(@"[ERROR] %@ is directory, ignoring", filePath); // file path
        return;
    }
    if(fileExists) {
        isWritable = [fileManager isWritableFileAtPath:filePath];
        if(!isWritable) {
            DebugLog(@"[ERROR] %@ is not writable, ignoring", filePath);
            return;
        }
        DebugLog(@"[WARN] %@ already exists, replacing", filePath);
        NSError *deleteError = nil;
        [fileManager removeItemAtPath:filePath error:&deleteError];
        if(deleteError != nil) {
            DebugLog(@"[WARN] Cannot delete %@, error was %@", filePath, [deleteError localizedDescription]);
            return;
        }
    }
    isWritable = [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    [self setSaveToFile: isWritable];
}
-(NSData *)responseData
{
    if(_data == nil) {
        return nil;
    }
    return [_data copy];
}
-(NSInteger)responseLength
{
    if([self saveToFile])
    {
        return (NSInteger)[[[NSFileManager defaultManager] attributesOfItemAtPath:[self filePath] error:nil] fileSize];
    }
    return [[self responseData] length];
}
-(id)jsonResponse
{
    if([self responseData] == nil) return nil;
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData: [self responseData]
                                              options: NSJSONReadingAllowFragments
                                                error: &error];
    if(error != nil) {
#ifdef DEBUG
        NSLog(@"%s - %@", __PRETTY_FUNCTION__, [error localizedDescription]);
#endif
        return nil;
    }
    return json;
}
-(NSString*)responseString
{
    if([self error] != nil) {
#ifdef DEBUG
        NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
        return [[self error] localizedDescription];
    }
    if([self responseData] == nil || [self responseLength] == 0) return nil;
    NSData *data =  [self responseData];
    NSString * result = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:[self encoding]];
    if (result==nil) {
        // encoding failed, probably a bad webserver or content we have to deal
        // with in a _special_ way
        NSStringEncoding encoding = NSUTF8StringEncoding;
        BOOL didExtractEncoding =  [APSHTTPHelper extractEncodingFromData:data result:&encoding];
        if (didExtractEncoding) {
            //If I did extract encoding use that
            result = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:encoding];
        } else {
            result = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSISOLatin1StringEncoding];
        }
            
    }
    return result;
}
-(NSDictionary*)responseDictionary
{
    id json = [self jsonResponse];
    if([json isKindOfClass:[NSDictionary class]]) {
#ifdef DEBUG
        NSLog(@"%s", __PRETTY_FUNCTION__);
#endif
        return (NSDictionary*)json;
    }
#ifdef DEBUG
    NSLog(@"%s - JSON is %@", __PRETTY_FUNCTION__, [[json superclass] description]);
#endif
    return nil;
}
-(NSArray*)responseArray
{
    id json = [self jsonResponse];
    if([json isKindOfClass:[NSArray class]]) {
        return (NSArray*)json;
    }
#ifdef DEBUG
    NSLog(@"%s - JSON is %@", __PRETTY_FUNCTION__, [[json superclass] description]);
#endif
    return nil;
}

@end
