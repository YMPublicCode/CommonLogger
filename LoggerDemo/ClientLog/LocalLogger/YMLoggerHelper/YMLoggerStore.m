//
//  YMLoggerStore.m
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "YMLoggerStore.h"


const NSString *kYMZIPPW = @"kYMZIPPW";
const NSString *kYMAESPW = @"kYMAESPW";

@interface YMLoggerStore()

@property (nonatomic,strong) NSMutableDictionary *loggerDic;

@end

@implementation YMLoggerStore

+ (instancetype)store{
    static dispatch_once_t onceToken;
    static YMLoggerStore *loggerStore;
    dispatch_once(&onceToken, ^{
        loggerStore = [[YMLoggerStore alloc] init];
        loggerStore->_loggerDic = [NSMutableDictionary dictionary];
    });
    return loggerStore;
}

- (void)saveString:(NSString *)str forKey:(NSString *)key{
    if (!str || !key) {
        NSLog(@"warning: str %@,key %@",str,key);
    }
    self.loggerDic[key] = str;
}

- (NSString *)stringForKey:(NSString *)key{
    if (!key) {
        NSLog(@"warning: key 不可以为空");
        return nil;
    }
    return self.loggerDic[key];
}

@end
