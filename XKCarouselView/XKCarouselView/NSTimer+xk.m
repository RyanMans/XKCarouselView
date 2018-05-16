//
//  NSTimer+xk.m
//  XKCarouselView
//
//  Created by Allen、 LAS on 2018/5/16.
//  Copyright © 2018年 重楼. All rights reserved.
//

#import "NSTimer+xk.h"

@implementation NSTimer (xk)

+ (NSTimer *)xk_timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *))block{
    
    if ([self respondsToSelector:@selector(timerWithTimeInterval:repeats:block:)]) {
        return [self timerWithTimeInterval:interval repeats:repeats block:block];
    }
    return [self timerWithTimeInterval:interval target:self selector:@selector(xk_TimerAction:) userInfo:block repeats:repeats];
}

+ (void)xk_TimerAction:(NSTimer *)timer {
    void (^block)(NSTimer *timer) = timer.userInfo;
    if (block) block(timer);
}
@end
