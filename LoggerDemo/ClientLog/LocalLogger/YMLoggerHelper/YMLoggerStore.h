//
//  YMLoggerStore.h
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *kYMZIPPW;  //zip pw m
extern NSString *kYMAESPW;   //aes pw m

@interface YMLoggerStore : NSObject

+ (instancetype)store;

- (void)saveString:(NSString *)str forKey:(NSString *)key;

- (NSString *)stringForKey:(NSString *)key;

@end
