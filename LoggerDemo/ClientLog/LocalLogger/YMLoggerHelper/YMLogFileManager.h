//
//  YMLogFileManager.h
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "DDFileLogger.h"
#import "CocoaLumberjack.h"

typedef void(^CompressComplete)(BOOL isSuccess);

@interface YMLogFileManager : DDLogFileManagerDefault
{
    BOOL upToDate;
    BOOL isCompressing;
}

@property (nonatomic,copy) CompressComplete compressComplete;

- (BOOL)hasLogFile;

@end
