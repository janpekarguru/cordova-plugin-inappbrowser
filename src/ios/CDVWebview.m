/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVWebview.h"
#import <Cordova/CDVPluginResult.h>
#import <Cordova/CDVUserAgentUtil.h>
#import <foundation/foundation.h>

#define    kInAppBrowserTargetSelf @"_self"
#define    kInAppBrowserTargetSystem @"_system"
#define    kInAppBrowserTargetBlank @"_blank"

#define    kInAppBrowserToolbarBarPositionBottom @"bottom"
#define    kInAppBrowserToolbarBarPositionTop @"top"

#define    TOOLBAR_HEIGHT 44.0
#define    LOCATIONBAR_HEIGHT 21.0
#define    FOOTER_HEIGHT ((TOOLBAR_HEIGHT) + (LOCATIONBAR_HEIGHT))

#pragma mark CDVInAppBrowser

@interface CDVEmbeddedWebView () {
    NSInteger _previousStatusBarStyle;
}
@end

@implementation CDVEmbeddedWebView

- (void)pluginInitialize
{
    _previousStatusBarStyle = -1;
    _callbackIdPattern = nil;
   
    _brw = [NSMutableArray array];
   
    /*for (int i=0;i<6;i++){
        [_brw addObject:[[CDVEmbeddedWebViewPlug alloc]init]];
    }*/
}

- (void)open:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    NSString* i = [command argumentAtIndex:0];
    NSString* url = [command argumentAtIndex:1];
    NSString* options = [command argumentAtIndex:2 withDefault:@"" andClass:[NSString class]];
    
    if (url != nil) {
#ifdef __CORDOVA_4_0_0
        NSURL* baseUrl = [self.webViewEngine URL];
#else
        NSURL* baseUrl = [self.webView.request URL];
#endif
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];
        
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        
        //[self openInWebPlug:absoluteUrl withOptions:options];
        [self openInWebPlug:absoluteUrl index:i CallBack:command.callbackId withOptions:options];
        
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"incorrect number of arguments"];
    }
    
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    self.callbackId = command.callbackId;
}

- (void)load:(CDVInvokedUrlCommand*)command
{
    
    NSString* i = [command argumentAtIndex:0];
    NSString* url = [command argumentAtIndex:1];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    
    if (el == nil) {
        NSLog(@"Tried to load IAB after it was closed.");
        return;
    }
    if (url != nil) {
#ifdef __CORDOVA_4_0_0
        NSURL* baseUrl = [self.webViewEngine URL];
#else
        NSURL* baseUrl = [self.webView.request URL];
#endif
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];
        [el navigateTo:absoluteUrl];
    }
}

- (void)close:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    //if (self.webplug == nil) {
   if (el == nil) {
        NSLog(@"Tried to close IAB after it was closed.");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.webplug removeFromSuperview];
        //self.webplug = nil;
        CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
        [el removeFromSuperview];
        el = nil;
        [self.brw removeObjectAtIndex:i.intValue];
    });
}

- (void)show:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    //if (self.webplug == nil) {
    if (el == nil) {
        NSLog(@"Tried to show IAB after it was closed. Show");
        return;
    }
    //self.webplug.hidden = NO;
    el.hidden = NO;
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    //if (self.webplug == nil) {
    if (el == nil) {
        NSLog(@"Tried to hide IAB after it was closed.");
        return;
    }
    //self.webplug.hidden = YES;
    el.hidden = YES;
}

- (void)setPosition:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    //if (self.webplug == nil) {
    if (el == nil) {
        NSLog(@"Tried to set position for IAB after it was closed.");
        return;
    }
    
    if (command.arguments.count < 3) {
        NSLog(@"Parameters is not long enough.");
        return;
    }
    
    NSString* sl = [command argumentAtIndex:1];
    NSString* st = [command argumentAtIndex:2];
    
    float fl = [sl floatValue];
    float ft = [st floatValue];
    
    //CGRect frame = self.webplug.frame;
    CGRect frame = el.frame;
    frame.origin.x = fl;
    frame.origin.y = ft;
    //self.webplug.frame = frame;
    el.frame = frame;
}

- (void)setSize:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    //if (self.webplug == nil) {
    if (el == nil) {
        NSLog(@"Tried to set size for IAB after it was closed.");
        return;
    }
    if (command.arguments.count < 3) {
        NSLog(@"SET SIZE : Parameters not long enough.");
        return;
    }
    
    NSString* sw = [command argumentAtIndex:1];
    NSString* sh = [command argumentAtIndex:2];
    
    float fw = [sw floatValue];
    float fh = [sh floatValue];
    
    //CGRect frame = self.webplug.frame;
    CGRect frame = el.frame;
    frame.size.width = fw;
    frame.size.height = fh;
    //self.webplug.frame = frame;
    el.frame = frame;
}

