# APSHTTPClient ChangeLog #


### Version 1.0 ###

* Implements existing functionality for the Titanium SDK. See http://docs.appcelerator.com/titanium/latest/#!/api/Titanium.Network.HTTPClient
* [TIMOB-16855] - Support custom NSURLConnectionDelegate in APSHTTPClient

### Version 1.1 ###

* Minor bug fix. Add support for NSURLAuthenticationMethodHTTPDigest

### Version 1.2 ###

* [TIMOB-18341] - Fix malformed Content-Type error with modsecurity

### Version 1.3 ###

* [TIMOB-18129] - Handle thrown exceptions from connection delegate

### Version 1.4 ###

* [TIMOB-18838] - Fix Content-Type definition of multipart/form-data

### Version 1.5 ###

* [TIMOB-17573] - Support multiple cookies in Request Header

### Version 1.6 ###

* [TIMOB-18902] - Support JSON in multipart post

### Version 1.7 ###

* [TIMOB-19154] - Deprecate NSURLConnection and use NSURLSession instead

### Version 1.8 ###

* [TIMOB-19390] - Rebuild SDK Dependent libs to support bitcode

### Version 1.9 ###

* [TIMOB-19609] - Remove "pcm missing" warnings

### Version 1.10 ###

* [TIMOB-20048] - Revert to nsurlconnection