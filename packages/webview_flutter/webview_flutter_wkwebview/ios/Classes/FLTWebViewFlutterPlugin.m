// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTWebViewFlutterPlugin.h"
#import "FWFGeneratedWebKitApis.h"
#import "FWFHTTPCookieStoreHostApi.h"
#import "FWFInstanceManager.h"
#import "FWFNavigationDelegateHostApi.h"
#import "FWFObjectHostApi.h"
#import "FWFPreferencesHostApi.h"
#import "FWFScriptMessageHandlerHostApi.h"
#import "FWFScrollViewDelegateHostApi.h"
#import "FWFScrollViewHostApi.h"
#import "FWFUIDelegateHostApi.h"
#import "FWFUIViewHostApi.h"
#import "FWFURLCredentialHostApi.h"
#import "FWFURLHostApi.h"
#import "FWFUserContentControllerHostApi.h"
#import "FWFWebViewConfigurationHostApi.h"
#import "FWFWebViewHostApi.h"
#import "FWFWebsiteDataStoreHostApi.h"

@interface FWFWebViewFactory : NSObject <FlutterPlatformViewFactory>
@property(nonatomic, weak) FWFInstanceManager *instanceManager;

- (instancetype)initWithManager:(FWFInstanceManager *)manager;
- (NSDictionary<NSString*, id<WKURLSchemeHandler>>*)schemeHandlers;
+ (FWFWebViewFactory*)currentInstance;
@end

@interface FWFWebViewFactoryInstance : NSObject
@property (weak, nonatomic) FWFWebViewFactory *factory;
+ (instancetype)sharedInstance;
@end
@implementation FWFWebViewFactoryInstance
+ (instancetype)sharedInstance {
    static FWFWebViewFactoryInstance *sInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sInstance = [[FWFWebViewFactoryInstance alloc] init];
    });
    return sInstance;
}
@end

@implementation FWFWebViewFactory {
  NSMutableDictionary<NSString*, id<WKURLSchemeHandler>>* _schemeHandlers;
}

+ (FWFWebViewFactory*)currentInstance {
  return [FWFWebViewFactoryInstance sharedInstance].factory;
}

- (instancetype)initWithManager:(FWFInstanceManager *)manager {
  self = [self init];
  if (self) {
    _instanceManager = manager;
    _schemeHandlers = [NSMutableDictionary dictionary];
	[FWFWebViewFactoryInstance sharedInstance].factory = self;
  }
  return self;
}

- (NSDictionary<NSString*, id<WKURLSchemeHandler>>*)schemeHandlers {
    return _schemeHandlers;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id _Nullable)args {
  NSNumber *identifier = (NSNumber *)args;
  FWFWebView *webView =
      (FWFWebView *)[self.instanceManager instanceForIdentifier:identifier.longValue];
  webView.frame = frame;
  return webView;
}

- (void)setHandler:(id<WKURLSchemeHandler>)handler forURLScheme:(NSString*)urlScheme {
  _schemeHandlers[urlScheme] = handler;
}

@end

@implementation FLTWebViewFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FWFInstanceManager *instanceManager =
      [[FWFInstanceManager alloc] initWithDeallocCallback:^(long identifier) {
        FWFObjectFlutterApiImpl *objectApi = [[FWFObjectFlutterApiImpl alloc]
            initWithBinaryMessenger:registrar.messenger
                    instanceManager:[[FWFInstanceManager alloc] init]];

        dispatch_async(dispatch_get_main_queue(), ^{
          [objectApi disposeObjectWithIdentifier:identifier
                                      completion:^(FlutterError *error) {
                                        NSAssert(!error, @"%@", error);
                                      }];
        });
      }];
  SetUpFWFWKHttpCookieStoreHostApi(
      registrar.messenger,
      [[FWFHTTPCookieStoreHostApiImpl alloc] initWithInstanceManager:instanceManager]);
  SetUpFWFWKNavigationDelegateHostApi(
      registrar.messenger,
      [[FWFNavigationDelegateHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                        instanceManager:instanceManager]);
  SetUpFWFNSObjectHostApi(registrar.messenger,
                          [[FWFObjectHostApiImpl alloc] initWithInstanceManager:instanceManager]);
  SetUpFWFWKPreferencesHostApi(registrar.messenger, [[FWFPreferencesHostApiImpl alloc]
                                                        initWithInstanceManager:instanceManager]);
  SetUpFWFWKScriptMessageHandlerHostApi(
      registrar.messenger,
      [[FWFScriptMessageHandlerHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                          instanceManager:instanceManager]);
  SetUpFWFUIScrollViewHostApi(registrar.messenger, [[FWFScrollViewHostApiImpl alloc]
                                                       initWithInstanceManager:instanceManager]);
  SetUpFWFWKUIDelegateHostApi(registrar.messenger, [[FWFUIDelegateHostApiImpl alloc]
                                                       initWithBinaryMessenger:registrar.messenger
                                                               instanceManager:instanceManager]);
  SetUpFWFUIViewHostApi(registrar.messenger,
                        [[FWFUIViewHostApiImpl alloc] initWithInstanceManager:instanceManager]);
  SetUpFWFWKUserContentControllerHostApi(
      registrar.messenger,
      [[FWFUserContentControllerHostApiImpl alloc] initWithInstanceManager:instanceManager]);
  SetUpFWFWKWebsiteDataStoreHostApi(
      registrar.messenger,
      [[FWFWebsiteDataStoreHostApiImpl alloc] initWithInstanceManager:instanceManager]);

  FWFWebViewFactory *webviewFactory = [[FWFWebViewFactory alloc] initWithManager:instanceManager];

  SetUpFWFWKWebViewConfigurationHostApi(
      registrar.messenger,
      [[FWFWebViewConfigurationHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                          instanceManager:instanceManager
                                                           schemeHandlers:webviewFactory.schemeHandlers]);
  SetUpFWFWKWebViewHostApi(registrar.messenger, [[FWFWebViewHostApiImpl alloc]
                                                    initWithBinaryMessenger:registrar.messenger
                                                            instanceManager:instanceManager]);
  SetUpFWFNSUrlHostApi(registrar.messenger,
                       [[FWFURLHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                          instanceManager:instanceManager]);
  SetUpFWFUIScrollViewDelegateHostApi(
      registrar.messenger,
      [[FWFScrollViewDelegateHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                        instanceManager:instanceManager]);
  SetUpFWFNSUrlCredentialHostApi(
      registrar.messenger,
      [[FWFURLCredentialHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                   instanceManager:instanceManager]);

  [registrar registerViewFactory:webviewFactory withId:@"plugins.flutter.io/webview"];

  // InstanceManager is published so that a strong reference is maintained.
  [registrar publish:instanceManager];
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [registrar publish:[NSNull null]];
}
@end