- (void)openInWebPlug:(NSURL*)url index:(NSString*)i CallBack:(NSString*)callbackId withOptions:(NSString*)options
{
    CDVEmbeddedWebViewPlug* el;//=[self.brw objectAtIndex:i.intValue];
    CDVWebviewOptions* browserOptions = [CDVWebviewOptions parseOptions:options];
    
    
    
    if (browserOptions.clearcache) {
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            if (![cookie.domain isEqual: @".^filecookies^"]) {
                [storage deleteCookie:cookie];
            }
        }
    }
    
    if (browserOptions.clearsessioncache) {
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            if (![cookie.domain isEqual: @".^filecookies^"] && cookie.isSessionOnly) {
                [storage deleteCookie:cookie];
            }
        }
    }
    
    if (el==nil) {
        NSString* originalUA = [CDVUserAgentUtil originalUserAgent];
        //NSLog(@"----------------JAN1--------- %@",i);
        el = [[CDVEmbeddedWebViewPlug alloc] initWithUserAgent:originalUA prevUserAgent:[self.commandDelegate userAgent] browserOptions:browserOptions index:i callbackId:callbackId];
        el.navigationDelegate =self;
        [_brw addObject:el];
    }
    
    
    // prevent webView from bouncing
    if (browserOptions.disallowoverscroll) {
        if ([el respondsToSelector:@selector(scrollView)]) {
            ((UIScrollView*)[el scrollView]).bounces = NO;
        } else {
            for (id subview in el.subviews) {
                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                    ((UIScrollView*)subview).bounces = NO;
                }
            }
        }
        
    }
    
    
    
    // UIWebView options
    el.scalesPageToFit = browserOptions.enableviewportscale;
    el.mediaPlaybackRequiresUserAction = browserOptions.mediaplaybackrequiresuseraction;
    el.allowsInlineMediaPlayback = browserOptions.allowinlinemediaplayback;
    if (IsAtLeastiOSVersion(@"6.0")) {
        el.keyboardDisplayRequiresUserAction = browserOptions.keyboarddisplayrequiresuseraction;
        el.suppressesIncrementalRendering = browserOptions.suppressesincrementalrendering;
    }
    
    el.frame = CGRectMake(
                                    browserOptions.left.floatValue,
                                    browserOptions.top.floatValue,
                                    browserOptions.width.floatValue,
                                    browserOptions.height.floatValue
                                    );
    
    [el navigateTo:url];
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [el removeFromSuperview];
        el.hidden = NO;
        [self.webView.superview addSubview:el];
        [self.webView.superview bringSubviewToFront:el];
    });

    
    
    
}

// Image from uiwebview
- (UIImage *) imageFromWebView:(UIWebView *)view
{
    // tempframe to reset view size after image was created
    CGRect tmpFrame         = view.frame;

    // set new Frame
    CGRect aFrame               = view.frame;
    aFrame.size.height  = [view sizeThatFits:[[UIScreen mainScreen] bounds].size].height;
    view.frame              = aFrame;

    // do image magic
    UIGraphicsBeginImageContext([view sizeThatFits:[[UIScreen mainScreen] bounds].size]);

    CGContextRef resizedContext = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:resizedContext];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    // reset Frame of view to origin
    view.frame = tmpFrame;
    return image;
}

- (void)getScreenshot:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    NSString *encodedString = @"";
    if (el == nil) {
    }else {
        float fq = 1;
        if (command.arguments.count < 2) {
            NSString* sq = [command argumentAtIndex:1];
            fq = [sq floatValue];
        }

        //UIImage* image = [self imageFromWebView:self.webplug];
        UIImage* image = [self imageFromWebView:el];
        NSData *imageData = UIImageJPEGRepresentation(image, fq);
        //encodedString = [imageData base64Encoding];
        encodedString =[imageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                     messageAsDictionary:@{@"type":@"onScreenshot", @"index":i,@"data":encodedString}];
        
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}
- (void)hasHistory:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    NSString *ret = @"0";
    //if (self.webplug == nil) {
    if (el == nil) {
    }else {
        if ([el canGoBack]) {
            ret=@"1";
        }
    }
    //NSString *combined = [NSString stringWithFormat:@"{\"type\":\"hasHistory\",\"index\":%@,\"data\":%@}", i, ret];
    //pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsString:combined];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:@{@"type":@"hasHistory", @"index":i,@"data":ret}];
    
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
}
- (void)goBack:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    
    if ([el canGoBack]) {
        [el goBack];
    }
}


