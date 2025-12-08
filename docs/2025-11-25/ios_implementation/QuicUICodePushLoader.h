// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_QUICUICODEPUSHLOADER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_QUICUICODEPUSHLOADER_H_

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * QuicUI Code Push Loader for iOS
 * 
 * Objective-C wrapper around C++ QuicUIPatchLoader for iOS platform.
 * Handles patch detection and loading for Flutter AOT snapshots on iOS.
 */
@interface QuicUICodePushLoader : NSObject

- (instancetype)initWithCacheDirectory:(NSString*)cacheDir;
- (nullable NSString*)getPatchedAOTPath;
- (BOOL)clearPatch;
- (nullable NSDictionary*)getPatchInfo;

@end

NS_ASSUME_NONNULL_END

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_QUICUICODEPUSHLOADER_H_
