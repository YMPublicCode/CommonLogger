//
//  NSURLRequest+YMNetworkingTime.m
//  LoggerDemo
//
//  Created by T on 2018/4/26.
//  Copyright © 2018年 T. All rights reserved.
//

#import "NSURLRequest+YMNetworkingTime.h"
#import <objc/runtime.h>
static char ymStartTime;   //请求开始时间
static char ymReqestNo;    //请求序列号

@implementation NSURLRequest (YMNetworkingTime)

- (void)setYmStartTime:(NSString *)startTime{
    objc_setAssociatedObject(self, &ymStartTime, startTime, OBJC_ASSOCIATION_COPY);
}

- (NSString *)ymStartTime{
    return objc_getAssociatedObject(self, &ymStartTime);
}

- (void)setYmReqestNo:(NSString *)aiaReqestNo1{
    objc_setAssociatedObject(self, &ymReqestNo, aiaReqestNo1, OBJC_ASSOCIATION_COPY);
}

- (NSString *)ymReqestNo{
    return objc_getAssociatedObject(self, &ymReqestNo);
}

@end
