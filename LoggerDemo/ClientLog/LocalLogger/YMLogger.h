//
//  YMLogger.h
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#ifndef YMLogger_h
#define YMLogger_h

#import "YMBaseLogger.h"
#import "YMBaseLogger+Networking.h"

/**
 开始记录日志
 */
extern void YMLogStart();

/**
 停止日志记录
 */
extern void YMLogStop();

/**
 配置 日志信息

 @param aesPW 用于 aes 加密的 密码
 @param zipPW 用于 zip 加密的 密码
 */
extern void YMLogConf(NSString *aesPW,NSString *zipPW);

/**
 压缩日志文件

 @param ^zipComplete 压缩完成后 得到最后的 zip 文件 路径
 */
extern void YMLogZipHandle(void(^zipComplete)(NSString *zipPath));

#endif /* YMLogger_h */
