//
//  YMBaseLogger+Networking.m
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "YMBaseLogger+Networking.h"
#import "NSURLRequest+YMNetworkingTime.h"


@interface YMResponseLogInfo: NSObject

@property (nonatomic,copy) NSString *responseHeader;
@property (nonatomic,copy) NSString *responseBaseInfo;
@property (nonatomic,copy) NSArray<NSString *> *responseContents;

@property (nonatomic,copy) NSString *responseJioner;
@property (nonatomic,copy) NSString *responseFromRequest;
@property (nonatomic,copy) NSString *responseFooter;

@end

@implementation YMResponseLogInfo
@end

static char YMRequestDic;
@interface YMBaseLogger()

@property (nonatomic,strong) NSMutableDictionary *requestDic;//请求保存字典
@end

@implementation YMBaseLogger (Networking)

#pragma mark - Public Method
/**
 打印 请求信息
 
 @param request 请求对象
 @return 请求信息汇总字符串
 */
- (NSString *)logRequest:(NSURLRequest *)request{
    
    NSString *genNo = [self generatSerialNo];
    request.ymStartTime = [NSDate date];
    request.ymReqestNo = genNo;
    
    NSString *requsetString = [self converStringByRequest:request];
    
    [self.requestDic setObject:request forKey:genNo];
    [self logString:requsetString];
    
    return genNo;
}

/**
 打印响应信息
 
 @param response 响应体
 @param idenf 标识符
 */
- (void)logResponse:(NSObject *)response idenf:(NSString *)idenf{
    NSURLRequest *req;
    if (!idenf) {
        NSLog(@"警告：标志符为空，请悉知");
    }else{
        // 查找到响应的 request 对象
        req = self.requestDic[idenf];
    }
    
    YMResponseLogInfo *responseString = [self converStringByResponse:response  req:req];
    
    [self logResponseInfo:responseString];
    
    // 打印完成 将 request 从字典中移除
    [self.requestDic removeObjectForKey:idenf];
}

/**
 打印响应信息
 
 @param response 响应体
 @param err 错误信息
 @param idenf 标识符
 */
- (void)logResponse:(NSHTTPURLResponse *)response error:(NSError *)err idnf:(NSString *)idenf{
    NSURLRequest *req;
    if (!idenf) {
        NSLog(@"警告：标志符为空，请悉知");
    }else{
        req = self.requestDic[idenf];
    }
    
    YMResponseLogInfo *responseString = [self converStringByResponse:response error:err req:req];
    
    [self logResponseInfo:responseString];
    [self.requestDic removeObjectForKey:idenf];
}

#pragma mark Private Method


/**
 转换 Request to String
 
 @param request 要打印的Request 对象
 @return requestString
 */
