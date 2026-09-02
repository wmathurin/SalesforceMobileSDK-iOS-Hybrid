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

// Expose private methods for testing.
@interface SFNetworkPlugin (Testing)

- (BOOL)isTrustedCallerURL:(NSURL *)url;
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

#pragma mark - isTrustedCallerURL (broad check — controls bridge access)

- (void)testCaller_HttpsLocalhostIsTrusted {
    XCTAssertTrue([self.plugin isTrustedCallerURL:[NSURL URLWithString:@"https://localhost"]]);
}

- (void)testCaller_HttpLocalhostIsTrusted {
    XCTAssertTrue([self.plugin isTrustedCallerURL:[NSURL URLWithString:@"http://localhost:8080/index.html"]]);
}

- (void)testCaller_FileSchemeIsTrusted {
    XCTAssertTrue([self.plugin isTrustedCallerURL:[NSURL URLWithString:@"file:///www/index.html"]]);
}

- (void)testCaller_SalesforceComIsTrusted {
    XCTAssertTrue([self.plugin isTrustedCallerURL:[NSURL URLWithString:@"https://myorg.my.salesforce.com"]]);
}

- (void)testCaller_ForceComIsTrusted {
    XCTAssertTrue([self.plugin isTrustedCallerURL:[NSURL URLWithString:@"https://mypage.force.com"]]);
}

- (void)testCaller_VisualforceComIsTrusted {
    XCTAssertTrue([self.plugin isTrustedCallerURL:[NSURL URLWithString:@"https://mypage.visualforce.com"]]);
}

- (void)testCaller_EvilComIsNotTrusted {
    XCTAssertFalse([self.plugin isTrustedCallerURL:[NSURL URLWithString:@"https://evil.com"]]);
}

- (void)testCaller_SpoofedSalesforceHostIsNotTrusted {
    XCTAssertFalse([self.plugin isTrustedCallerURL:[NSURL URLWithString:@"https://evil-salesforce.com"]]);
}

- (void)testCaller_NilIsNotTrusted {
    XCTAssertFalse([self.plugin isTrustedCallerURL:nil]);
}

#pragma mark - isTrustedSalesforceURL:instanceURL: (strict check — controls auth token attachment)

- (void)testEndpoint_HttpsLocalhostIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://localhost"];
    XCTAssertTrue([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL]);
}

- (void)testEndpoint_HttpLocalhostIsTrusted {
    NSURL *url = [NSURL URLWithString:@"http://localhost:8080/path"];
    XCTAssertTrue([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL]);
}

- (void)testEndpoint_ExactInstanceUrlIsTrusted {
    NSURL *url = [NSURL URLWithString:@"https://myorg.my.salesforce.com/services/data/v60.0"];
    XCTAssertTrue([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL]);
}

- (void)testEndpoint_OtherSalesforceOrgIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://otherorg.my.salesforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL]);
}

- (void)testEndpoint_ForceComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://mypage.force.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL]);
}

- (void)testEndpoint_VisualforceComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://mypage.visualforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL]);
}

- (void)testEndpoint_EvilComIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"https://evil.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL]);
}

- (void)testEndpoint_FileSchemeIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"file:///www/index.html"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL]);
}

- (void)testEndpoint_HttpInstanceUrlIsNotTrusted {
    NSURL *url = [NSURL URLWithString:@"http://myorg.my.salesforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:self.instanceURL]);
}

- (void)testEndpoint_NilURLIsNotTrusted {
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:nil instanceURL:self.instanceURL]);
}

- (void)testEndpoint_NilInstanceURLBlocksNonLocalhost {
    NSURL *url = [NSURL URLWithString:@"https://myorg.my.salesforce.com"];
    XCTAssertFalse([self.plugin isTrustedSalesforceURL:url instanceURL:nil]);
}

- (void)testEndpoint_NilInstanceURLAllowsLocalhost {
    NSURL *url = [NSURL URLWithString:@"https://localhost"];
    XCTAssertTrue([self.plugin isTrustedSalesforceURL:url instanceURL:nil]);
}

@end
