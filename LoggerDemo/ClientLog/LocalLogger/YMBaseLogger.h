//
//  YMBaseLogger.h
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YMBaseLogger : NSObject

@property (nonatomic,strong) dispatch_semaphore_t compressSemaphore;

+ (instancetype)shareInstance;

- (void)logString:(NSString *)str;

@end

