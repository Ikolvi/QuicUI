#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>

// Quick test to verify CommonCrypto SHA256 calculation
// Compile: clang -framework Foundation -framework CommonCrypto test_hash.m -o test_hash
// Run: ./test_hash /path/to/file

int main(int argc, char *argv[]) {
    @autoreleasepool {
        if (argc != 2) {
            printf("Usage: %s <file_path>\n", argv[0]);
            return 1;
        }
        
        NSString *filePath = [NSString stringWithUTF8String:argv[1]];
        NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:filePath];
        
        if (!file) {
            printf("Error: Cannot open file: %s\n", argv[1]);
            return 1;
        }
        
        CC_SHA256_CTX ctx;
        CC_SHA256_Init(&ctx);
        
        NSData *data;
        while ((data = [file readDataOfLength:4096]) && [data length] > 0) {
            CC_SHA256_Update(&ctx, [data bytes], (CC_LONG)[data length]);
        }
        
        unsigned char hash[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256_Final(hash, &ctx);
        
        [file closeFile];
        
        // Convert to hex string
        NSMutableString *hashString = [NSMutableString string];
        for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
            [hashString appendFormat:@"%02x", hash[i]];
        }
        
        printf("SHA256: %s\n", [hashString UTF8String]);
        printf("File: %s\n", argv[1]);
        
        return 0;
    }
}
