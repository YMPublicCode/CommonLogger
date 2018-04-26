//
//  NSURLRequest+YMNetworkingTime.h
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (YMNetworkingTime)

/**
 请求开始时间
 */
@property (nonatomic,copy) NSDate *ymStartTime;

/**
 请求序列号
 */
@property (nonatomic,copy) NSString *ymReqestNo;

@end

