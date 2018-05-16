//
//  XKCarouselView.m
//  XKCarouselView
//
//  Created by Allen、 LAS on 2018/5/16.
//  Copyright © 2018年 重楼. All rights reserved.
//

#import "XKCarouselView.h"
#import "UIImage+GIF.h"
#import "NSTimer+xk.h"

#define WeakSelf(x)  __weak typeof(self) x = self;
#define XK_TIME  5

@interface XKCarouselView ()<UIScrollViewDelegate>

//轮播的图片数组
@property (nonatomic, strong) NSMutableArray *imagesDataSource;

//分页控件
@property (nonatomic, strong) UIPageControl *pageControl;
//滚动视图
@property (nonatomic,strong)UIScrollView * displayScrollView;
//当前显示的imageView
@property (nonatomic, strong) UIImageView *currImageView;
//滚动显示的imageView
@property (nonatomic, strong) UIImageView *otherImageView;
//当前显示图片的索引
@property (nonatomic, assign) NSInteger currIndex;
//将要显示图片的索引
@property (nonatomic, assign) NSInteger nextIndex;
//定时器
@property (nonatomic, strong) NSTimer *timer;
@end

static NSString * imageCache;

@implementation XKCarouselView

//创建本地缓存文件夹
+ (void)initialize {
    imageCache = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"XKCarousel"];
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:imageCache isDirectory:&isDir];
    if (!isExists || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:imageCache withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoCache = YES;
        [self addSubview:self.displayScrollView];
        [self addSubview:self.pageControl];
    }
    return self;
}

//布局子控件
- (void)layoutSubviews{
    [super layoutSubviews];
    
    //有导航控制器时，会默认在scrollview上方添加64的内边距，这里强制设置为0
    _displayScrollView.contentInset = UIEdgeInsetsZero;
    _displayScrollView.frame = self.bounds;
    _pageControl.frame = CGRectMake(0, self.height - 20, self.width, 20);
    [self setScrollViewContentSize];
}

#pragma mark- frame相关
- (CGFloat)height {
    return self.displayScrollView.frame.size.height;
}

- (CGFloat)width {
    return self.displayScrollView.frame.size.width;
}

#pragma mark 设置图片的内容模式
- (void)setContentMode:(UIViewContentMode)contentMode {
    _contentMode = contentMode;
    _currImageView.contentMode = contentMode;
    _otherImageView.contentMode = contentMode;
}

//MARK: 设置图片数组
- (void)setImageArray:(NSArray *)imageArray{

    if (!imageArray.count) return;
    
    _imageArray = imageArray;
    _imagesDataSource = [NSMutableArray array];
    
    for (int index = 0 ; index < _imageArray.count; index++) {
        if ([_imageArray[index] isKindOfClass:[UIImage class]]){ //本地图片
            [_imagesDataSource addObject:_imageArray[index] ];
        }
        else if ([_imageArray[index] isKindOfClass:[NSString class]]){
            //如果是网络图片，则先添加占位图片，下载完成后替换
            if (_placeholderImage) [_imagesDataSource addObject:_placeholderImage];
            else [_imagesDataSource addObject:[UIImage imageNamed:@"XKPlaceholder"]];
            [self xk_DownloadImageAtIndex:index];
        }
    }
    
    //防止在滚动过程中重新给imageArray赋值时报错
    if (_currIndex >= _imagesDataSource.count) _currIndex = _imagesDataSource.count - 1;
    self.currImageView.image = self.imagesDataSource[_currIndex];
    self.pageControl.numberOfPages = _imagesDataSource.count;
    [self layoutSubviews];
}

//设置滚动视图的内容size
- (void)setScrollViewContentSize{
    if (_imagesDataSource.count > 1) {
        self.displayScrollView.contentSize = CGSizeMake(self.width * 5, 0);
        self.displayScrollView.contentOffset = CGPointMake(self.width * 2, 0);
        self.currImageView.frame = CGRectMake(self.width * 2, 0, self.width, self.height);
        [self startTimer];
    }
    else{
        //只要一张图片时，scrollview不可滚动，且关闭定时器
        self.displayScrollView.contentSize = CGSizeZero;
        self.displayScrollView.contentOffset = CGPointZero;
        self.currImageView.frame = CGRectMake(0, 0, self.width, self.height);
        [self stopTimer];
    }
}

