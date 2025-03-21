/*
 Copyright (c) 2014-present, salesforce.com, inc. All rights reserved.
 
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

#import <MobileCoreServices/MobileCoreServices.h>
#import <SalesforceSDKCore/SFSDKAppFeatureMarkers.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "SFLocalhostSubstitutionCache.h"
#import "SFSDKHybridLogger.h"

#define WWW_DIR @"www"

// App feature constant.
static NSString * const kSFAppFeatureUsesLocalhost = @"LH";

@implementation SFLocalhostSubstitutionCache

- (NSString *)mimeTypeForPath:(NSString *)filePath {
    if (filePath && ![filePath isEqualToString:@""]) {
        NSString *fileExtension = [filePath pathExtension];
        if (fileExtension && ![fileExtension isEqualToString:@""]) {
            UTType *type = [UTType typeWithFilenameExtension:fileExtension];
            NSString *MIMEType = type.preferredMIMEType;
            return MIMEType ?: @"application/octet-stream";
        }
    }
    return @"application/octet-stream"; // Default MIME type for invalid or missing extensions
}

- (NSString*)pathForResource:(NSString*)resourcepath
{
    NSBundle* mainBundle = [NSBundle mainBundle];
    
    // When passed @"" returned full path to www directory
    if ([resourcepath length] == 0) {
        return [[[mainBundle bundlePath] stringByAppendingPathComponent:WWW_DIR] stringByStandardizingPath];
    }
    
    // Otherwise
    NSString* filename = [resourcepath lastPathComponent];
    NSString* directory = [WWW_DIR stringByAppendingString:[resourcepath substringToIndex:[resourcepath length] - [filename length]]];
    return [[mainBundle pathForResource:filename ofType:@"" inDirectory:directory] stringByStandardizingPath];
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request
{
    NSURL* url = [request URL];

    // Not a localhost request.
    if (![[url host] isEqualToString:@"localhost"]) {
        return [super cachedResponseForRequest:request];
    }

    // Localhost request.
    [SFSDKAppFeatureMarkers registerAppFeature:kSFAppFeatureUsesLocalhost];
    NSString* urlPath = [url path];
    NSString* filePath = [self pathForResource:urlPath];
    NSString* wwwDirPath = [self pathForResource:@""];
    NSData* data = nil;
    NSString* mimeType = @"text/plain";
    NSFileManager *manager = [[NSFileManager alloc] init];
    if (![filePath hasPrefix:wwwDirPath]) {
        [SFSDKHybridLogger e:[self class] format:@"Trying to access files outside www: %@", url];
    } else if (![manager fileExistsAtPath:filePath]) {
        [SFSDKHybridLogger e:[self class] format:@"Trying to access non-existent file: %@", url];
    } else {
        data = [NSData dataWithContentsOfFile:filePath];
        mimeType = [self mimeTypeForPath:filePath];
        [SFSDKHybridLogger i:[self class] format:@"Loading local file: %@", urlPath];
    }
    NSURLResponse *response = [[NSURLResponse alloc]
                               initWithURL:[request URL]
                               MIMEType:mimeType
                               expectedContentLength:[data length]
                               textEncodingName:@"utf-8"];
    return [[NSCachedURLResponse alloc] initWithResponse:response data:data];
}

@end
