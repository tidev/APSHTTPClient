/**
 * Appcelerator TiHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#ifndef RELEASE_TO_NIL
#define RELEASE_TO_NIL(x) { if (x!=nil) { [x release]; x = nil; } }
#endif

#ifndef DeveloperLog
#if DEBUG
#define DeveloperLog(...) { NSLog(__VA_ARGS__); }
#else
#define DeveloperLog(...) { }
#endif
#endif

#ifndef DebugLog
#if DEBUG
#define DebugLog(...) { NSLog(__VA_ARGS__); }
#else
#define DebugLog(...) { }
#endif
#endif

#import "TiHTTPRequest.h"
#import "TiHTTPResponse.h"
#import "TiHTTPPostForm.h"
#import "TiHTTPOperation.h"
#import "TiHTTPHelper.h"
