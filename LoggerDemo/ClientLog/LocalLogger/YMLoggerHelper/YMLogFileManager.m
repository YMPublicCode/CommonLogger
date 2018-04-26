//
//  YMLogFileManager.m
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "YMLogFileManager.h"
#import <objc/runtime.h>
#import <objc/message.h>
#define LOG_LEVEL 4

#define NSLogError(frmt, ...)    do{ if(LOG_LEVEL >= 1) NSLog(frmt, ##__VA_ARGS__); } while(0)
#define NSLogWarn(frmt, ...)     do{ if(LOG_LEVEL >= 2) NSLog(frmt, ##__VA_ARGS__); } while(0)
#define NSLogInfo(frmt, ...)     do{ if(LOG_LEVEL >= 3) NSLog(frmt, ##__VA_ARGS__); } while(0)
#define NSLogVerbose(frmt, ...)  do{ if(LOG_LEVEL >= 4) NSLog(frmt, ##__VA_ARGS__); } while(0)
#import "NVHTarGzip.h"



@interface DDLogFileInfo (Compressor)

@property (nonatomic, readonly) BOOL isCompressed;

- (NSString *)tempFilePathByAppendingPathExtension:(NSString *)newExt;
- (NSString *)fileNameByAppendingPathExtension:(NSString *)newExt;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation DDLogFileInfo (Compressor)

@dynamic isCompressed;

- (BOOL)isCompressed
{
    return [[[self fileName] pathExtension] isEqualToString:@"gz"];
}

- (NSString *)tempFilePathByAppendingPathExtension:(NSString *)newExt
{
    // Example:
    //
    // Current File Name: "/full/path/to/log-ABC123.txt"
    //
    // newExt: "gzip"
    // result: "/full/path/to/temp-log-ABC123.txt.gzip"
    
    NSString *tempFileName = [NSString stringWithFormat:@"temp-%@", [self fileName]];
    
    NSString *newFileName = [tempFileName stringByAppendingPathExtension:newExt];
    
    NSString *fileDir = [[self filePath] stringByDeletingLastPathComponent];
    
    NSString *newFilePath = [fileDir stringByAppendingPathComponent:newFileName];
    
    return newFilePath;
}


- (NSString *)fileNameByAppendingPathExtension:(NSString *)newExt
{
    // Example:
    //
    // Current File Name: "log-ABC123.txt"
    //
    // newExt: "gzip"
    // result: "log-ABC123.txt.gzip"
    
    NSString *fileNameExtension = [[self fileName] pathExtension];
    
    if ([fileNameExtension isEqualToString:newExt])
    {
        return [self fileName];
    }
    
    return [[self fileName] stringByAppendingPathExtension:newExt];
}

@end


@interface YMLogFileManager()

@property (readwrite) BOOL isCompressing;

@end

@implementation YMLogFileManager

@synthesize isCompressing;

- (id)init
{
    return [self initWithLogsDirectory:nil];
}

- (id)initWithLogsDirectory:(NSString *)aLogsDirectory
{
    if ((self = [super initWithLogsDirectory:aLogsDirectory]))
    {
        upToDate = NO;
        
        // Check for any files that need to be compressed.
        // But don't start right away.
        // Wait for the app startup process to finish.
        
        [self performSelector:@selector(compressNextLogFile) withObject:nil afterDelay:5.0];
    }
    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(compressNextLogFile) object:nil];
}


- (void)compressLogFile:(DDLogFileInfo *)logFile
{
    self.isCompressing = YES;
    
    YMLogFileManager* __weak weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [weakSelf backgroundThread_CompressLogFile:logFile];
    });
}

- (void)compressNextLogFile
{
    if (self.isCompressing)
    {
        // We're already compressing a file.
        // Wait until it's done to move onto the next file.
        return;
    }
    
    NSLogVerbose(@"CompressingLogFileManager: compressNextLogFile");
    
    upToDate = NO;
    
    NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
    
    NSUInteger count = [sortedLogFileInfos count];
    if (count == 0)
    {
        // Nothing to compress
        upToDate = YES;
        return;
    }
    
    NSUInteger i = count;
    while (i > 0)
    {
        DDLogFileInfo *logFileInfo = [sortedLogFileInfos objectAtIndex:(i - 1)];
        
        if (logFileInfo.isArchived && !logFileInfo.isCompressed)
        {
            [self compressLogFile:logFileInfo];
            
            break;
        }
        
        i--;
    }
    
    upToDate = YES;
    
}

- (void)compressionDidSucceed:(DDLogFileInfo *)logFile
{
    NSLogVerbose(@"CompressingLogFileManager: compressionDidSucceed: %@", logFile.fileName);
    
    self.isCompressing = NO;
    
    [self compressNextLogFile];
    
    if (self.compressComplete) {
        self.compressComplete(YES);
    }
}

- (void)compressionDidFail:(DDLogFileInfo *)logFile
{
    NSLogWarn(@"CompressingLogFileManager: compressionDidFail: %@", logFile.fileName);
    
    self.isCompressing = NO;
    
    // We should try the compression again, but after a short delay.
    //
    // If the compression failed there is probably some filesystem issue,
    // so flooding it with compression attempts is only going to make things worse.
    
    NSTimeInterval delay = (60 * 15); // 15 minutes
    
    [self performSelector:@selector(compressNextLogFile) withObject:nil afterDelay:delay];
    
    //压缩信号量 发送
    if (self.compressComplete) {
        self.compressComplete(NO);
    }
}

