//
//  DTFileCache.h
//  DetuDownloadFile
//
// 文件形式的存取

#import <Foundation/Foundation.h>

@interface DTFileCache : NSObject
-(instancetype)initWithPath:(NSString *)path;
- (void)setValue:(id)value key:(NSString *)key;
- (id)valueToKey:(NSString *)key;
- (void)removeToKey:(NSString *)key;
@end
