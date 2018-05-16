//
//  NSTimer+xk.h
//  XKCarouselView
//
//  Created by Allen、 LAS on 2018/5/16.
//  Copyright © 2018年 重楼. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSTimer (xk)

//定时器重复执行
+ (NSTimer *)xk_timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *))block;

@end
