//
//  ViewController.m
//  XKCarouselView
//
//  Created by Allen、 LAS on 2018/5/16.
//  Copyright © 2018年 重楼. All rights reserved.
//

#import "ViewController.h"
#import "XKCarouselView.h"
#import <Photos/Photos.h>
@interface ViewController ()
@property (nonatomic, strong) XKCarouselView *carouselView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"轮播图";
    
    _carouselView = [[XKCarouselView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 250)];
    _carouselView.imageArray = @[
                                 @"http://c.hiphotos.baidu.com/image/h%3D300/sign=50ca98bc00d79123ffe092749d355917/48540923dd54564e08122c8dbfde9c82d1584f0b.jpg",//网络图片
                                 @"http://g.hiphotos.baidu.com/zhidao/wh%3D450%2C600/sign=9d888a81f503918fd78435ce640d0aa1/9f510fb30f2442a7279c20c4d343ad4bd01302c5.jpg",//网络gif图片
                                 @"http://imgsrc.baidu.com/forum/w=580;/sign=7b7092e413dfa9ecfd2e561f52ebf503/500fd9f9d72a6059ac8e11e22a34349b023bbaa8.jpg?v=tbs",
                                 @"http://h.hiphotos.baidu.com/image/h%3D300/sign=bdb445b200d79123ffe092749d355917/48540923dd54564ee56cf183bfde9c82d1584f7a.jpg"
                                 ];
    [self.view addSubview:_carouselView];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
