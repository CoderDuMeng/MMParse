//
//  DTParse.m
//  DetuDownloadFile
//
//  Created by detu on 16/9/10.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import "DTParse.h"
#import "DTOpertaion.h"
#import "DTDiskCache.h"
#import "DTFileCache.h"

/*
 解析url类 查看是否是 6个面的url
 */

static NSString *TypeToURL(NSString * url) {
    NSArray *types = @[@".png",@".jpg",@".mp4",@".mp3",@".JPG",@".PNG",@".MP4",@".MP3"];
    NSString *type = url.lastPathComponent;
    NSString *stringT = nil;
    for (NSString *t in types) {
        if ([type rangeOfString:t].location  != NSNotFound) {
            stringT = t;
            break;
        }
    }
    return stringT;
}

@implementation DTURLInfo

-(instancetype)initWithURL:(NSURL *)url oldurl:(NSString *)oldUrl{
    if (self = [super init]) {
        _type = TypeToURL(url.absoluteString);
        _oldUrl = [oldUrl copy];
        _url = url;
    }
    return self;
}
@end

/***
 解析类
 */
@interface DTParse()

//<< 本地包含两个xml文件 一个是原始下载没有替换的 这个是替换的地址
@property (copy , nonatomic) NSString *replaceXmlPath;
//<< 每个文件替换的根目录
@property (copy , nonatomic) NSString *replaceFilePath;
//<<第一次请求回来的xml文件地址
@property (copy , nonatomic) NSString *xmlPath;
//<<完成的个数
@property (copy , nonatomic) NSString *xml;
//<<总 URLS
@property (strong , nonatomic) NSMutableArray *totalURLs;
//<<主队列
@property (strong , nonatomic) dispatch_queue_t main;
//<<子线程
@property (strong , nonatomic) dispatch_queue_t queue;
//设置最大的count
@property (assign , nonatomic) int maxCount;
//完成的count
@property (assign , nonatomic) int finishCount;
//是否完成 设置的最大count
@property (assign , nonatomic) int isMaxCount;
@end
@implementation DTParse
- (BOOL)_targetSelector:(SEL)sel{
    return [_delegate respondsToSelector:sel];
}

-(instancetype)init{
    if (self=[super init]) {
        self.maxCount = 6;
        _main = dispatch_get_main_queue();
        _queue  = dispatch_queue_create("com.detu.DTParse", DISPATCH_QUEUE_SERIAL);
        
    }
    return self;
}


static NSArray *urlsToXML(NSString *xml) {
    NSString * urlpattern = @"([hH]ttp[s]{0,1})://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\-~!@#$%^&*+?:_/=<>.',;]*)?";
    NSRegularExpression *regular   = [[NSRegularExpression alloc] initWithPattern:urlpattern options:0 error:nil];
    NSArray *results               = [regular matchesInString:xml options:0 range:NSMakeRange(0, xml.length)];
    return results;
    
    
}
static NSMutableArray <DTURLInfo *>* parseFilter(NSString *xml){
    @autoreleasepool {
        NSMutableArray *urls= [NSMutableArray array];
        for (NSTextCheckingResult *result  in urlsToXML(xml)) {
            NSString *string = [xml substringWithRange:result.range];
            NSString *component = [string lastPathComponent];
            NSRange range = [component rangeOfString:@"%s"];
            //是6个面的
            if (range.location != NSNotFound) {
                NSArray *replaces = @[@"b",@"d",@"f",@"l",@"r",@"u"];
                NSString *newUrl = [string stringByDeletingLastPathComponent];  //删除旧的后缀
                for (NSString *t in replaces) {
                    NSString *newLast = [component stringByReplacingCharactersInRange:range withString:t];
                    NSString *newString = [newUrl stringByAppendingPathComponent:newLast];
                    NSURL *newUrl = [NSURL URLWithString:newString];
                    if (newUrl == nil)continue;
                    
                    DTURLInfo *parse = [[DTURLInfo alloc] initWithURL:newUrl oldurl:string];
                    parse.last = t;
                    parse.isMore = YES;
                    [urls addObject:parse];
                    
                }
            } else {
                DTURLInfo *info = [[DTURLInfo alloc] initWithURL:[NSURL URLWithString:string] oldurl:string];
                [urls addObject:info];
            }
        }
        return urls;
    }
    
}