- (void)didArchiveLogFile:(NSString *)logFilePath
{
    NSLogVerbose(@"CompressingLogFileManager: didArchiveLogFile: %@", [logFilePath lastPathComponent]);
    
    // If all other log files have been compressed,
    // then we can get started right away.
    // Otherwise we should just wait for the current compression process to finish.
    
    if (upToDate)
    {
        [self compressLogFile:[DDLogFileInfo logFileWithPath:logFilePath]];
    }
}

- (void)didRollAndArchiveLogFile:(NSString *)logFilePath
{
    NSLogVerbose(@"CompressingLogFileManager: didRollAndArchiveLogFile: %@", [logFilePath lastPathComponent]);
    
    // If all other log files have been compressed,
    // then we can get started right away.
    // Otherwise we should just wait for the current compression process to finish.
    
    if (upToDate)
    {
        [self compressLogFile:[DDLogFileInfo logFileWithPath:logFilePath]];
    }
}

- (void)backgroundThread_CompressLogFile:(DDLogFileInfo *)logFile
{
    
    
    @autoreleasepool {
        
        NSLogInfo(@"CompressingLogFileManager: Compressing log file: %@", logFile.fileName);
        
        // Steps:
        //  1. Create a new file with the same fileName, but added "gzip" extension
        //  2. Open the new file for writing (output file)
        //  3. Open the given file for reading (input file)
        //  4. Setup zlib for gzip compression
        //  5. Read a chunk of the given file
        //  6. Compress the chunk
        //  7. Write the compressed chunk to the output file
        //  8. Repeat steps 5 - 7 until the input file is exhausted
        //  9. Close input and output file
        // 10. Teardown zlib
        
        
        // STEP 1
        
        NSString *inputFilePath = logFile.filePath;
        
        NSString *tempOutputFilePath = [logFile tempFilePathByAppendingPathExtension:@"gz"];
        
#if TARGET_OS_IPHONE
        // We use the same protection as the original file.  This means that it has the same security characteristics.
        // Also, if the app can run in the background, this means that it gets
        // NSFileProtectionCompleteUntilFirstUserAuthentication so that we can do this compression even with the
        // device locked.  c.f. DDFileLogger.doesAppRunInBackground.
        NSString* protection = logFile.fileAttributes[NSFileProtectionKey];
        NSDictionary* attributes = protection == nil ? nil : @{NSFileProtectionKey: protection};
        [[NSFileManager defaultManager] createFileAtPath:tempOutputFilePath contents:nil attributes:attributes];
#endif
        NSError *error;
        
        BOOL isSuccess = [[NVHTarGzip sharedInstance] gzipFileAtPath:logFile.filePath toPath:tempOutputFilePath error:&error];
        
        if (error)
        {
            // Remove output file.
            // Our compression attempt failed.
            
            NSLogError(@"Compression of %@ failed: %@", inputFilePath, error);
            error = nil;
            BOOL ok = [[NSFileManager defaultManager] removeItemAtPath:tempOutputFilePath error:&error];
            if (!ok)
                NSLogError(@"Failed to clean up %@ after failed compression: %@", tempOutputFilePath, error);
            
            // Report failure to class via logging thread/queue
            
            dispatch_async([DDLog loggingQueue], ^{ @autoreleasepool {
                
                [self compressionDidFail:logFile];
            }});
        }
        else
        {
            // Remove original input file.
            // It will be replaced with the new compressed version.
            
            error = nil;
            BOOL ok = [[NSFileManager defaultManager] removeItemAtPath:inputFilePath error:&error];
            if (!ok)
                NSLogWarn(@"Warning: failed to remove original file %@ after compression: %@", inputFilePath, error);
            
            // Mark the compressed file as archived,
            // and then move it into its final destination.
            //
            // temp-log-ABC123.txt.gz -> log-ABC123.txt.gz
            //
            // The reason we were using the "temp-" prefix was so the file would not be
            // considered a log file while it was only partially complete.
            // Only files that begin with "log-" are considered log files.
            
            DDLogFileInfo *compressedLogFile = [DDLogFileInfo logFileWithPath:tempOutputFilePath];
            compressedLogFile.isArchived = YES;
            
            NSString *outputFileName = [logFile fileNameByAppendingPathExtension:@"gz"];
            [compressedLogFile renameFile:outputFileName];
            
            // Report success to class via logging thread/queue
            
            dispatch_async([DDLog loggingQueue], ^{ @autoreleasepool {
                
                [self compressionDidSucceed:compressedLogFile];
            }});
        }
    } // end @autoreleasepool
}


- (BOOL)hasLogFile{
    NSArray *sortedLogFileInfos = [self sortedLogFileInfos];
    NSUInteger count = [sortedLogFileInfos count];
    return count;
}

- (void)deleteOldLogFiles {

//    重写父类 删除日志文件方法
//    目前方案待改善
    
    NSString *logsDirectory = [self logsDirectory];
    NSArray *fileNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:logsDirectory error:nil];
    
    if ([fileNames count] < self.maximumNumberOfLogFiles) {
        return;
    }
    
    for (NSString *fileName in fileNames) {
        
        if ([fileName hasSuffix:@"gz"])
            
        {
            NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];
            
            NSDate *creatDate = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil][NSFileCreationDate];
            if (-[creatDate timeIntervalSinceNow] > 60*60*24*7) {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
        }
    }
}
@end
