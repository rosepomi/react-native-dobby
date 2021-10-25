//
//  LoadingView.m
//  guangDian
//
//  Created by peng on 16/4/12.
//  Copyright © 2016年 yunwan. All rights reserved.
//

#import "LoadingView.h"

#define w_Ratio   [UIScreen mainScreen].bounds.size.width/320
#define h_Ratio   [UIScreen mainScreen].bounds.size.height/568
#define LoadingScreenWidth   [UIScreen mainScreen].bounds.size.width
#define LoadingScreenHeight  [UIScreen mainScreen].bounds.size.height
#define LoadingUIColorFromRGB(rgbValue)    [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define ActivityColor LoadingUIColorFromRGB(0x08a6f2)
@interface LoadingView()

@property (nonatomic, strong)UIView *coverView;
@property (nonatomic, strong)UIView *whihtView;
@property (nonatomic, strong)UIActivityIndicatorView *activi;
@property (nonatomic, strong)UIButton *closeBtn;

@end

@implementation LoadingView


-(instancetype)init
{
    self=[super init];
    if (self) {
        [self initView];
    }
    return self;
}

-(void)initView{
    self.frame = [self screenBounds];
    _whihtView=[[UIView alloc]initWithFrame:CGRectMake((LoadingScreenWidth-150*w_Ratio)*0.5, (LoadingScreenHeight-90*h_Ratio)*0.5, 150*w_Ratio,90*h_Ratio)];
    _whihtView.backgroundColor=[UIColor whiteColor];
    _whihtView.layer.masksToBounds = YES;
    _whihtView.layer.cornerRadius =10;
    [self addSubview:_whihtView];
    
    _activi=[[UIActivityIndicatorView alloc]initWithFrame:CGRectMake((_whihtView.frame.size.width-45)*0.5, (_whihtView.frame.size.height-45)*0.5, 45, 45)];
//    _activi.center=_whihtView.center;
    [_activi setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [_activi setColor:ActivityColor];

    [_whihtView addSubview:_activi];
    
    
    _coverView = [[UIView alloc]initWithFrame:[self topView].bounds];
    _coverView.backgroundColor = [UIColor blackColor];
    _coverView.alpha = 0;
    _coverView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
//    [[self topView] addSubview:_coverView];
    
    
    _closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeBtn setBackgroundImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(closeBtnDidClicked) forControlEvents:UIControlEventTouchUpInside];
    _closeBtn.frame = CGRectMake(_whihtView.frame.size.width - 32,0, 32, 32);
    [_whihtView addSubview:_closeBtn];
    
}

-(void)closeBtnDidClicked{
    [self dismiss];
}

-(void)setDescribleStr:(NSString *)desStr{
//    _desLabel.text = desStr;
}
- (CGRect)screenBounds
{
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    // On iOS7, screen width and height doesn't automatically follow orientation
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            CGFloat tmp = screenWidth;
            screenWidth = screenHeight;
            screenHeight = tmp;
        }
    }
    
    return CGRectMake(0, 0, screenWidth, screenHeight);
}
#pragma mark - show and dismiss
-(UIView*)topView{
//        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];

    return  window;
}
- (void)show {
    [self performSelectorOnMainThread:@selector(showInMainThread) withObject:nil waitUntilDone:NO];
}

- (void)showInView:(UIView*)view {
    [_activi startAnimating];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        weakSelf.coverView.alpha = 0.5;
        
    } completion:^(BOOL finished) {
        
    }];
    
    [view addSubview:self];
    [self showAnimation];
}

- (void)showInMainThread{
    
    [_activi startAnimating];
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5 animations:^{
        weakSelf.coverView.alpha = 0.5;
        
    } completion:^(BOOL finished) {
        
    }];
    
    [[self topView] addSubview:self];
    [self showAnimation];
}

-(void)showWithView:(UIView *)showView{
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.activi startAnimating];
        [UIView animateWithDuration:0.5 animations:^{
            weakSelf.coverView.alpha = 0.5;
            
        } completion:^(BOOL finished) {
            
        }];
//        [showView addSubview:weakSelf.coverView];
        [showView addSubview:self];
        [self showAnimation];
    });
}


- (void)showAnimation {
    CAKeyframeAnimation *popAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    popAnimation.duration = 0.4;
    popAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.01f, 0.01f, 1.0f)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1f, 1.1f, 1.0f)],
                            [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.9f, 0.9f, 1.0f)],
                            [NSValue valueWithCATransform3D:CATransform3DIdentity]];
    popAnimation.keyTimes = @[@0.2f, @0.5f, @0.75f, @1.0f];
    popAnimation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                     [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                     [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [_whihtView.layer addAnimation:popAnimation forKey:nil];
}

- (void)dismiss {
    
    
    [self performSelectorOnMainThread:@selector(hideAnimation) withObject:nil waitUntilDone:NO];
    
}
- (void)hideAnimation{
    __weak typeof(self) weakSelf = self;

    [UIView animateWithDuration:0.4 animations:^{
        weakSelf.coverView.alpha = 0.0;
        
        weakSelf.whihtView.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

-(void)dealloc
{
    [_activi stopAnimating];
}












/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
