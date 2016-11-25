//
//  DTFileCache.m
//  DetuDownloadFile
//
//  Created by detu on 16/9/18.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import "DTFileCache.h"


@interface DTFileCache()
{
    NSString *_path;
    NSMutableDictionary *_dict;
    NSRecursiveLock *_lock;
}
@end

@implementation DTFileCache
-(instancetype)initWithPath:(NSString *)path{
    if (self = [super init]) {
        _path = [path copy];
        _dict = [NSMutableDictionary dictionaryWithContentsOfFile:_path];
        _lock = [NSRecursiveLock new];
    }
    return self;
}
- (void)_update {
    [_dict writeToFile:_path atomically:YES];
}
- (void)setValue:(id)value key:(NSString *)key {
    if (_dict == nil) {
        _dict = [NSMutableDictionary new];
    }
    [_lock lock];
    _dict[key] = value;
    [self _update];
    [_lock unlock];
    
}

-(id)valueToKey:(NSString *)key{
    [_lock lock];
    id value = _dict[key];
    [_lock unlock];
    return value;
    
}
-(void)removeToKey:(NSString *)key{
    [_lock lock];
    [_dict removeObjectForKey:key];
    [self _update];
    [_lock unlock];
    
}

-(void)removeAll {
    [_lock lock];
    [_dict removeAllObjects];
    [self _update];
    [_lock unlock];
    
    
}

@end
