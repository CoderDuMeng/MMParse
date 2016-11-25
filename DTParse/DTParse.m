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

static NSString *TypeToURL(NSString * url) {
    NSArray *types = @[@".png",@".jpg",@".mp4",@".mp3",@".JPG",@".PNG",@".MP4",@".MP3",@".mov",@".MOV"];
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


@interface DTParse()
{
    
    /**
     代理方法 判断的变量  是否执行
     */
    BOOL _delegateRespondDidStartParse;
    BOOL _delegateRespondDidNewXmlString;
    BOOL _delegateRespondDidFinishFilePathString;
    BOOL _delegateRespondDidFinishReplaceXmlFile;
    BOOL _delegateRespondDidFinishURLs;
    BOOL _delegateRespondDidFinishCount;
    BOOL _delegateResondDidError;
    
    
}

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
//缓存file size
@property (strong , nonatomic) DTFileCache *fileCache;
//队列对象
@property (strong , nonatomic) NSOperationQueue *operationQueue;

@end
@implementation DTParse
-(void)setDelegate:(id<DTParseDelegate>)delegate {
    if (_delegate != delegate) {
        _delegate = nil;
        _delegate = delegate;
        _delegateRespondDidStartParse = [_delegate respondsToSelector:@selector(parse:didStartParse:)];
        _delegateRespondDidNewXmlString = [_delegate respondsToSelector:@selector(parse:didNewXmlString:path:)];
        _delegateRespondDidFinishFilePathString = [_delegate respondsToSelector:@selector(parse:didFinishFilePathString:)];
        _delegateRespondDidFinishReplaceXmlFile = [_delegate respondsToSelector:@selector(parse:didFinishReplaceXmlFile:path:)];
        _delegateRespondDidFinishURLs = [_delegate respondsToSelector:@selector(parse:didFinishURLs:)];
        _delegateRespondDidFinishCount = [_delegate respondsToSelector:@selector(parse:didFinishCount:)];
        _delegateResondDidError = [_delegate respondsToSelector:@selector(parse:didError:)];
    }
}

-(instancetype)init{
    if (self=[super init]) {
        _maxCount = 6;
        _main = dispatch_get_main_queue();
        _queue  = dispatch_queue_create("com.detu.DTParse", DISPATCH_QUEUE_SERIAL);
        _operationQueue = [NSOperationQueue new];
        
        NSString *filePath = [NSString stringWithFormat:@"detu.com/%@",@"failure.plist".MD5].cacheComponent;
        _fileCache = [[DTFileCache alloc] initWithPath:filePath];
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
                value =  [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
            if (value && [value isKindOfClass:[NSString class]]) {
                if (block)block(value);
            }
        } else {
            [self _failureXMLURL:_url value:NO];
        }
        
    } progress:nil] start];
    
}

