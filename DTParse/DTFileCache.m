//
//  DTFileCache.m
//  DetuDownloadFile
//
//  Created by detu on 16/9/18.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import "DTFileCache.h"
#import <UIKit/UIKit.h>

#define Lock  dispatch_semaphore_wait(_dispatch_lock, DISPATCH_TIME_FOREVER);
#define Signal dispatch_semaphore_signal(_dispatch_lock);
@interface DTFileCache()
{
    NSString *_path;
    NSMutableDictionary *_dict;
    dispatch_semaphore_t _dispatch_lock;
    NSFileManager *_fileManager;
}
@end

@implementation DTFileCache
-(instancetype)initWithPath:(NSString *)path{
    if (self = [super init]) {
        _path = [path copy];
        _dict = [NSMutableDictionary dictionaryWithContentsOfFile:_path];
        if (_dict == nil) {
            _dict = [NSMutableDictionary new];
        }
        _dispatch_lock = dispatch_semaphore_create(1);
        _fileManager = [NSFileManager new];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_update)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
    }
    return self;
}
- (void)_update {
    [_dict writeToFile:_path atomically:YES];
}

- (void)setValue:(id)value key:(NSString *)key {
    Lock
    if (value && key) {
        _dict[key] = value;
        [self _update];
    }
    Signal
}

-(id)valueToKey:(NSString *)key{
    Lock
    id value = nil;
    if (key) {
        value = _dict[key];
    }
    Signal
    return value;
    
}
-(void)removeToKey:(NSString *)key{
    Lock
    [_dict removeObjectForKey:key];
    [self _update];
    Signal
}

-(void)removeAll {
    Lock
    if (_dict && _dict.count > 0) {
        [_dict removeAllObjects];
        [self _update];
    }
    Signal
    
    
}
-(void)trash:(void (^)())block{
    Lock
    if ([_fileManager fileExistsAtPath:_path]) {
        BOOL is =  [_fileManager removeItemAtPath:_path error:nil];
        if (is) {
            if(block)block();
        }
    }
    Signal
}
-(void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

@end




@interface DTMemoryCache()
@property (strong , nonatomic)  NSMutableDictionary *memCache;
@property (strong , nonatomic)  dispatch_semaphore_t dispatch_lock;
@end
@implementation DTMemoryCache

+(DTMemoryCache *)memoryCache {
    static DTMemoryCache *_memoryCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _memoryCache = [[self alloc] init];
        
    });
    return _memoryCache;
}
-(instancetype)init {
    if (self=[super init]) {
        _memCache = [NSMutableDictionary new];
        _dispatch_lock = dispatch_semaphore_create(1);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(removeAll)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
       
        
    }
    return self;
}

-(NSInteger)count {
    dispatch_semaphore_wait(_dispatch_lock, DISPATCH_TIME_FOREVER);
    NSUInteger countLimit =  [_memCache count];
    dispatch_semaphore_signal(_dispatch_lock);
    return countLimit;
}

- (void)setValue:(id)value key:(NSString *)key {
    dispatch_semaphore_wait(_dispatch_lock, DISPATCH_TIME_FOREVER);
    if (value && key) {
        [_memCache setObject:value forKey:key];
    }
    dispatch_semaphore_signal(_dispatch_lock);
}

- (void)removeToKey:(NSString *)key {
    dispatch_semaphore_wait(_dispatch_lock, DISPATCH_TIME_FOREVER);
    if (key) {
        [_memCache removeObjectForKey:key];
    }
    dispatch_semaphore_signal(_dispatch_lock);
}

-(id)valueToKey:(NSString *)key{
    if (!key)return nil;
    dispatch_semaphore_wait(_dispatch_lock, DISPATCH_TIME_FOREVER);
    id value = nil;
    value = [_memCache objectForKey:key];
    dispatch_semaphore_signal(_dispatch_lock);
    return value;
}

-(BOOL)containsValueKey:(NSString *)key {
    dispatch_semaphore_wait(_dispatch_lock, DISPATCH_TIME_FOREVER);
    BOOL contains =  [_memCache.allKeys containsObject:key];
    dispatch_semaphore_signal(_dispatch_lock);
    return contains;
}

-(void)findAll:(void (^)(id, NSString *))block {
    if (!block) return;
    dispatch_semaphore_wait(_dispatch_lock, DISPATCH_TIME_FOREVER);
    if (_memCache && _memCache.count >  0) {
        for (id key in _memCache) {
            id value = _memCache[key];
            block(value , key);
        }
    } else {
        block(nil, nil);
    }
    dispatch_semaphore_signal(_dispatch_lock);
}

- (void)removeAll{
    if (!_memCache || !_memCache.count) return;
    dispatch_semaphore_wait(_dispatch_lock, DISPATCH_TIME_FOREVER);
    [_memCache removeAllObjects];
    dispatch_semaphore_signal(_dispatch_lock);
    
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end