//MARK: 下载图片
- (void)xk_DownloadImageAtIndex:(NSInteger)index{
    NSString * urlString = _imageArray[index];
    NSString * imageName = [urlString stringByReplacingOccurrencesOfString:@"/" withString:@""];
    NSString * path = [imageCache stringByAppendingPathComponent:imageName];
    if (_autoCache) {
        NSData * data = [NSData dataWithContentsOfFile:path];
        if (data) { //确定是否是gif图片
            _imagesDataSource[index] = [UIImage xk_GifWithImageData:data];
            return;
        }
    }
    
    WeakSelf(ws);
    //异步下载图片
    xk_RunBlockWithAsync(^{
        NSData * imageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        if (!imageData) return;
        UIImage * image =  [UIImage xk_GifWithImageData:imageData];
        //回归主线程
        xk_RunBlockWithMain(^{
            if (image) {
                ws.imagesDataSource[index] = image;
                //如果下载的图片为当前要显示的图片，直接到主线程给imageView赋值，否则要等到下一轮才会显示
                if (ws.currIndex == index) ws.currImageView.image = image;
                if (ws.autoCache) [imageData writeToFile:path atomically:YES];
            }
        });
    });
}

//主线程
void xk_RunBlockWithMain(dispatch_block_t block){
    dispatch_async(dispatch_get_main_queue(), block);
}

//异步线程
void xk_RunBlockWithAsync(dispatch_block_t block){
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

#pragma mark 设置定时器时间
- (void)setTime:(NSTimeInterval)time {
    _time = time;
    [self startTimer];
}

- (void)startTimer {
    //如果只有一张图片，则直接返回，不开启定时器
    if (_imagesDataSource.count <= 1) return;
    //如果定时器已开启，先停止再重新开启
    if (self.timer) [self stopTimer];
    WeakSelf(ws);
    self.timer = [NSTimer xk_timerWithTimeInterval:_time < 1? XK_TIME: _time repeats:YES block:^(NSTimer * _Nonnull timer) {
        //滚动发
        [ws.displayScrollView setContentOffset:CGPointMake(ws.width * 3, 0) animated:YES];
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

//设置gif图片的播放模式
- (void)setGifPlayMode:(XKCarouselGifPlayMode)gifPlayMode{
    _gifPlayMode = gifPlayMode;
    if (_gifPlayMode == XKCarouselGifPlayMode_Always) [self xk_ImageViewGif:YES];
    else if (_gifPlayMode == XKCarouselGifPlayMode_Never) [self xk_ImageViewGif:NO];
}

- (void)xk_ImageViewGif:(BOOL)animated{
    [self setGifImageView:self.currImageView animated:animated];
    [self setGifImageView:self.otherImageView animated:animated];
}

- (void)setGifImageView:(UIImageView*)imageView animated:(BOOL)animated{
    if (animated) {
        CFTimeInterval pausedTime = [imageView.layer timeOffset];
        imageView.layer.speed = 1.0;
        imageView.layer.timeOffset = 0.0;
        imageView.layer.beginTime = 0.0;
        CFTimeInterval timeSincePause = [imageView.layer convertTime:CACurrentMediaTime() fromLayer:nil] -    pausedTime;
        imageView.layer.beginTime = timeSincePause;
    } else {
        CFTimeInterval pausedTime = [imageView.layer convertTime:CACurrentMediaTime() fromLayer:nil];
        imageView.layer.speed = 0.0;
        imageView.layer.timeOffset = pausedTime;
    }
}

#pragma mark 设置pageControl的指示器图片
- (void)setPageImage:(UIImage *)image andCurrentPageImage:(UIImage *)currentImage {
    if (!image || !currentImage) return;
    [self.pageControl setValue:currentImage forKey:@"_currentPageImage"];
    [self.pageControl setValue:image forKey:@"_pageImage"];
}

#pragma mark 设置pageControl的指示器颜色
- (void)setPageColor:(UIColor *)color andCurrentPageColor:(UIColor *)currentColor {
    _pageControl.pageIndicatorTintColor = color;
    _pageControl.currentPageIndicatorTintColor = currentColor;
}

#pragma mark 清除沙盒中的图片缓存
+ (void)clearDiskCache {
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:imageCache error:NULL];
    for (NSString *fileName in contents) {
        [[NSFileManager defaultManager] removeItemAtPath:[imageCache stringByAppendingPathComponent:fileName] error:nil];
    }
}

- (void)xk_PageControlCurrentPage:(CGFloat)offsetX{
    if (offsetX < self.width * 1.5) {
        NSInteger index = self.currIndex - 1;
        if (index < 0) index = self.imagesDataSource.count - 1;
        _pageControl.currentPage = index;
    } else if (offsetX > self.width * 2.5){
        _pageControl.currentPage = (self.currIndex + 1) % self.imagesDataSource.count;
    } else {
        _pageControl.currentPage = self.currIndex;
    }
}

#pragma mark  UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (CGSizeEqualToSize(CGSizeZero, scrollView.contentSize)) return;
    CGFloat offsetX = scrollView.contentOffset.x;
    
    //切换时暂停模式
    if (_gifPlayMode == XKCarouselGifPlayMode_PauseWhenScroll) [self xk_ImageViewGif:(offsetX == self.width * 2)];

    //滚动过程中改变pageControl的当前页码
    [self xk_PageControlCurrentPage:offsetX];
    
    //向右滚动
    if (offsetX < self.width * 2) {
        self.otherImageView.frame = CGRectMake(self.width, 0, self.width, self.height);
        self.nextIndex = self.currIndex - 1;
        if (self.nextIndex < 0) self.nextIndex = _imagesDataSource.count - 1;
        self.otherImageView.image = self.imagesDataSource[self.nextIndex];
        if (offsetX <= self.width) [self toNext];
        
        //向左滚动
    } else if (offsetX > self.width * 2){
       self.otherImageView.frame = CGRectMake(CGRectGetMaxX(_currImageView.frame), 0, self.width, self.height);
        self.nextIndex = (self.currIndex + 1) % _imagesDataSource.count;
        self.otherImageView.image = self.imagesDataSource[self.nextIndex];
        if (offsetX >= self.width * 3) [self toNext];
    }
}

- (void)toNext{
    //切换到下一张图片
    self.currImageView.image = self.otherImageView.image;
    self.displayScrollView.contentOffset = CGPointMake(self.width * 2, 0);
    [self.displayScrollView layoutSubviews];
    self.currIndex = self.nextIndex;
    self.pageControl.currentPage = self.currIndex;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self startTimer];
}

//该方法用来修复滚动过快导致分页异常的bug
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGPoint currPointInSelf = [_displayScrollView convertPoint:_currImageView.frame.origin toView:self];
    if (currPointInSelf.x >= -self.width / 2 && currPointInSelf.x <= self.width / 2)
        [self.displayScrollView setContentOffset:CGPointMake(self.width * 2, 0) animated:YES];
    else [self toNext];
}


