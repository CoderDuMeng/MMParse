//
//   ;
//  DetuDownloadFile
//
//  Created by detu on 16/8/29.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^DTOpertaionResponseBlock)(NSInteger size,NSString *url);
typedef void (^DTOpertaionCompleteBlock)(id data ,NSError *error,BOOL finish ,NSString *url);
typedef void (^DTOpertaionProgressBlock)(NSInteger receivedSize, NSInteger expectedSize);



@interface DTOpertaion : NSOperation
/**
 *  传入请求的reqeust
 *
 *  @param request
 *  @param path     写入本地的path 如果为nil的话默认返回data  否则会根据传入进去的path 写流
 *  @param comlete  回调 失败 和 完成
 *  @param progress 进度
 *
 *  @return
 */
-(instancetype)initWithURL:(NSMutableURLRequest *)request
                      path:(NSString *)path
                  response:(DTOpertaionResponseBlock)response
                  complete:(DTOpertaionCompleteBlock)comlete
                  progress:(DTOpertaionProgressBlock)progress;

//响应的头部
@property (strong , nonatomic)  NSHTTPURLResponse  *response;
//完成的size
@property (assign, nonatomic)   NSInteger expectedSize;
//总size
@property (assign, nonatomic)   NSInteger  receivedSize;
//任务
@property (strong , nonatomic)  NSURLSessionDataTask  *task;
//是否完成 是根据 完成的size 和 总的size 比较
@property (assign , nonatomic , readonly)  BOOL isFinish;
@end
