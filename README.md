> **EXPERIMENTAL: DO NOT USE IN PRODUCTION YET.**
# APSHTTPClient

[![Version](https://img.shields.io/cocoapods/v/APSHTTPClient.svg?style=flat)](http://cocoadocs.org/docsets/APSHTTPClient)
[![License](https://img.shields.io/cocoapods/l/APSHTTPClient.svg?style=flat)](http://cocoadocs.org/docsets/APSHTTPClient)
[![Platform](https://img.shields.io/cocoapods/p/APSHTTPClient.svg?style=flat)](http://cocoadocs.org/docsets/APSHTTPClient)

## Usage

Run the library's unit tests from the command line with these commands:

```shell
pushd Test
pod install
popd
rake test
```

Package the library for distribution with this command:

```shell
create_release_folder.sh
```

### Components
**APSHTTPRequest** - Responsible for the http request  
**NSObject\<APSHTTPRequestDelegate\>** - Responsible for the APSHTTPRequest callbacks  
**APSHTTPPostForm** - Used to build a post form  
**APSHTTPResponse** - Holds all the response information from the request  
**APSHTTPHelper** - Helper class with some handy functions

### GET Request:

	// in header
	#import <APSHTTPClient/APSHTTPClient.h>

    -(void)sendRequest
    {
        APSHTTPRequest *request = [[[APSHTTPRequest alloc] init] autorelease];
        [request setDelegate:self];
        [request setMethod: @"GET"];
        [request setUrl:[NSURL URLWithString: @"http://google.com/"]];
        [request send];
    }

    -(void)tiRequest:(APSHTTPRequest *)request onLoad:(APSHTTPResponse *)response
    {
        NSString* response = [response responseString];
    }
    
    -(void)tiRequest:(APSHTTPRequest *)request onError:(APSHTTPResponse *)response
    {
        NSString* errorMessage = [[response error] localizedDescription];
    }

### POST Request:

	// in header
	#import <APSHTTPClient/APSHTTPClient.h>

    -(void)sendRequest
    {
        APSHTTPPostForm *form = [[[APSHTTPPostForm alloc] init] autorelease];
        [form addFormKey:@"first_name" andValue: @"John"];
        [form addFormKey:@"last_name" andValue: @"Smith"];
        [form addFormData: UIImageJPEGRepresentation([[self myImageView] image], 0.7)
                 fileName:@"image.jpeg"
                fieldName:@"photo"];
    
        APSHTTPRequest *request = [[[APSHTTPRequest alloc] init] autorelease];
        [request setDelegate:self];
        [request setMethod: @"POST"];
        [request setPostForm:form];
        [request setUrl:[NSURL URLWithString: @"http://some_server.com/api/post"]];
        [request send];
    }

    -(void)tiRequest:(APSHTTPRequest *)request onLoad:(APSHTTPResponse *)response
    {
        NSString* response = [response responseString];
    }
    
    -(void)tiRequest:(APSHTTPRequest *)request onError:(APSHTTPResponse *)response
    {
        NSString* errorMessage = [[response error] localizedDescription];
    }

## Requirements

## Installation

APSHTTPClient is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "APSHTTPClient"

## Author

Pedro Enrique, penrique@appcelerator.com
Sabil Rahim, srahim@appcelerator.com
Vishal Duggal, vduggal@appcelerator.com

## License

APSHTTPClient is available under the Apache License, Version 2.0
license. See the LICENSE file for more info.