- (void)injectJS:(CDVInvokedUrlCommand*)command
{
    NSString* i = [command argumentAtIndex:0];
    NSString* js = [command argumentAtIndex:1];
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:i.intValue];
    [el stringByEvaluatingJavaScriptFromString:js];
    //NSLog(@"---------- injectJS ------- %@", js);
    
    
}

- (BOOL)web_View:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType index:(NSString*) ind
{
    NSURL* url = request.URL;
    BOOL isTopLevelNavigation = [request.URL isEqual:[request mainDocumentURL]];
    self.index=ind;
    // See if the url uses the 'gap-iab' protocol. If so, the host should be the id of a callback to execute,
    // and the path, if present, should be a JSON-encoded value to pass to the callback.
    if ([[url scheme] isEqualToString:@"gap-iab"]) {
        NSString* scriptCallbackId = [url host];
        CDVPluginResult* pluginResult = nil;

        //if ([self isValidCallbackId:scriptCallbackId]) {
        if (FALSE){
            NSString* scriptResult = [url path];
            NSError* __autoreleasing error = nil;

            // The message should be a JSON-encoded array of the result of the script which executed.
            if ((scriptResult != nil) && ([scriptResult length] > 1)) {
                scriptResult = [scriptResult substringFromIndex:1];
                NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
                if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]]) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:(NSArray*)decodedResult];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION];
                }
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:scriptCallbackId];
            return NO;
        }
    } else if ((self.callbackId != nil) && isTopLevelNavigation) {
        // Send a loadstart event for each top-level navigation (includes redirects).
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstart", @"index":ind,@"data":[url absoluteString]}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView*)theWebView
{
    _injectedIframeBridge = NO;
    CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:self.index.intValue];
    NSString* url = [el.currentURL absoluteString];
    //NSLog(@" -------- START LOAD----------- %@",url);
}

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    if (self.callbackId != nil) {
        CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:self.index.intValue];
        NSString* url = [el.currentURL absoluteString];
        
        //NSLog(@" -------- FINISHED LOAD----------- %@",url);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstop",@"index":self.index, @"data":url}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

