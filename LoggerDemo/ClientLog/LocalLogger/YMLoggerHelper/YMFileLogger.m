//
//  YMFileLogger.m
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "YMFileLogger.h"

@implementation YMFileLogger
- (void)logMessage:(DDLogMessage *)logMessage{
    @autoreleasepool{
        [super logMessage:logMessage];
    }
}

- (BOOL)hasLogHandle{
    return self->_currentLogFileInfo;
}
@end
