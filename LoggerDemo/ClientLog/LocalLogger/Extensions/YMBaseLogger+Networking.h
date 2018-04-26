//
//  YMBaseLogger+Networking.h
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "YMBaseLogger.h"
#import <objc/runtime.h>

#define YMLogRequest(requset)          NSString *__idenf = [[YMBaseLogger shareInstance] logRequest:request];

#define YMLogResponse(responseData)       do{ [[YMBaseLogger shareInstance] logResponse:responseData idenf:__idenf];}while(0);

#define YMLogErrorResp(response,error) do{ [[YMBaseLogger shareInstance] logResponse:(NSHTTPURLResponse *)response error:error idnf:__idenf]; }while(0);

@interface YMBaseLogger (Networking)

- (NSString *)logRequest:(NSURLRequest *)request;

- (void)logResponse:(NSObject *)responseData idenf:(NSString *)idenf;

- (void)logResponse:(NSHTTPURLResponse *)response error:(NSError *)err idnf:(NSString *)idenf;

@end
