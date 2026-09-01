/*
 SFNetworkPluginOriginCheckTests.m
 SalesforceHybridSDKTests

 Copyright (c) 2024-present, salesforce.com, inc. All rights reserved.

 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
   and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
   conditions and the following disclaimer in the documentation and/or other materials provided
   with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
   endorse or promote products derived from this software without specific prior written
   permission of salesforce.com, inc.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <XCTest/XCTest.h>
#import "SFNetworkPlugin.h"

// Expose private method for testing.
@interface SFNetworkPlugin (Testing)

- (BOOL)isTrustedCallerURL:(NSURL *)url;

@end

@interface SFNetworkPluginOriginCheckTests : XCTestCase

@property (nonatomic, strong) SFNetworkPlugin *plugin;

@end

@implementation SFNetworkPluginOriginCheckTests

- (void)setUp {
    [super setUp];
    self.plugin = [[SFNetworkPlugin alloc] init];
}

- (void)tearDown {
    self.plugin = nil;
    [super tearDown];
}

#pragma mark - Trusted origins

- (void)testFileSchemeIsTrusted {
    NSURL *url = [NSURL URLWithString:@"file:///www/index.html"];
    XCTAssertTrue([self.plugin isTrustedCallerURL:url],
                  @"file:// URLs must be trusted (local hybrid apps)");
}

- (void)testSalesforceComIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://myorg.salesforce.com"];
    XCTAssertTrue([self.plugin isTrustedCallerURL:url],
                  @"*.salesforce.com must be trusted");
}

- (void)testMySalesforceComIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://myorg.my.salesforce.com"];
    XCTAssertTrue([self.plugin isTrustedCallerURL:url],
                  @"*.my.salesforce.com must be trusted (ends with .salesforce.com)");
}

- (void)testVisualforceComIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://mypage.visualforce.com"];
    XCTAssertTrue([self.plugin isTrustedCallerURL:url],
                  @"*.visualforce.com must be trusted");
}

- (void)testForceComIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://mypage.force.com"];
    XCTAssertTrue([self.plugin isTrustedCallerURL:url],
                  @"*.force.com must be trusted");
}

- (void)testDocumentforceComIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://docs.documentforce.com"];
    XCTAssertTrue([self.plugin isTrustedCallerURL:url],
                  @"*.documentforce.com must be trusted");
}

- (void)testSalesforceCommunitiesComIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://mysite.salesforce-communities.com"];
    XCTAssertTrue([self.plugin isTrustedCallerURL:url],
                  @"*.salesforce-communities.com must be trusted");
}

- (void)testLocalhostIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://localhost"];
    XCTAssertTrue([self.plugin isTrustedCallerURL:url],
                  @"localhost must be trusted");
}

#pragma mark - Untrusted origins

- (void)testEvilComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://evil.com"];
    XCTAssertFalse([self.plugin isTrustedCallerURL:url],
                   @"evil.com must NOT be trusted");
}

- (void)testNotSalesforceComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://notsalesforce.com"];
    XCTAssertFalse([self.plugin isTrustedCallerURL:url],
                   @"notsalesforce.com must NOT be trusted");
}

- (void)testEvilSalesforceComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://evil-salesforce.com"];
    XCTAssertFalse([self.plugin isTrustedCallerURL:url],
                   @"evil-salesforce.com must NOT be trusted (does not end with .salesforce.com)");
}

- (void)testNilURLIsNotTrusted {
    XCTAssertFalse([self.plugin isTrustedCallerURL:nil],
                   @"nil URL must NOT be trusted");
}

@end