- (NSString *)converStringByRequest:(NSURLRequest *)request{
    if (!request) {
        return @"aiawarn:---- request 为空，请检查";
    }
    NSMutableString *logString = [NSMutableString stringWithString:@"\n\n**************************************************************\n*                       Request Start                        *\n**************************************************************\n\n"];
    
    [logString appendFormat:@"\n\nHTTP StartTime:\n\t%@", request.ymStartTime];
    [logString appendFormat:@"\n\nHTTP ReqNO:\n\t%@", request.ymReqestNo];
    [logString appendFormat:@"\n\nHTTP Method:\n\t%@", request.HTTPMethod];
    [logString appendFormat:@"\n\nHTTP URL:\n\t%@", request.URL];
    [logString appendFormat:@"\n\nHTTP Header:\n%@", request.allHTTPHeaderFields ? request.allHTTPHeaderFields : @"\t\t\t\t\tN/A"];
    
    [logString appendFormat:@"\n\nHTTP Body:\n\t%@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] ];
    
    [logString appendFormat:@"\n\n**************************************************************\n*                         Request End                        *\n**************************************************************\n\n\n\n"];
    
    return logString;
}

/**
 转换 Response to String
 
 @param response 要打印的resp 对象
 @param request 要关联的req 对象
 @return 连接后的字符串
 */
- (YMResponseLogInfo *)converStringByResponse:(NSObject *)response req:(NSURLRequest *)request{
    YMResponseLogInfo *responseInfo = [YMResponseLogInfo new];
    NSDate *reqStartDate = request.ymStartTime;
    //网络耗时
    NSTimeInterval requestTime = [[NSDate date] timeIntervalSinceDate:reqStartDate];
    
    responseInfo.responseHeader = @"\n\n==============================================================\n=                        API Response                        =\n==============================================================\n\n";
    
    responseInfo.responseBaseInfo = @"";
    responseInfo.responseContents = @[];
    responseInfo.responseJioner = @"\n---------------  Related Request Content  --------------\n";
    responseInfo.responseFromRequest = @"";
    responseInfo.responseFooter = @"\n\n==============================================================\n=                        Response End                        =\n==============================================================\n\n\n\n";
    NSString *contentStr ;
    if ([response isKindOfClass:[NSData class]]) {
        @autoreleasepool{
            NSString *jsonString = [[NSString alloc] initWithData:(NSData *)response encoding:NSUTF8StringEncoding];
            contentStr =  [NSString stringWithFormat:@"Content:\n %@ \n\n",jsonString];;
        }
    }else{
        contentStr = [NSString stringWithFormat:@"Content:\n %@ \n\n",response];
    }
    
    NSMutableArray *contentsArray = [NSMutableArray array];
    
    [contentsArray addObject:[contentStr copy]];
    responseInfo.responseContents = [contentsArray copy];
    
    
    NSMutableString *logString = [NSMutableString string];
    if (!request) {
        [logString appendFormat:@"\n\n%@:\n\t",@"request 为 空，请检查" ];
    }else{
        [logString appendFormat:@"\n\nHTTP StartTime:\n\t%@", request.ymStartTime];
        [logString appendFormat:@"\n\nHTTP RequestTime:\n\t%f", requestTime];
        
        [logString appendFormat:@"\n\nHTTP ReqNO:\n\t%@", request.ymReqestNo];
        [logString appendFormat:@"\n\nHTTP URL:\n\t%@", request.URL];
        [logString appendFormat:@"\n\nHTTP Header:\n%@", request.allHTTPHeaderFields ? request.allHTTPHeaderFields : @"\t\t\t\t\tN/A"];
        
        [logString appendFormat:@"\n\nHTTP Body:\n\t%@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] ];
    }
    responseInfo.responseFromRequest = [logString copy];
    
    return responseInfo;
}

/**
 转换 Response to String
 
 @param response 要打印的resp 对象
 @param error 错误信息对象 对象
 @param request 要关联的请求 对象
 @return 连接后的字符串
 */
- (YMResponseLogInfo *)converStringByResponse:(NSHTTPURLResponse *)response error:(NSError *)error req:(NSURLRequest *)request{
    YMResponseLogInfo *responseInfo = [YMResponseLogInfo new];
    NSDate *reqStartDate = request.ymStartTime;
    //网络耗时
    NSTimeInterval requestTime = [[NSDate date] timeIntervalSinceDate:reqStartDate];
    
    responseInfo.responseHeader = @"\n\n==============================================================\n=                        API Response                        =\n==============================================================\n\n";
    
    NSMutableString *errStr = [NSMutableString string];
    
    [errStr appendFormat:@"Status:\t%ld\t(%@)\n\n", (long)response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]];
    [errStr appendFormat:@"Content:\n%@\n\n", response];
    [errStr appendFormat:@"Error Domain:\t\t\t\t\t\t\t%@\n", error.domain];
    [errStr appendFormat:@"Error Domain Code:\t\t\t\t\t\t%ld\n", (long)error.code];
    [errStr appendFormat:@"Error Localized Description:\t\t\t%@\n", error.localizedDescription];
    [errStr appendFormat:@"Error Localized Failure Reason:\t\t\t%@\n", error.localizedFailureReason];
    [errStr appendFormat:@"Error Localized Recovery Suggestion:\t%@\n\n", error.localizedRecoverySuggestion];
    responseInfo.responseBaseInfo = [errStr copy];
    
    
    responseInfo.responseContents = @[];
    responseInfo.responseJioner = @"\n---------------  Related Request Content  --------------\n";
    responseInfo.responseFromRequest = @"";
    responseInfo.responseFooter = @"\n\n==============================================================\n=                        Response End                        =\n==============================================================\n\n\n\n";
    NSString *contentStr ;
    if ([response isKindOfClass:[NSData class]]) {
        @autoreleasepool{
            NSString *jsonString = [[NSString alloc] initWithData:(NSData *)response encoding:NSUTF8StringEncoding];
            contentStr =  [NSString stringWithFormat:@"Content:\n %@ \n\n",jsonString];;
        }
    }else{
        contentStr = [NSString stringWithFormat:@"Content:\n %@ \n\n",response];
    }
    NSMutableArray *contentsArray = [NSMutableArray array];
    
    [contentsArray addObject:[contentStr copy]];
    responseInfo.responseContents = [contentsArray copy];
    
    
    NSMutableString *logString = [NSMutableString string];
    if (!request) {
        [logString appendFormat:@"\n\n%@:\n\t",@"request 为 空，请检查" ];
    }else{
        [logString appendFormat:@"\n\nHTTP StartTime:\n\t%@", request.ymStartTime];
        [logString appendFormat:@"\n\nHTTP RequestTime:\n\t%f", requestTime];
        
        [logString appendFormat:@"\n\nHTTP ReqNO:\n\t%@", request.ymReqestNo];
        [logString appendFormat:@"\n\nHTTP URL:\n\t%@", request.URL];
        [logString appendFormat:@"\n\nHTTP Header:\n%@", request.allHTTPHeaderFields ? request.allHTTPHeaderFields : @"\t\t\t\t\tN/A"];
        
        [logString appendFormat:@"\n\nHTTP Body:\n\t%@", [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] ];
    }
    responseInfo.responseFromRequest = [logString copy];
    
    
    return responseInfo;
}



- (void)logResponseInfo:(YMResponseLogInfo *)responseInfo{
    //    组装 response 打印对象
    NSMutableString *logString = [NSMutableString string];
    
    [logString appendString:responseInfo.responseHeader?:@""];
    [logString appendString:responseInfo.responseBaseInfo?:@""];
    for (NSString *content in responseInfo.responseContents) {
        [logString appendString:content?:@""];
    }
    [logString appendString:responseInfo.responseJioner?:@""];
    [logString appendString:responseInfo.responseFromRequest?:@""];
    [logString appendString:responseInfo.responseFooter?:@""];
    [self logString: logString?:@""];
}

/**
 *  生成序列号
 *
 *   @return 序列数
 */
- (NSString  *)generatSerialNo{
    static int i = 0;
    
    if (i > 1000) {
        i = 0;
    }
    i++;
    
    return [@(i) stringValue];
}

#pragma mark - Getter and Setter
- (NSMutableDictionary *)requestDic{
    NSMutableDictionary *dic = objc_getAssociatedObject(self, &YMRequestDic);
    if (!dic) {
        dic = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &YMRequestDic, dic, OBJC_ASSOCIATION_RETAIN);
    }
    return dic;
}

@end
