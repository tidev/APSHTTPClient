/**
 * Appcelerator APSHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "APSHTTPClient.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation APSHTTPPostForm {
    NSMutableDictionary *_requestFormDictionay;
    NSMutableArray *_requestFilesArray;
    NSMutableDictionary *_headers;
    NSMutableData *_postFormData;
    NSData *_jsonData;
    NSData *_stringData;
}


-(void)appendStringData:(NSString*)str
{
    [[self postFormData] appendData:[str dataUsingEncoding: NSUTF8StringEncoding]];
}

-(void)appendData:(NSData*)data
{
    [[self postFormData] appendData: data];
}
-(void)appendData:(NSData *)data withContentType:(NSString *)contentType
{
    _contentType = [contentType copy];
    [[self postFormData] appendData: data];
}

-(void)buildStringPostData
{
	NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));

    [self addHeaderKey:@"Content-Type" andHeaderValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded; charset=%@", charset]];
	BOOL last = NO;
    NSArray *allKeys = [[self requestFormDictionay] allKeys];
    for(NSInteger i = 0, len = [allKeys count]; i < len; i++)
    {
        if(i == len - 1) {
            last = YES;
        }
        NSString *key = [allKeys objectAtIndex:i];
        [self appendStringData:[NSString stringWithFormat:@"%@=%@%@",
                          [APSHTTPHelper encodeURL:key],
                          [APSHTTPHelper encodeURL: [[self requestFormDictionay] valueForKey:key]],
                          (last ?  @"" : @"&")
                          ]
         ];

    }
    

}

-(void)buildFilePostData
{
    NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    NSString *boundary = [NSString stringWithFormat:@"0xTibOuNdArY_%i", (int)[[NSDate date] timeIntervalSince1970]];
    [self addHeaderKey:@"Content-Type" andHeaderValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]];
    if (_jsonData != nil) {
        [self appendStringData:[NSString stringWithFormat:@"--%@\r\n",boundary]];
        [self appendStringData: @"Content-Disposition: form-data; name=\"json\"\n"];
        [self appendStringData: [NSString stringWithFormat:@"Content-Type:application/json;charset=\"%@\"\r\n", charset]];
        [self appendStringData:@"\r\n"];
        [self appendData:_jsonData];
        [self appendStringData:@"\r\n"];
        // Content-Disposition: form-data; name="json"
        // Content-Type: application/json; charset=utf-8
        //
        // --0xTibOuNdArY
    }
    NSArray *allKeys = [[self requestFormDictionay] allKeys];
    NSInteger fileCount = [[self requestFilesArray] count];
    BOOL last = NO;

    for(NSInteger i = 0, len = [allKeys count]; i < len; i++)
    {
        if(i == len - 1 && fileCount == 0) {
            last = YES;
        }
        NSString *key = [allKeys objectAtIndex:i];
        [self appendStringData:[NSString stringWithFormat:@"--%@\r\n",boundary]];
        [self appendStringData: [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n", key]];
        [self appendStringData: [NSString stringWithFormat:@"Content-Type:text/plain;charset=\"%@\"\r\n", charset]];
        [self appendStringData:@"\r\n"];
        [self appendStringData:[NSString stringWithFormat:@"%@\r\n", [[self requestFormDictionay] valueForKey:key]]];
        if (last == YES) {
            [self appendStringData:[NSString stringWithFormat:@"--%@--\r\n", boundary]];
        }
         // Content-Disposition: form-data; name="username"
         //
         // pec1985
         // --0xTibOuNdArY
    }

    for(NSInteger i = 0; i < fileCount; i++)
    {
        if(i == fileCount - 1) {
            last = YES;
        }
        NSDictionary *dict = [[self requestFilesArray] objectAtIndex:i];
        [self appendStringData:[NSString stringWithFormat:@"--%@\r\n",boundary]];
        [self appendStringData: [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [dict valueForKey:@"fileField"], [dict valueForKey:@"fileName"]]];
		[self appendStringData: [NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", [dict objectForKey:@"contentType"]]];
        [self appendData:[dict valueForKey:@"fileData"]];
        [self appendStringData:@"\r\n"];        
        if (last == YES) {
            [self appendStringData:[NSString stringWithFormat:@"--%@--\r\n", boundary]];
        }
        // Content-Disposition: form-data; name="file[0]"; filename="image.jpg"
        // Content-Type: imgae/jpeg
        //
        // [binary data]
        // --0xTibOuNdArY
    }
}

-(NSData*)requestData
{
    NSInteger fileCount = [[self requestFilesArray] count];
    if(fileCount != 0) {
        //for multipart
        [self buildFilePostData];
        [self addHeaderKey:@"Content-Length" andHeaderValue:[NSString stringWithFormat:@"%lu", (unsigned long)[_postFormData length]]];
        return [self postFormData];
    }
    if(_postFormData != nil && _contentType != nil) {
        [self addHeaderKey:@"Content-Type" andHeaderValue: _contentType];
    }
    else if(_stringData != nil) {
        [self appendData:_stringData];
    }
    else if(_jsonData != nil) {
        [self appendData:_jsonData];
        [self addHeaderKey:@"Content-Type" andHeaderValue:@"application/json;charset=utf-8"];
    }
    else {
        [self buildStringPostData];
    }
    [self addHeaderKey:@"Content-Length" andHeaderValue:[NSString stringWithFormat:@"%lu", (unsigned long)[_postFormData length]]];
    return [self postFormData];
}
-(NSMutableData*)postFormData
{
    if(_postFormData == nil) {
        _postFormData = [[NSMutableData alloc] init];
    }
    return _postFormData;
}
-(NSDictionary*)requestHeaders
{
    return [_headers copy];
}

-(NSMutableDictionary*)requestFormDictionay
{
    if(_requestFormDictionay == nil) {
        _requestFormDictionay = [[NSMutableDictionary alloc] init];
    }
    return _requestFormDictionay;
}
-(NSMutableArray*)requestFilesArray
{
    if(_requestFilesArray == nil) {
        _requestFilesArray = [[NSMutableArray alloc] init];
    }
    return _requestFilesArray;
}
-(NSMutableDictionary*)headers
{
    if(_headers == nil) {
        _headers = [[NSMutableDictionary alloc] init];
    }

    return _headers;
}

-(void)setJSONData:(id)json
{
    NSError *error = nil;
    _jsonData = [NSJSONSerialization dataWithJSONObject:json options:kNilOptions error:&error];
    if(error != nil) {
        NSLog(@"Error reading JSON: %@", [error localizedDescription]);
    }
}

-(void)setStringData:(NSString *)str
{
    _stringData = [str dataUsingEncoding: NSUTF8StringEncoding];
}

-(void)addDictionay:(NSDictionary*)dict
{
    [[self requestFormDictionay] setValuesForKeysWithDictionary:dict];
}

-(void)addFormKey:(NSString*)key andValue:(NSString*)value
{
	[[self requestFormDictionay] setValue:value forKey:key];
}

-(void)addFormFile:(NSString*)path;
{
    [self addFormFile:path fieldName:[NSString stringWithFormat:@"file%i", (unsigned int)[[self requestFilesArray] count]]];
}

-(void)addFormFile:(NSString*)path fieldName:(NSString*)name;
{
    [self addFormFile:path fieldName:name contentType:[APSHTTPHelper fileMIMEType:path]];
}

-(void)addFormFile:(NSString*)path fieldName:(NSString*)name contentType:(NSString*)contentType
{
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    if(fileData == nil) {
#ifdef DEBUG
		NSLog(@"%s Cannot find file %@", __PRETTY_FUNCTION__, path);
#endif
        return;
    }
    NSString *fileName = [[path componentsSeparatedByString:@"/"] lastObject];
    
    [self addFormData:fileData fileName:fileName fieldName:name contentType:contentType];
}


-(void)addFormData:(NSData*)data
{
    [self addFormData:data
             fileName:[NSString stringWithFormat:@"file[%i]", (unsigned int)[[self requestFilesArray] count]]
     ];
}
-(void)addFormData:(NSData*)data fileName:(NSString*)fileName
{
    [self addFormData: data
             fileName: fileName
            fieldName: [NSString stringWithFormat:@"file[%i]", (unsigned int)[[self requestFilesArray] count]]
     ];

}
-(void)addFormData:(NSData*)data fileName:(NSString*)fileName fieldName:(NSString*)fieldName
{
    [self addFormData: data
             fileName: fileName
            fieldName: fieldName
          contentType: [APSHTTPHelper contentTypeForImageData:data]
     ];

}
-(void)addFormData:(NSData*)data fileName:(NSString*)fileName fieldName:(NSString*)fieldName contentType:(NSString*)contentType
{
    [[self requestFilesArray] addObject:@{
                                          @"fileField": fieldName,
                                          @"fileName" : fileName,
                                          @"fileData" : data,
                                          @"contentType" : contentType
                                          }];
}

-(void)addHeaderKey:(NSString*)key andHeaderValue:(NSString*)value
{
    if (key == nil) {
        DebugLog(@"Ignore request to %s. key is nil.", __PRETTY_FUNCTION__);
        return;
    }
    
    if (value == nil) {
        DebugLog(@"Remove header for key %@.", key);
        [self.headers removeObjectForKey:key];
    } else {
        self.headers[key] = value;
    }
}

@end
