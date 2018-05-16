//
//  XKCarouselView.h
//  XKCarouselView
//
//  Created by Allen、 LAS on 2018/5/16.
//  Copyright © 2018年 重楼. All rights reserved.
//

#import <UIKit/UIKit.h>

//gif播放方式
typedef NS_ENUM(NSInteger, XKCarouselGifPlayMode) {
    XKCarouselGifPlayMode_Always,   //始终播放
    XKCarouselGifPlayMode_Never,           //从不播放
    XKCarouselGifPlayMode_PauseWhenScroll  //切换图片时暂停
};

@protocol XKCarouselViewDelegate;

//无限轮播视图
@interface XKCarouselView : UIView

/**
 *  是否开启图片缓存，默认为YES
 */
@property (nonatomic,assign) BOOL autoCache;

/**
 *  占位图片，在设置图片数组之前设置
 *  不设置则为默认占位图
 */
@property (nonatomic,strong) UIImage *placeholderImage;

/**
 *  设置图片的内容模式，默认为UIViewContentModeScaleToFill
 */
@property (nonatomic,assign) UIViewContentMode contentMode;

/**
 *  轮播的图片数组，可以是本地图片（UIImage，不能是图片名称），也可以是网络路径
 *  支持网络gif图片，本地gif需做处理后传入
 */
@property (nonatomic,strong) NSArray *imageArray;

/**
 *  每一页停留时间，默认为5s，最少1s
 *  当设置的值小于1s时，则为默认值
 */
@property (nonatomic,assign)NSTimeInterval time;

/**
 *  gif的播放方式，默认为XKCarouselGifPlayMode_Always
 */
@property (nonatomic,assign)XKCarouselGifPlayMode gifPlayMode;

/**
 *  点击图片响应事件
 */
@property (nonatomic,copy)void (^imageClickBlock)(NSInteger index);

/**
 *  代理对象
 */
@property (nonatomic,weak)id<XKCarouselViewDelegate>delegate;

#pragma mark 方法

/**
 *  开启定时器
 *  默认已开启，调用该方法会重新开启
 */
- (void)startTimer;


/**
 *  停止定时器
 *  停止后，如果手动滚动图片，定时器会重新开启
 */
- (void)stopTimer;

/**
 *  设置分页控件指示器的图片
 *  两个图片必须同时设置，否则设置无效
 *  不设置则为系统默认
 *
 *  @param image    其他页码的图片
 *  @param currentImage 当前页码的图片
 */
- (void)setPageImage:(UIImage *)image andCurrentPageImage:(UIImage *)currentImage;

/**
 *  设置分页控件指示器的颜色
 *  不设置则为系统默认
 *
 *  @param color        其他页码的颜色
 *  @param currentColor 当前页码的颜色
 */
- (void)setPageColor:(UIColor *)color andCurrentPageColor:(UIColor *)currentColor;

/**
 *  清除沙盒中的图片缓存
 */
+ (void)clearDiskCache;
@end

//点击协议
@protocol XKCarouselViewDelegate <NSObject>

@optional

/**
 *  该方法用来处理图片的点击，会返回图片在数组中的索引
 *  代理与block二选一即可，若两者都实现，block的优先级高
 *
 *  @param carouselView 控件本身
 *  @param index        图片索引
 */
- (void)xk_CarouselView:(XKCarouselView *)carouselView clickImageAtIndex:(NSInteger)index;
@end