- (void)webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    if (self.callbackId != nil) {
        CDVEmbeddedWebViewPlug* el=[self.brw objectAtIndex:self.index.intValue];
        NSString* url = [el.currentURL absoluteString];
        NSLog(@" -------- LOAD ERROR  ----------- %@",url);
        //CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
        //messageAsDictionary:@{@"type":@"loaderror", @"url":url, @"code": [NSNumber numberWithInteger:error.code], @"message": error.localizedDescription}];
        
        //   js interface
        //
        // call from js:
        // android
        // AppInterface.send(data);
        //
        // ios
        // window.url="AppInterface://"+data;
        
        if ([[url substringWithRange:NSMakeRange(0,15)] isEqualToString: @"AppInterface://" ]==1){
            NSString* data=[url substringWithRange:NSMakeRange(15,[url length]-15)];
            data=[data stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:@{@"type":@"jsMessage",@"index":self.index, @"data":data}];
            [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }else{
          CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loaderror",@"index":self.index, @"data":error.localizedDescription}];
          [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
          [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
        }
    }
}

@end


@implementation CDVWebviewOptions

- (id)init
{
    if (self = [super init]) {
        // default values
        self.location = YES;
        self.toolbar = YES;
        self.closebuttoncaption = nil;
        self.toolbarposition = kInAppBrowserToolbarBarPositionBottom;
        self.clearcache = NO;
        self.clearsessioncache = NO;

        self.enableviewportscale = NO;
        self.mediaplaybackrequiresuseraction = NO;
        self.allowinlinemediaplayback = NO;
        self.keyboarddisplayrequiresuseraction = YES;
        self.suppressesincrementalrendering = NO;
        self.hidden = NO;
        self.disallowoverscroll = NO;
    }

    return self;
}

+ (CDVWebviewOptions*)parseOptions:(NSString*)options
{
    CDVWebviewOptions* obj = [[CDVWebviewOptions alloc] init];

    // NOTE: this parsing does not handle quotes within values
    NSArray* pairs = [options componentsSeparatedByString:@","];

    // parse keys and values, set the properties
    for (NSString* pair in pairs) {
        NSArray* keyvalue = [pair componentsSeparatedByString:@"="];

        if ([keyvalue count] == 2) {
            NSString* key = [[keyvalue objectAtIndex:0] lowercaseString];
            NSString* value = [keyvalue objectAtIndex:1];
            NSString* value_lc = [value lowercaseString];

            BOOL isBoolean = [value_lc isEqualToString:@"yes"] || [value_lc isEqualToString:@"no"];
            NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setAllowsFloats:YES];
            BOOL isNumber = [numberFormatter numberFromString:value_lc] != nil;

            // set the property according to the key name
            if ([obj respondsToSelector:NSSelectorFromString(key)]) {
                if (isNumber) {
                    [obj setValue:[numberFormatter numberFromString:value_lc] forKey:key];
                } else if (isBoolean) {
                    [obj setValue:[NSNumber numberWithBool:[value_lc isEqualToString:@"yes"]] forKey:key];
                } else {
                    [obj setValue:value forKey:key];
                }
            }
        }
    }

    return obj;
}

@end


@implementation CDVEmbeddedWebViewPlug

@synthesize currentURL;

- (id)initWithUserAgent:(NSString*)userAgent prevUserAgent:(NSString*)prevUserAgent browserOptions: (CDVWebviewOptions*) browserOptions index:(NSString*)index callbackId:(NSString*)callbackId
{
    //NSLog(@"---------webView:INIT WITH USER AGENT----------index:%@  cb:%@",index,callbackId);
    self = [super init];
    self.index=index;
    self.callbackId=callbackId;
    
    if (self != nil) {
        _index=index;
        _userAgent = userAgent;
        _prevUserAgent = prevUserAgent;
        _browserOptions = browserOptions;
#ifdef __CORDOVA_4_0_0
        _webViewDelegate = [[CDVUIWebViewDelegate alloc] initWithDelegate:self];
#else
        _webViewDelegate = [[CDVWebViewDelegate alloc] initWithDelegate:self];
#endif
        self.delegate = _webViewDelegate;
        self.backgroundColor = [UIColor whiteColor];
        self.clearsContextBeforeDrawing = YES;
        self.clipsToBounds = YES;
        self.contentMode = UIViewContentModeScaleToFill;
        self.multipleTouchEnabled = YES;
        self.opaque = YES;
        self.scalesPageToFit = NO;
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

- (void)navigateTo:(NSURL*)url
{
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    [self loadRequest:request];
}

- (void)webViewDidStartLoad:(UIWebView*)theWebView
{
    // loading url, start spinner, update back/forward
    //NSLog(@"---------webView:START LOAD---------- %@",self.index);
    return [self.navigationDelegate webViewDidStartLoad:theWebView];
}

- (BOOL)webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL isTopLevelNavigation = [request.URL isEqual:[request mainDocumentURL]];
    
    if (isTopLevelNavigation) {
        self.currentURL = request.URL;
    }
    return [self.navigationDelegate web_View:theWebView shouldStartLoadWithRequest:request navigationType:navigationType index:self.index];
}

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    // update url, stop spinner, update back/forward
    NSLog(@"---------webView:FINISH LOAD----------");
    
    // Work around a bug where the first time a PDF is opened, all UIWebViews
    // reload their User-Agent from NSUserDefaults.
    // This work-around makes the following assumptions:
    // 1. The app has only a single Cordova Webview. If not, then the app should
    //    take it upon themselves to load a PDF in the background as a part of
    //    their start-up flow.
    // 2. That the PDF does not require any additional network requests. We change
    //    the user-agent here back to that of the CDVViewController, so requests
    //    from it must pass through its white-list. This *does* break PDFs that
    //    contain links to other remote PDF/websites.
    // More info at https://issues.apache.org/jira/browse/CB-2225
    BOOL isPDF = [@"true" isEqualToString :[theWebView stringByEvaluatingJavaScriptFromString:@"document.body==null"]];
    if (isPDF) {
        [CDVUserAgentUtil setUserAgent:_prevUserAgent lockToken:_userAgentLockToken];
    }
    
    [self.navigationDelegate webViewDidFinishLoad:theWebView];
}

- (void)webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    // log fail message, stop spinner, update back/forward
    NSLog(@"--------- webView:didFailLoadWithError - %ld: %@ -----------", (long)error.code, [error localizedDescription]);
    
    [self.navigationDelegate webView:theWebView didFailLoadWithError:error];
}

@end
