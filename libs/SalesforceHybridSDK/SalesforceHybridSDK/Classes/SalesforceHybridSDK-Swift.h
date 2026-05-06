// Hand-maintained ObjC bridge stub for SalesforceHybridSDKSwift.
// Contains declarations for @objc public types defined in Swift files.
// Must be updated whenever a Swift type gains/loses @objc exposure.
//
// SalesforceWebViewCookieManager uses @objc(SFSDKSalesforceWebViewCookieManager),
// so its ObjC class name is set directly (no Swift mangling).

#ifndef SALESFORCEHYBRIDSDK_SWIFT_H
#define SALESFORCEHYBRIDSDK_SWIFT_H

#if defined(__OBJC__)

#include <Foundation/Foundation.h>

@class SFUserAccount;

@interface SFSDKSalesforceWebViewCookieManager : NSObject
- (void)setCookiesWithUserAccount:(SFUserAccount * _Nonnull)userAccount completion:(void (^ _Nonnull)(void))completion;
- (nonnull instancetype)init;
@end

#endif // __OBJC__

#endif // SALESFORCEHYBRIDSDK_SWIFT_H
