//
//  UIImage+GIF.h
//  XKCarouselView
//
//  Created by Allen、 LAS on 2018/5/16.
//  Copyright © 2018年 重楼. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (GIF)

//图片解析：gif数据
+ (UIImage*)xk_GifWithImageData:(NSData*)data;

//根据图片名获取gif
+ (UIImage*)xk_GifWithImageName:(NSString*)imageName;


@end
