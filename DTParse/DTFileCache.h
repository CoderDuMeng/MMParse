//
//  DTFileCache.h
//  DetuDownloadFile
//
// 文件形式的存取

#import <Foundation/Foundation.h>
/**
 支持json格式plist本地文件的形式存储
 
 *
 */

@interface DTFileCache : NSObject
- (instancetype)initWithPath:(NSString *)path;
- (void)setValue:(id)value key:(NSString *)key;
- (id)valueToKey:(NSString *)key;
- (void)removeToKey:(NSString *)key;
- (void)removeAll;
- (void)trash:(void(^)())block;
@end



@interface DTMemoryCache : NSObject
+(DTMemoryCache *)memoryCache;
- (void)setValue:(id)value key:(NSString *)key;
- (void)removeToKey:(NSString *)key;
- (id)valueToKey:(NSString *)key;
- (BOOL)containsValueKey:(NSString *)key;
- (void)findAll:(void(^)(id value ,NSString *key))block;
- (void)removeAll;
- (NSInteger)count;


@end
