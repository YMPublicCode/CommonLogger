//
//  YMBaseLogger.m
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "YMBaseLogger.h"
#import <objc/runtime.h>
#import "CocoaLumberjack.h"
#import "ZipArchive.h"
#import "YMFileLogger.h"
#import "YMLogFileManager.h"
#import "YMLogFileFormatter.h"
#import "YMLoggerStore.h"
#define YMLOGDEBUG 1
#if YMLOGDEBUG
# define YMInfoLog(...) NSLog(__VA_ARGS__)
#else
# define YMInfoLog(...)
#endif

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
static const YMFileLogger *fileLogger = nil;
static const YMLogFileManager *fileManager = nil;

/**
 初始化Logger
 */
void initLogger(){
    
    NSArray *aryPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *strDocPath = [aryPath objectAtIndex:0];
    strDocPath = [strDocPath stringByAppendingString:@"/Logs"];
    YMInfoLog(@"日志沙盒目录 %@",strDocPath);
    
    if(DEBUG){
        // 在调试模式下 输出到控制台，发布模式不输出控制台
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
    }
    
    fileManager = [[YMLogFileManager alloc] initWithLogsDirectory:strDocPath];
    [fileManager setCompressComplete:^(BOOL isSuccess) {
        //本地压缩完成后，发送信号量通知完成
        if ([YMBaseLogger shareInstance].compressSemaphore) {
            dispatch_semaphore_signal([YMBaseLogger shareInstance].compressSemaphore);
        }
    }];
    fileLogger = [[YMFileLogger alloc] initWithLogFileManager:fileManager]; //
    YMLogFileFormatter *formtter = [YMLogFileFormatter new];
    fileLogger.logFormatter = formtter;
    fileLogger.rollingFrequency = 60 * 60 *24 ; // 24 * 1 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 20;
    [DDLog addLogger:fileLogger];
}


@interface YMBaseLogger(){

@public volatile BOOL _logEnable;//能否打印

}
@end

@implementation YMBaseLogger

+ (void)load{
    //自动初始化 Logger 相关（主要初始化DDLog）
    initLogger();
}

+ (instancetype)shareInstance{
    static YMBaseLogger *logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[YMBaseLogger alloc] init];
        logger->_logEnable = YES;
        logger->_compressSemaphore = nil;
    });
    return logger;
}

/**
 最终打印函数
 
 @param string 要打印的数据
 */
- (void)logString:(NSString *)string{
    if(_logEnable){
        //使用 DD log 打印
        DDLogInfo(@"%@",string);
    }
}

@end

/**
日志打印开始
*/
void YMLogStart(){
    [YMBaseLogger shareInstance]->_logEnable = YES;
}

/**
 日志打印结束
 */
void  YMLogStop(){
    [YMBaseLogger shareInstance]->_logEnable = NO;
}


void YMLogConf(NSString *aesPW,NSString *zipPW){
    [[YMLoggerStore store] saveString:zipPW forKey:kYMZIPPW];
    [[YMLoggerStore store] saveString:aesPW forKey:kYMAESPW];
}

/**
 压缩日志文件
 此代码 copy 来源项目中关于压缩部分
 @param path 日志文件总路径
 @param localZipPath 压缩完后 zip 包的 路径
 */
void zipArchiveLogs(NSString *path,NSString **localZipPath){
    
    NSArray *aryPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [aryPath objectAtIndex:0];
    NSString *zipFileName = [NSString stringWithFormat:@"%@.zip",@"log"];
    NSString *zipPath = [documentsPath stringByAppendingPathComponent:zipFileName];
    
    ZipArchive *ziparchive = [[ZipArchive alloc]init];
    // 压缩包密码
    
    NSString *zipPW = [[YMLoggerStore store] stringForKey:kYMZIPPW];
    [ziparchive CreateZipFile2:zipPath Password:zipPW];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *spath = path;
    
    NSArray *subPaths = [fileManager subpathsAtPath:spath];
    //        遍历取出文件路径
    for(NSString *subPath in subPaths)
    {
        NSString *fullPath = [spath  stringByAppendingPathComponent:subPath];
        
        BOOL isDir;
        if([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir)// 只处理文件
        {
            //                    向zip包里添加文件
            [ziparchive addFileToZip:fullPath newname:subPath];
        }
    }
    //        关闭zip包
    BOOL createZipSuccess =  [ziparchive CloseZipFile2];
    //        在生成zip包成功的情况下
    if (createZipSuccess) {
        *localZipPath = zipPath;
    }else{
        *localZipPath = nil;
    }
}

/**
 上传日志压缩包
 
 @param zipComplete 压缩完成后要进行的处理 zipPath 为压缩完成后的 zip 包路径
 */
void YMLogZipHandle(void(^zipComplete)(NSString *zipPath)){
    
    if ([YMBaseLogger shareInstance].compressSemaphore) {
        YMInfoLog(@"日志压缩中，请等待");
        return;
    }
    
    YMInfoLog(@"开始日志封存");
    [YMBaseLogger shareInstance].compressSemaphore = dispatch_semaphore_create(0);
    
    //    有log后缀的文件，说明需要日志需要内部压缩 .log-》.gz
    BOOL hasLogFile = [fileManager hasLogFile];
    
    [fileLogger rollLogFileWithCompletionBlock:^{
        @autoreleasepool{
            YMInfoLog(@"日志封存结束");
            
            if(!hasLogFile){
                YMInfoLog(@"无需内部压缩");
            }else{
                YMInfoLog(@"日志内部压缩开始");
                NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
                
                if(![YMBaseLogger shareInstance].compressSemaphore){
                    NSLog(@"日志服务异常，稍后重试");
                    zipComplete(nil);
                    return ;
                }
                
                // 等待信号量返回，设置超时时间为 10 秒
                dispatch_semaphore_wait([YMBaseLogger shareInstance].compressSemaphore, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
                
                NSTimeInterval endTime = [[NSDate date] timeIntervalSince1970];
                NSString *localDes = [NSString stringWithFormat:@"耗时： %@ ",@(endTime - startTime)];
                YMInfoLog(@"日志内部压缩 %@",localDes);
                YMInfoLog(@"日志内部压缩结束");
            }
            
            // 信号量返回或者没有使用信号量， 现将信号量置为空，下次使用时再创建即可，
            // 现在设计是每一次压缩成功都会判断 compressSemaphore 是否为空
            // 不为空就调用
            // dispatch_semaphore_signal(compressSemaphore);
            // 保证每一次需要监控日志压缩完成后都能收到信息
            
            [YMBaseLogger shareInstance].compressSemaphore = nil;
            
            YMInfoLog(@"日志文件汇总压缩成 zip 开始");
            NSString *path = fileManager.logsDirectory;
            NSString *zipPath = nil;
            
            zipArchiveLogs(path, &zipPath);
            YMInfoLog(@"日志全部压缩结束");
            if(zipComplete){
                zipComplete(zipPath);
            }
        }
    }];
}
