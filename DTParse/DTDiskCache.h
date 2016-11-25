//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h> 

@interface DTDiskCache : NSObject
+ (DTDiskCache *)diskCache;
@property (strong , nonatomic)  NSFileManager *fileManager;
-(NSString *)makeDirPath:(NSString *)key;
-(NSString *)makeSuperDirPath:(NSString *)key;
-(NSString *)superDirName;
-(NSString *)smallReplaceFilePath:(NSString *)key;
-(BOOL)removeFilePath:(NSString *)path;
-(BOOL)isExistFilePath:(NSString *)path;
@end
@interface NSString (MD5)
-(NSString *)cacheComponent;
-(NSString *)MD5;
-(BOOL)writeToFile:(NSString *)path;
-(NSString *)appendingXMl;
-(NSString *)appendingJPG;
-(NSString *)appendingPNG;
-(NSString *)appendingMP4;
-(NSString *)appendingPath:(NSString *)path;
-(NSString *)appending:(NSString *)str;
-(NSInteger)fileSize;

@end
