//
//  ViewController.m
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "ViewController.h"
#import "YMLogger.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self startNetWork];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    // 压缩日志文件
    YMLogZipHandle(^(NSString *zipPath) {
        NSLog(@"zip path %@",zipPath);
    });
}

- (void)startNetWork{
    
    // step 1 构造请求
    NSURL *url = [NSURL URLWithString:@"https://baike.baidu.com/api/wikiui/getlemmaconfig"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:(NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:10];

    // 打印请求信息
    YMLogRequest(requset);
    
    // step 2 发送请求
    NSURLSessionTask *task = [[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
       
        //    step 3 处理相应
        if (!error) {
            // 打印响应信息
            YMLogResponse(data);
        }else{
            // 打印响应信息和错误息
            YMLogErrorResp(response, error);
        }
    }];
   
    [task resume];
}

@end
