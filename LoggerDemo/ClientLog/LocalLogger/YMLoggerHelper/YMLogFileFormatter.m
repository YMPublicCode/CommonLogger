//
//  YMLogFileFormatter.m
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "YMLogFileFormatter.h"
#import "AESCrypt.h"
#import "YMLoggerStore.h"
@implementation YMLogFileFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage{
    NSString *orgString = logMessage->_message;
    NSString *aesPW = [[YMLoggerStore store] stringForKey:kYMAESPW]?:@"";
    NSString *cryptSt = [AESCrypt encrypt:orgString password:aesPW];
    return  [NSString stringWithFormat:@"%@***",cryptSt];
}

@end