- (void)_failureXMLURL:(NSString *)key value:(BOOL)value{
    
    [_fileCache setValue:[NSNumber numberWithBool:value] key:key];
    
    if (!value) {
        _isExecute = value;
        if (_delegateResondDidError) {
            NSString *info = [NSString stringWithFormat:@"下载失败 XMLURL %@",key];
            [_delegate parse:self didError:[NSError errorWithDomain:info code:0 userInfo:nil]];
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
                    if (_delegateRespondDidFinishCount) {
                        [_delegate parse:self didFinishCount:_finishCount];
                    }
                    NSRange range =  [_replaceXml rangeOfString:info.oldUrl];
                    if (range.location != NSNotFound) {
                        _replaceXml = [_replaceXml stringByReplacingOccurrencesOfString:info.oldUrl withString:replacePath];
                    }
                    if (_delegateRespondDidFinishFilePathString) {
                        [_delegate parse:self didFinishFilePathString:filePath];
                    }
                    if (_finishCount == _count && _totalURLs.count == 0) {
                        _isExecute = NO;
                        _finishCount = 0;
                        _isMaxCount = 0;
                        if ([_replaceXml writeToFile:_replaceXmlPath]) {
                            if (_delegateRespondDidFinishReplaceXmlFile) {
                                [_delegate parse:self didFinishReplaceXmlFile:_replaceXml path:_replaceXmlPath];
                            }
                        }
                        if ([_xml writeToFile:_xmlPath]) {
                            if (_delegateRespondDidNewXmlString) {
                                [_delegate parse:self didNewXmlString:_xml path:_xmlPath];
                            }
                            
                        }
                        [self _failureXMLURL:_url value:YES];
                    } else {
                        _isMaxCount++;
                        if (_isMaxCount == _maxCount ) {
                            _isMaxCount = 0;
                            [self _start];
                        }
                    }
                } else {
                    if (_totalURLs.count) {
                        [self _failureXMLURL:_url value:NO];
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
        
        //响应
        DTOpertaionResponseBlock response = ^(NSInteger size,NSString *url) {
            dispatch_async(_main, ^{
                [fileCache setValue:[NSNumber numberWithInteger:size] key:url];
            });
        };
        
        NSString *stringURL = url.absoluteString;
        //内存中没有的话
        BOOL isMem = [[[DTMemoryCache memoryCache] valueToKey:filePath] boolValue];
        if (!isMem) {
            BOOL isExists  = [[DTDiskCache diskCache] isExistFilePath:filePath];
            NSInteger compSize = [[fileCache valueToKey:stringURL] integerValue];
            NSInteger filesize = [filePath fileSize];
            BOOL isSame  = compSize == filesize;
            /*
             
             验证本地是否存在  和 存在的是否完整  缺一不可
             
             本地有存每个文件的总size   每次都和本地已经存在的对比  相同是真实  否则假
             
             */
            if (isExists && isSame) {
                [[DTMemoryCache memoryCache] setValue:@(YES) key:filePath];
                completeBlock(nil,nil,YES,stringURL);
            } else {
                if (filesize)[[DTDiskCache diskCache] removeFilePath:filePath]; //移除不完成的
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
                DTOpertaion *opertaioin = [[DTOpertaion alloc] initWithURL:request path:filePath  response:response complete:completeBlock progress:nil];
                if (_operationQueue) {
                    [_operationQueue addOperation:opertaioin];
                } else {
                    [opertaioin start];
                }
            }
        } else {
            // 内存中有的了 并且本地是存在的 文件也是完整的
            completeBlock(nil,nil,YES,stringURL);
            
        }
    }
    
    //NSLog(@"%f", ( (self.finishCount * 1.0 ) + ((1.0 * receivedSize) / expectedSize ))/ (_count * 1.0));
}
- (void)_update{
    @autoreleasepool {
        if (_delegateRespondDidStartParse)[_delegate parse:self didStartParse:_url];
        
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
                    if (_delegateRespondDidFinishReplaceXmlFile) {
                        [_delegate parse:self didFinishReplaceXmlFile:replaceXml path:_replaceXmlPath];
                    }
                });
                
            } else {
                
                NSMutableArray *urls = [parseFilter(newXml) mutableCopy];
                if (_delegateRespondDidFinishURLs) {
                    [_delegate parse:self didFinishURLs:urls];
                }
                _urls = [urls mutableCopy];
                _totalURLs = [_urls mutableCopy];
                _count = (int)urls.count;
                if (_urls)[self _start];  // start download
            }
        };
        
        /*
         本地存在了的时候 设置是否要检查更新   isUpdate is YES 更新  default is NO  不更新
         */
        if (replaceXml && !self.isUpdate) {  //是否要更新
            _isSame = NO;
            _isExecute = NO;
            if (_delegateRespondDidFinishReplaceXmlFile) {
                [_delegate parse:self didFinishReplaceXmlFile:replaceXml path:_replaceXmlPath];
            }
        } else {
            [self _xmlToURL:url block:requestBlock];
        }
    }
    
}
- (void)_update:(NSString *)url{
    @autoreleasepool {
        /*
         处理xml 对应的本地路径 包括根部文件夹 xml 文件path
         */
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
    if (_isExecute) return;
    NSString *xmlUrl = [url copy];
    _isFinish = [[_fileCache valueToKey:url] boolValue];
    [self _update:xmlUrl];  //处理文件路径
    [self _update];
    
}


@end
