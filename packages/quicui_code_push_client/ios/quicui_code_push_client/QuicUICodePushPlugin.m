#import "QuicUICodePushPlugin.h"

@implementation QuicUICodePushPlugin {
    FlutterMethodChannel* _channel;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    NSLog(@"[QuicUICodePush] registerWithRegistrar called");
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"com.quicui/codepush"
              binaryMessenger:[registrar messenger]];
    QuicUICodePushPlugin* instance = [[QuicUICodePushPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
    NSLog(@"[QuicUICodePush] Plugin registered successfully");
}

- (instancetype)initWithChannel:(FlutterMethodChannel*)channel {
    self = [super init];
    if (self) {
        _channel = channel;
    }
    return self;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"[QuicUICodePush] 🔧 handleMethodCall: %@", call.method);
    
    if ([@"installPatch" isEqualToString:call.method]) {
        [self handleInstallPatch:call result:result];
    } else if ([@"getDeviceArchitecture" isEqualToString:call.method]) {
        result(@"arm64");
    } else {
        NSLog(@"[QuicUICodePush] Method not implemented: %@", call.method);
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleInstallPatch:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSLog(@"[QuicUICodePush] START handleInstallPatch");
    
    NSDictionary* args = call.arguments;
    NSString* patchPath = args[@"patchPath"];
    NSString* patchId = args[@"patchId"];  // Get patchId from server response
    NSString* hash = args[@"hash"];
    
    NSLog(@"[QuicUICodePush] Patch ID received: %@", patchId);
    
    if (!patchPath || !patchId) {
        NSLog(@"[QuicUICodePush] ERROR Missing arguments");
        result([FlutterError errorWithCode:@"INVALID_ARGS" 
                                   message:@"patchPath and patchId required"
                                   details:nil]);
        return;
    }
    
    NSLog(@"[QuicUICodePush] Installing patch");
    NSLog(@"[QuicUICodePush] Source path length: %lu", (unsigned long)[patchPath length]);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager* fileManager = [NSFileManager defaultManager];
        
        // Get Caches directory
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        if (paths.count == 0) {
            NSLog(@"[QuicUICodePush] ❌ Cannot find Caches directory");
            dispatch_async(dispatch_get_main_queue(), ^{
                result(@NO);
            });
            return;
        }
        
        NSString* cachesDir = paths[0];
        
        // C++ loader expects: patches/0/dlc.vmcode (using patch number, not full patchId)
        NSString* patchesBaseDir = [cachesDir stringByAppendingPathComponent:@"patches"];
        
        // Find existing patches to determine next patch number
        NSInteger patchNumber = 0;
        NSError* dirError = nil;
        NSArray* existingPatches = [fileManager contentsOfDirectoryAtPath:patchesBaseDir error:&dirError];
        if (existingPatches) {
            for (NSString* item in existingPatches) {
                if ([item isEqualToString:@"patches_state.json"]) continue;
                NSInteger num = [item integerValue];
                if (num >= patchNumber) {
                    patchNumber = num + 1;
                }
            }
        }
        
        // Use patch number as directory name (e.g., "0", "1", "2")
        NSString* versionDir = [patchesBaseDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%lld", (long long)patchNumber]];
        
        NSLog(@"[QuicUICodePush] Patch ID: %@, Patch number: %lld", patchId, (long long)patchNumber);
        NSLog(@"[QuicUICodePush] Creating patches directory: %@", versionDir);
        
        // Create patches/[version] directory
        NSError* error = nil;
        [fileManager createDirectoryAtPath:versionDir 
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (error) {
            NSLog(@"[QuicUICodePush] ERROR creating directory: %@", error);
        } else {
            NSLog(@"[QuicUICodePush] Patches directory created");
        }
        
        // Copy file as dlc.vmcode (expected by updater)
        NSString* destPath = [versionDir stringByAppendingPathComponent:@"dlc.vmcode"];
        
        // Remove old file if exists
        if ([fileManager fileExistsAtPath:destPath]) {
            NSLog(@"[QuicUICodePush] Removing old dlc.vmcode");
            [fileManager removeItemAtPath:destPath error:nil];
        }
        
        // Copy patch file to dlc.vmcode
        NSLog(@"[QuicUICodePush] Copying patch to dlc.vmcode");
        BOOL success = [fileManager copyItemAtPath:patchPath toPath:destPath error:&error];
        if (!success || error) {
            NSLog(@"[QuicUICodePush] ERROR copying file: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                result(@NO);
            });
            return;
        }
        
        NSLog(@"[QuicUICodePush] File copied successfully to: %@", destPath);
        
        // Verify file exists and get size
        unsigned long long fileSize = 0;
        if ([fileManager fileExistsAtPath:destPath]) {
            NSDictionary* attrs = [fileManager attributesOfItemAtPath:destPath error:nil];
            fileSize = [attrs fileSize];
            NSLog(@"[QuicUICodePush] dlc.vmcode size: %llu bytes", fileSize);
            
            // Set file attributes to ensure proper access
            NSDictionary *attributes = @{
                NSFilePosixPermissions: @(0644),
                NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication
            };
            NSError *attrError = nil;
            [fileManager setAttributes:attributes ofItemAtPath:destPath error:&attrError];
            if (attrError) {
                NSLog(@"[QuicUICodePush] Warning setting file attributes: %@", attrError);
            } else {
                NSLog(@"[QuicUICodePush] File attributes set successfully");
            }
        } else {
            NSLog(@"[QuicUICodePush] ERROR: File not found after copy");
            dispatch_async(dispatch_get_main_queue(), ^{
                result(@NO);
            });
            return;
        }
        
        // Get architecture and version from args (used for both metadata files)
        NSString* architecture = args[@"architecture"] ?: @"arm64";
        NSString* version = patchId;  // Use patchId as version identifier
        
        // Create metadata.json in patch directory for C++ engine validation
        NSString* metadataFile = [versionDir stringByAppendingPathComponent:@"metadata.json"];
        
        NSLog(@"[QuicUICodePush] Creating metadata.json in patch directory");
        
        // Create metadata matching expected format for C++ engine
        NSDictionary* metadata = @{
            @"patch_id": patchId,
            @"version": version,
            @"hash": hash ?: @"",
            @"size": @(fileSize),
            @"compression": @"xz",
            @"platform": @"ios",
            @"architecture": architecture
        };
        
        NSError* metadataError = nil;
        NSData* metadataJsonData = [NSJSONSerialization dataWithJSONObject:metadata
                                                                   options:NSJSONWritingPrettyPrinted
                                                                     error:&metadataError];
        if (metadataError || !metadataJsonData) {
            NSLog(@"[QuicUICodePush] Warning: Failed to create metadata.json: %@", metadataError);
        } else {
            [metadataJsonData writeToFile:metadataFile atomically:YES];
            NSLog(@"[QuicUICodePush] metadata.json created successfully at: %@", metadataFile);
        }
        
        // Create patches_state.json to tell updater which patch to boot
        NSString* patchesStateFile = [patchesBaseDir stringByAppendingPathComponent:@"patches_state.json"];
        
        NSLog(@"[QuicUICodePush] Creating patches_state.json with patch number: %lld", (long long)patchNumber);
        
        // Include all metadata fields required by C++ LoadPatchMetadata()
        // The C++ engine reads patches_state.json as metadata on iOS
        NSDictionary* patchesState = @{
            @"number": @(patchNumber),
            @"size": @(fileSize),
            @"hash": hash ?: @"",
            @"version": version,
            @"platform": @"ios",
            @"architecture": architecture,
            @"patch_hash": hash ?: @"",
            @"signature": @"",
            @"release_date": @"",
            @"critical": @NO,
            @"requires_restart": @YES
        };
        
        NSError* jsonError = nil;
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:patchesState
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&jsonError];
        if (jsonError || !jsonData) {
            NSLog(@"[QuicUICodePush] Warning: Failed to create patches_state.json: %@", jsonError);
        } else {
            [jsonData writeToFile:patchesStateFile atomically:YES];
            NSLog(@"[QuicUICodePush] patches_state.json created successfully with metadata fields");
        }
        
        NSLog(@"[QuicUICodePush] Installation complete");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            result(@YES);
        });
    });
}

@end
