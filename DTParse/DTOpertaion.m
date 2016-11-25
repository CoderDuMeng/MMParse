//
//  DTOpertaion.m
//  DetuDownloadFile
//
//  Created by detu on 16/8/29.
//  Copyright © 2016年 demoDu. All rights reserved.
//

#import "DTOpertaion.h"
#import "DTDiskCache.h"
#import <UIKit/UIKit.h>


@interface DTOpertaion() <NSURLSessionTaskDelegate ,NSURLSessionDataDelegate>
@property (strong , nonatomic)  NSMutableURLRequest       *request;
@property (strong , nonatomic)  NSMutableData             *data;
@property (copy   , nonatomic)  DTOpertaionResponseBlock  responseBlock;
@property (copy   , nonatomic)  DTOpertaionCompleteBlock complete;
@property (copy   , nonatomic)  DTOpertaionProgressBlock progress;
@property (assign , nonatomic)  BOOL finish;
@property (copy   , nonatomic)  NSString *path;
@property (copy   , nonatomic)  NSString *url;
@property (strong , nonatomic)  NSOutputStream *stream;
@property (assign , nonatomic)  NSUInteger taskIdentifier;

@end
@implementation DTOpertaion
UIApplication *DTApplication(){
    return [UIApplication sharedApplication];
}
-(instancetype)initWithURL:(NSMutableURLRequest *)request
                      path:(NSString *)path
                  response:(DTOpertaionResponseBlock)response
                  complete:(DTOpertaionCompleteBlock)comlete
                  progress:(DTOpertaionProgressBlock)progress{
    if (self=[super init]) {
        _path = [path copy];
        _request  = request;
        _complete = [comlete copy];
        _progress = [progress copy];
        _responseBlock = [response copy];
        _url = [request.URL.absoluteString copy];
    }
    return self;
}

-(BOOL)isFinish{
    if (self.receivedSize == self.expectedSize)return YES;
    return NO;
}

-(void)start{
    NSURLSessionConfiguration *configuration  = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest   = 15;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSURLSessionDataTask *task  = [session dataTaskWithRequest:_request];
    _task = task;
    [_task resume];
    
}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    @autoreleasepool {
        NSError *error = nil;
        _response = (id) response;
        NSInteger starusCode = self.response.statusCode;
        if (starusCode > 400 || starusCode == 304) {
            error = [NSError errorWithDomain:NSURLErrorDomain code:starusCode userInfo:nil];
        }
        if (error) {
            _finish = NO;
            if (_complete)_complete(nil,error,_finish,_url);
            [_task cancel];
        } else {
            _expectedSize = (NSInteger)_response.expectedContentLength;
            if (_path) {
                _stream = [NSOutputStream outputStreamToFileAtPath:_path append:YES];
                [_stream  open];
            } else {
                _data = [NSMutableData new];
                
            }
            if(_progress)_progress(_receivedSize,_expectedSize);
            if(_responseBlock)_responseBlock(_expectedSize,_url);
            
        }
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    @autoreleasepool {
        if (_finish) return;
        NSInteger totalLength = _expectedSize;
        _receivedSize+=data.length;
        if (_progress)_progress(_receivedSize,totalLength);
        
        if (_data) {
            [_data appendData:data];
        } else {
            NSInteger result = [_stream write:data.bytes maxLength:data.length];
            if (result == -1) {
                [_stream close];
                [self cancel];
                
            }
        }
        if (_receivedSize == totalLength) {
            _finish = YES;
            if (_complete)_complete(_data , nil , YES , _url);
            [_stream close];
        }
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error) {
        if (_complete)_complete(nil,error,NO,_url);
        [self cancel];
    }
    
}
-(void)cancel{
    [_task cancel];
    if (_path && !self.finish) {
        [[NSFileManager defaultManager]removeItemAtPath:_path error:nil];
    }
    if (_complete)_complete(nil ,[NSError errorWithDomain:@"DTParse.cancel" code:0 userInfo:nil], NO, _url);
    [super cancel];
}

@end