- (void)_xmlToURL:(NSString *)url  block:(void(^)(NSString *newXml))block{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    [[[DTOpertaion alloc] initWithURL:request path:nil response:nil complete:^(id data, NSError *error, BOOL finish ,NSString *url) {
        if (data) {
            id value = nil;
            if ([NSJSONSerialization isValidJSONObject:data]) {
                value = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
            } else {
                NSString *xml =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                value = xml;
            }
            if (value) {
                if (block)block(value);
            }
        } else {
            [self _failure:_url];
        }
        
    } progress:nil] start];
    
}


- (void)_failure:(NSString *)key {
    BOOL is = [[DTDiskCache diskCache] setValue:@(NO) key:key];
    if (is) {
        _isExecute = NO;
        if ([self _targetSelector:@selector(parse:didError:)]) {
            [_delegate parse:self didError:[NSError errorWithDomain:@"下载失败 整体" code:0 userInfo:nil]];
        }
    }
    
}
- (void)_start{
    for (int i = 0 ;  i  < self.totalURLs.count ; i ++ ) {
        [self _start:self.totalURLs[i]];
        if (self.maxCount == i + 1)break;
    }
}

- (void)_start:(DTURLInfo *)info{
    @autoreleasepool {
        NSURL *url = info.url;
        NSString *md5Url = info.oldUrl.MD5;
        NSString *replacePath = [_replaceFilePath appendingPath:md5Url];
        NSString *filePath = [_superDirPath appendingPath:md5Url];
        if (info.isMore) {
            filePath =  [filePath appending:info.last];
            replacePath =  [replacePath appending:@"%s"];
        }
        
        NSString *type = info.type;
        if (type != nil) {
            filePath = [filePath appending:type];
            replacePath = [replacePath appending:type];
        }
        __weak typeof(self)_self = self;
        DTOpertaionCompleteBlock completeBlock = ^(NSData * data,
                                                   NSError *error,
                                                   BOOL finish,
                                                   NSString *url){
            
            __strong typeof(_self)self = _self;
            dispatch_async(_main, ^{
                if (finish) {
                    [_totalURLs removeObject:info];
                    _finishCount ++;
                    if ([self _targetSelector:@selector(parse:didFinishCount:)]) {
                        [_delegate parse:self didFinishCount:_finishCount];
                    }
                    NSRange range =  [_replaceXml rangeOfString:info.oldUrl];
                    if (range.location != NSNotFound) {
                        _replaceXml = [_replaceXml stringByReplacingOccurrencesOfString:info.oldUrl withString:replacePath];
                    }
                    if ([self _targetSelector:@selector(parse:didFinishFilePathString:)]) {
                        [_delegate parse:self didFinishFilePathString:filePath];
                    }
                    if (_finishCount == _count && _totalURLs.count == 0) {
                        _isExecute = NO;
                        _finishCount = 0;
                        _isMaxCount = 0;
                        if ([_replaceXml writeToFile:_replaceXmlPath]) {
                            if ([self _targetSelector:@selector(parse:didFinishReplaceXmlFile:path:)]) {
                                [_delegate parse:self didFinishReplaceXmlFile:_replaceXml path:_replaceXmlPath];
                            }
                        }
                        if ([_xml writeToFile:_xmlPath]) {
                            if ([self _targetSelector:@selector(parse:didNewXmlString:path:)]) {
                                [_delegate parse:self didNewXmlString:_xml path:_xmlPath];
                            }
                        }
                        [[DTDiskCache diskCache] setValue:@(YES) key:_url];
                    } else {
                        _isMaxCount++;
                        if (_isMaxCount == _maxCount ) {
                            _isMaxCount = 0;
                            [self _start];
                        }
                    }
                } else {
                    if (_totalURLs.count) {
                        [self _failure:_url];
                        [[DTDiskCache diskCache] removeFilePath:filePath];
                    }
                    _isMaxCount = 0;
                    _isExecute = NO;
                }
            });
        };
        /**
         存在就完成并且文件的内容完整的
         假设中途 App 崩溃 本地文件不是完整的 但是存在的  这里效验本地文件存在的真实性
         
         */
        static  DTFileCache *fileCache = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *fileName =[NSString stringWithFormat:@"detu.com/%@",@"size.plist".MD5];
            if (fileCache == nil) {
                fileCache = [[DTFileCache alloc] initWithPath:fileName.cacheComponent];
            }
        });
        DTOpertaionResponseBlock response = ^(NSInteger size,NSString *url) {
            dispatch_async(_main, ^{
                [fileCache setValue:[NSNumber numberWithInteger:size] key:url];
            });
        };
        BOOL isExists  = [[DTDiskCache diskCache] isExistFilePath:filePath];
        NSInteger compSize = [[fileCache valueToKey:url.absoluteString] integerValue];
        NSInteger filesize = [filePath fileSize];
        BOOL isSame  = compSize == filesize;
        if (isExists && isSame) {
            completeBlock(nil,nil,YES,url.absoluteString);
        } else {
            if (filesize)[[DTDiskCache diskCache] removeFilePath:filePath]; //移除不完成的
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            DTOpertaion *opertaioin = [[DTOpertaion alloc] initWithURL:request path:filePath  response:response complete:completeBlock progress:nil];
            NSOperationQueue *queue = [NSOperationQueue new];
            if (queue) {
                [queue addOperation:opertaioin];
            } else {
                [opertaioin start];
                
            }
        }
        
    }
    
    //NSLog(@"%f", ( (self.finishCount * 1.0 ) + ((1.0 * receivedSize) / expectedSize ))/ (_count * 1.0));
}
- (void)_request{
    @autoreleasepool {
        if ([_delegate respondsToSelector:@selector(parse:didStartParse:)]) {
            [_delegate parse:self didStartParse:_url];
        }
        _isExecute = YES;
        NSString *url = self.url;
        NSString *oldXml =  [NSString stringWithContentsOfFile:_xmlPath encoding:NSUTF8StringEncoding error:nil];
        NSString *replaceXml = [NSString stringWithContentsOfFile:_replaceXmlPath encoding:NSUTF8StringEncoding error:nil];
        __weak typeof(self)_self = self;
        void (^requestBlock)(NSString *newXml) = ^(NSString *newXml){
            __strong typeof(_self)self = _self;
            _xml = [newXml copy];
            _replaceXml = [_xml copy];
            
            if (oldXml && [oldXml isEqualToString:newXml]) {
                dispatch_async(_main, ^{
                    _isSame =  YES;
                    _isExecute = NO;
                    
                    if ([self _targetSelector:@selector(parse:didFinishReplaceXmlFile:path:)]) {
                        [_delegate parse:self didFinishReplaceXmlFile:replaceXml path:_replaceXmlPath];
                    }
                });
            } else {
                
                NSMutableArray *urls = [parseFilter(newXml) mutableCopy];
                if ([self _targetSelector:@selector(parse:didFinishURLs:)]) {
                    [_delegate parse:self didFinishURLs:urls];
                }
                _urls = [urls mutableCopy];
                _totalURLs = [_urls mutableCopy];
                _count = (int)urls.count;
                if (_urls) {
                    [self _start];
                }
            }
        };
        
        
        if (replaceXml && _update) {  //是否要更新
            _isSame = NO;
            _isExecute = NO;
            if ([self _targetSelector:@selector(parse:didFinishReplaceXmlFile:path:)]) {
                [_delegate parse:self didFinishReplaceXmlFile:replaceXml path:_replaceXmlPath];
            }
        } else {
            
            [self _xmlToURL:url block:requestBlock];
        }
    }
    
}
- (void)_update:(NSString *)url{
    @autoreleasepool {
        _url = [url copy];
        _count = 0;
        NSString *superDir = [[[DTDiskCache diskCache] makeDirPath:url] copy];
        _xmlPath = [superDir appendingPath:url.MD5.appendingXMl];
        _replaceXmlPath = [superDir appendingPath:[url appending:@"replace"].MD5.appendingXMl];
        _replaceFilePath = [[DTDiskCache diskCache] smallReplaceFilePath:url];
        _superDirPath = superDir;
        
    }
}

-(void)start:(NSString *)url{
    if (self.isExecute) return;
    NSString *xmlUrl = [url copy];
    _isFinish = [[DTDiskCache diskCache] valueKey:url];
    [self _update:xmlUrl];  //处理文件路径
    [self _request];
    
}




@end
