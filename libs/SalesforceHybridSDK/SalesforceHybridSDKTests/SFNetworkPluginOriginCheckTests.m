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

- (BOOL)isTrustedSalesforceURL:(NSURL *)url instanceURL:(NSURL *)instanceURL;

@end

@interface SFNetworkPluginOriginCheckTests : XCTestCase

@property (nonatomic, strong) SFNetworkPlugin *plugin;
@property (nonatomic, strong) NSURL *instanceURL;

@end

@implementation SFNetworkPluginOriginCheckTests

- (void)setUp {
    [super setUp];
    self.plugin = [[SFNetworkPlugin alloc] init];
    self.instanceURL = [NSURL URLWithString:@"https://myorg.my.salesforce.com"];
}

- (void)tearDown {
    self.plugin = nil;
    self.instanceURL = nil;
    [super tearDown];
}

#pragma mark - localhost is always trusted

- (void)testHttpsLocalhostIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://localhost"];
    XCTAssertTrue([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                  @"https://localhost must be trusted");
}

- (void)testHttpLocalhostIsTrusted {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080/index.html"];
    XCTAssertTrue([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                  @"http://localhost must be trusted (local hybrid dev server)");
}

#pragma mark - Exact instance URL host is trusted

- (void)testExactInstanceUrlIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://myorg.my.salesforce.com/path"];
    XCTAssertTrue([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                  @"The user's own instance URL must be trusted");
}

- (void)testInstanceUrlWithApiPathIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://myorg.my.salesforce.com/services/data/v60.0"];
    XCTAssertTrue([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                  @"A request path under the instance URL must be trusted");
}

#pragma mark - Other Salesforce domains are NOT trusted

- (void)testOtherSalesforceOrgIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://otherorg.my.salesforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                   @"A different Salesforce org must NOT be trusted");
}

- (void)testWildcardSalesforceComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://anything.salesforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                   @"Broad *.salesforce.com wildcard must NOT be trusted");
}

- (void)testForceComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://mypage.force.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                   @"*.force.com must NOT be trusted (cross-tenant risk)");
}

- (void)testVisualforceComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://mypage.visualforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                   @"*.visualforce.com must NOT be trusted (cross-tenant risk)");
}

#pragma mark - Arbitrary hosts are NOT trusted

- (void)testEvilComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://evil.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                   @"evil.com must NOT be trusted");
}

- (void)testSpoofedSalesforceComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://evil-salesforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                   @"evil-salesforce.com must NOT be trusted");
}

#pragma mark - Scheme is enforced for non-localhost

- (void)testFileSchemeIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"file:///www/index.html"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                   @"file:// must NOT be trusted (modern Cordova uses https://localhost)");
}

- (void)testHttpInstanceUrlIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"http://myorg.my.salesforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL],
                   @"http:// instance URL must NOT be trusted (https required)");
}

#pragma mark - Edge cases

- (void)testNilURLIsNotTrusted {
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:nil instanceURL:self.instanceURL],
                   @"nil URL must NOT be trusted");
}

- (void)testNilInstanceURLBlocksNonLocalhost {
    NSURL *url = [NSURL URLWithString:@"https://myorg.my.salesforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:nil],
                   @"Without an authenticated instance URL, non-localhost must be blocked");
}

- (void)testNilInstanceURLAllowsLocalhost {
    NSURL *url = [NSURL URLWithString:@"https://localhost"];
    XCTAssertTrue([self.plugin isTrustedSalesforceURL:url instanceURL:nil],
                  @"localhost is trusted even without an authenticated session");
}

@end
