
#import "DTDiskCache.h"
@interface DTDiskCache()
@end
@implementation DTDiskCache
+(DTDiskCache *)diskCache{
    static DTDiskCache *_diskCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _diskCache = [[DTDiskCache alloc] init];
    });
    return _diskCache;
}
-(instancetype)init{
    if (self=[super init]) {
        _fileManager = [NSFileManager new];
    }
    return self;
}
- (NSString *)superDirName{
    return @"detu.com/";
}
- (NSString *)replacePath{
    return @"[IOS_DEFAULT_PATH]/";
}
- (NSString *)smallReplaceFilePath:(NSString *)key{
    NSString *replacePath = [NSString stringWithFormat:@"%@%@",[self replacePath],[self superDirName]];
    return  [replacePath stringByAppendingString:key.MD5];
}
- (NSString *)makeSuperDirPath:(NSString *)key{
    return [[self superDirName] stringByAppendingString:[key MD5]].cacheComponent;
}
-(NSString *)makeDirPath:(NSString *)key{
    NSString *dirPath = [self makeSuperDirPath:key];
    //查看子文件夹纯在不存在
    BOOL isExists = [_fileManager fileExistsAtPath:dirPath];
    if (!isExists) {
        //不存在创建文件夹 写入
        [_fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dirPath;
}
-(BOOL)removeFilePath:(NSString *)path{
    return [_fileManager removeItemAtPath:path error:nil];
}
-(BOOL)isExistFilePath:(NSString *)path{
    return [_fileManager fileExistsAtPath:path];
}
@end
@implementation NSString(MD5)
-(NSString *)MD5{
    // 得出bytes
    const char *cstring = self.UTF8String;
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cstring, (CC_LONG)strlen(cstring), bytes);
    // 拼接
    NSMutableString *md5String = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [md5String appendFormat:@"%02x", bytes[i]];
    }
    return md5String;
}
- (NSString *)cacheComponent{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:self];
}
-(NSInteger)fileSize{
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:self error:nil][NSFileSize] integerValue];
}
-(BOOL)writeToFile:(NSString *)path{
    return [self writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}
-(NSString *)appendingXMl{
    return [self stringByAppendingPathExtension:@"xml"];
}
-(NSString *)appendingJPG{
    return [self stringByAppendingPathExtension:@"jpg"];
}
-(NSString *)appendingMP4{
    return [self stringByAppendingPathExtension:@"mp4"];
}
-(NSString *)appendingPNG{
    return [self stringByAppendingPathExtension:@"png"];
}
-(NSString *)appendingPath:(NSString *)path{
    return [self stringByAppendingPathComponent:path];
}
-(NSString *)appending:(NSString *)str{
    return [self stringByAppendingString:str];
}

@end

