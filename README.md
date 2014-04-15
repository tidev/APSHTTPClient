### Requirements
**MobileCoreServices.framework**

### Components
**AppCHTTPRequest** - Responsible for the http request  
**NSObject\<AppCHTTPRequestDelegate\>** - Responsible for the AppCHTTPRequest callbacks  
**AppCHTTPPostForm** - Used to build a post form  
**AppCHTTPResponse** - Holds all the response information from the request  
**AppCHTTPHelper** - Helper class with some handy functions

### GET Request:

	// in header
	#import <AppCHTTPClient/AppCHTTPClient.h>

    -(void)sendRequest
    {
        AppCHTTPRequest *request = [[[AppCHTTPRequest alloc] init] autorelease];
        [request setDelegate:self];
        [request setMethod: @"GET"];
        [request setUrl:[NSURL URLWithString: @"http://google.com/"]];
        [request send];
    }

    -(void)tiRequest:(AppCHTTPRequest *)request onLoad:(AppCHTTPResponse *)response
    {
        NSString* response = [response responseString];
    }
    
    -(void)tiRequest:(AppCHTTPRequest *)request onError:(AppCHTTPResponse *)response
    {
        NSString* errorMessage = [[response error] localizedDescription];
    }

### POST Request:

	// in header
	#import <AppCHTTPClient/AppCHTTPClient.h>

    -(void)sendRequest
    {
        AppCHTTPPostForm *form = [[[AppCHTTPPostForm alloc] init] autorelease];
        [form addFormKey:@"first_name" andValue: @"John"];
        [form addFormKey:@"last_name" andValue: @"Smith"];
        [form addFormData: UIImageJPEGRepresentation([[self myImageView] image], 0.7)
                 fileName:@"image.jpeg"
                fieldName:@"photo"];
    
        AppCHTTPRequest *request = [[[AppCHTTPRequest alloc] init] autorelease];
        [request setDelegate:self];
        [request setMethod: @"POST"];
        [request setPostForm:form];
        [request setUrl:[NSURL URLWithString: @"http://some_server.com/api/post"]];
        [request send];
    }

    -(void)tiRequest:(AppCHTTPRequest *)request onLoad:(AppCHTTPResponse *)response
    {
        NSString* response = [response responseString];
    }
    
    -(void)tiRequest:(AppCHTTPRequest *)request onError:(AppCHTTPResponse *)response
    {
        NSString* errorMessage = [[response error] localizedDescription];
    }
    