#pragma mark - 懒加载
- (UIScrollView*)displayScrollView{
    if (!_displayScrollView) {
        _displayScrollView = [UIScrollView new];
        _displayScrollView.bounces = NO;
        _displayScrollView.delegate = self;
        _displayScrollView.scrollsToTop = NO;
        _displayScrollView.pagingEnabled = YES;
        _displayScrollView.showsHorizontalScrollIndicator = NO;
        _displayScrollView.showsVerticalScrollIndicator = NO;
        
        //添加手势监听图片的点击
        [_displayScrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickImageViewEvent:)]];
        _currImageView = [[UIImageView alloc] init];
        _currImageView.clipsToBounds = YES;
        [_displayScrollView addSubview:_currImageView];
        _otherImageView = [[UIImageView alloc] init];
        _otherImageView.clipsToBounds = YES;
        [_displayScrollView addSubview:_otherImageView];
    }
    return _displayScrollView;
}

//点击图片响应事件
- (void)onClickImageViewEvent:(UITapGestureRecognizer*)sender{
    if (self.imageClickBlock)self.imageClickBlock(self.currIndex);
    else if ([self.delegate respondsToSelector:@selector(xk_CarouselView:clickImageAtIndex:)]){
        [self.delegate xk_CarouselView:self clickImageAtIndex:self.currIndex];
    }
}

- (UIPageControl *)pageControl{
    if (!_pageControl) {
        _pageControl = [UIPageControl new];
        _pageControl.userInteractionEnabled = NO;
    }
    return _pageControl;
}

- (void)dealloc{
    _displayScrollView = nil;
    _pageControl = nil;
}
@end
