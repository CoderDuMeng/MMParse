//
//  DTParse.h
//  DetuDownloadFile
//
//  Created by detu on 16/9/10.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import <Foundation/Foundation.h>
/**解析是否是6个面的url 以及检验 URL 是否为真是的 URL 不会出现畸形*/
@interface DTURLInfo: NSObject
-(instancetype)initWithURL:(NSURL *)url oldurl:(NSString *)oldUrl;
@property (copy , nonatomic, readonly) NSString *oldUrl; //<< 解析的url
@property (copy , nonatomic, readonly) NSURL    *url;   //<< 解析完成以后新的url
@property (assign , nonatomic) BOOL   isMore; //<< 判断是否是 %s
@property (copy , nonatomic) NSString *last;  //后面拼接的后缀
@property (copy , nonatomic , readonly) NSString *type;
@end

@class DTParse , DTURLInfo;

@protocol DTParseDelegate <NSObject>

@optional
/**开始任务*/
- (void)parse:(DTParse *)parse didStartParse:(NSString *)url;
/**没有替换的xml 获取回来的*/
- (void)parse:(DTParse *)parse didNewXmlString:(NSString *)string path:(NSString *)path;
/**每一次下载完成的都会调用这个方法*/
- (void)parse:(DTParse *)parse didFinishFilePathString:(NSString *)string;
/*群补下载完毕的时候会调用此方法 返回一个地址 和 返回 xml string*/
- (void)parse:(DTParse *)parse didFinishReplaceXmlFile:(NSString *)string  path:(NSString *)path;
/**返回全部要下载的url对象*/
- (void)parse:(DTParse *)parse didFinishURLs:(NSMutableArray <DTURLInfo *>*)urls;
/**每次完成以后回调 下载完成的个数*/
- (void)parse:(DTParse *)parse didFinishCount:(int )count;
/**请求xml 文件error 的时候会调用  正在下载的时候出现error的时候会调用 调用一次error 就会全部停止*/
- (void)parse:(DTParse *)parse didError:(NSError *)error;


@end
/***
 失败和成功是围绕 xml地址来完成  传入xml地址 解析完成url 首先回去本地 本地没有去下载
 每一次从新获取xml 都是最新的
 */

@interface DTParse : NSObject
@property (assign , nonatomic , readonly) BOOL isFinish; //<<是否是完成下载过的xml地址
@property (copy , nonatomic   ,readonly)  NSString  *url; //解析xml的地址
@property (strong , nonatomic ,readonly) NSMutableArray *urls; //全部Urls
@property (assign , nonatomic , readonly) int  count; //<<全部执行url 个数
@property (assign , nonatomic , readonly) BOOL isExecute;//<< 是否正在执行
@property (assign , nonatomic , readonly) BOOL isSame;//<< 是不是和本地相同的xml  是 return 1
@property (copy   , nonatomic , readonly)  NSString *replaceXml; //<< 最新的xml 替换完成本地地址的
@property (weak , nonatomic) id <DTParseDelegate>delegate; //<< 代理对象
@property (copy , nonatomic,readonly) NSString *superDirPath; //<<每个xml地址创建的文件夹的跟文件夹的path


@property (assign , nonatomic)  BOOL update; //<< 本地是下载完整的是否去更新


/**开始请求xml 解析xml  下载xml 里面每一个url*/
- (void)start:(NSString *)url;






@end
