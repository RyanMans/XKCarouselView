//
//  UIImage+GIF.m
//  XKCarouselView
//
//  Created by Allen、 LAS on 2018/5/16.
//  Copyright © 2018年 重楼. All rights reserved.
//

#import "UIImage+GIF.h"

@implementation UIImage (GIF)

+ (UIImage*)xk_GifWithImageData:(NSData*)data{
    CGImageSourceRef imageRef= CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    size_t count = CGImageSourceGetCount(imageRef);
    
    if (count <= 1) {  //非gif
        CFRelease(imageRef);
        return [[UIImage alloc] initWithData:data];
    }
    
    NSMutableArray * imageArrs = [NSMutableArray array];
    NSTimeInterval duration = 0;
    
    for (size_t index = 0; index < count; index ++) {
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageRef, index, NULL);
        if (!image) continue;
        duration += [UIImage xk_DurationWithImageSource:imageRef index:index];
        [imageArrs addObject:[UIImage imageWithCGImage:image]];
        CGImageRelease(image);
    }
    
    if (!duration) duration = 0.1 * count;
    CFRelease(imageRef);
    return [UIImage animatedImageWithImages:imageArrs duration:duration];
}

+ (float)xk_DurationWithImageSource:(CGImageSourceRef)source index:(NSInteger)index{
    float duration = 0.1f;
    CFDictionaryRef propertiesRef = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary * properties = (__bridge NSDictionary *)propertiesRef;
    NSDictionary * gifProperties = properties[(NSString *)kCGImagePropertyGIFDictionary];

    NSNumber *delayTime = gifProperties[(NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (delayTime) duration = delayTime.floatValue;
    else {
        delayTime = gifProperties[(NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime) duration = delayTime.floatValue;
    }
    CFRelease(propertiesRef);
    return duration;
}

+ (UIImage*)xk_GifWithImageName:(NSString *)imageName{
    if (![imageName hasSuffix:@".gif"]) imageName = [imageName stringByAppendingString:@".gif"];
    NSString * imagePath = [[NSBundle mainBundle] pathForResource:imageName ofType:nil];
    NSData * data = [NSData dataWithContentsOfFile:imagePath];
    if (data) return [UIImage xk_GifWithImageData:data];
    return [UIImage imageNamed:imageName];
}
@end
