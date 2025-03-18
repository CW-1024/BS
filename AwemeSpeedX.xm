#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"

// 播放速度配置
static NSArray *speedOptions = nil;
static NSInteger currentSpeedIndex = 0;
static float currentSpeed = 1.0;
static AWEAwemePlayVideoViewController *currentVideoController = nil;

// 初始化播放速度选项
void initializeSpeedOptions() {
    if (!speedOptions) {
        speedOptions = @[@"1.0", @"1.5", @"2.0"];
        currentSpeedIndex = 0;
        currentSpeed = 1.0;
    }
}

@interface AWEAwemePlayVideoViewController (SpeedControl)
- (void)adjustPlaybackSpeed:(float)speed;
@end

%hook AWEAwemePlayVideoViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
    if (currentSpeed > 0 && currentSpeed != 1) {
        [self setVideoControllerPlaybackRate:currentSpeed];
    }
    %orig(arg0);
    currentVideoController = self;
}

%new
- (void)adjustPlaybackSpeed:(float)speed {
    currentSpeed = speed; 
    [self setVideoControllerPlaybackRate:speed];
}

%end

@interface UIView (SpeedHelper)
- (UIViewController *)firstAvailableUIViewController;
- (void)speedButtonTapped:(id)sender;
- (float)getCurrentSpeed;
@end

%hook AWEElementStackView

- (void)layoutSubviews {
    
    // 只处理右侧控件栈
    if (self.accessibilityLabel && [self.accessibilityLabel isEqualToString:@"right"]) {
        // 寻找视频控制器容器视图
        UIView *containerView = self.superview;
        if (!containerView) return;
        
        // 检查是否已经添加了按钮
        static UIButton *speedButton = nil;
        BOOL buttonExists = NO;
        
        for (UIView *subview in containerView.subviews) {
            if ([subview isKindOfClass:[UIButton class]] && [subview.accessibilityLabel isEqualToString:@"speedSwitchButton"]) {
                buttonExists = YES;
                speedButton = (UIButton *)subview;
                break;
            }
        }
        
        // 获取当前速度值
        float currentSpeed = [self getCurrentSpeed];
        
        if (!buttonExists) {
            // 创建圆形倍速按钮
            CGFloat buttonSize = 44;
            speedButton = [UIButton buttonWithType:UIButtonTypeSystem];
            speedButton.accessibilityLabel = @"speedSwitchButton";
            
            speedButton.frame = CGRectMake(0, 0, buttonSize, buttonSize);
            speedButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
            speedButton.layer.cornerRadius = buttonSize / 2;
            speedButton.layer.masksToBounds = YES;
            speedButton.layer.borderWidth = 1.5;
            speedButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.5].CGColor;
            
            initializeSpeedOptions();
           
            [speedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            speedButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
            
            speedButton.layer.shadowColor = [UIColor blackColor].CGColor;
            speedButton.layer.shadowOffset = CGSizeMake(0, 2);
            speedButton.layer.shadowOpacity = 0.5;
        
            [containerView addSubview:speedButton];
            speedButton.translatesAutoresizingMaskIntoConstraints = NO;
            
            // 位置在右侧控件栈的上方
            [NSLayoutConstraint activateConstraints:@[
                [speedButton.bottomAnchor constraintEqualToAnchor:self.topAnchor constant:0], 
                [speedButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-6], 
                [speedButton.widthAnchor constraintEqualToConstant:buttonSize],
                [speedButton.heightAnchor constraintEqualToConstant:buttonSize]
            ]];
            
            // 添加按钮事件
            [speedButton addTarget:self action:@selector(speedButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [speedButton addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
            [speedButton addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchCancel | UIControlEventTouchUpOutside];
        }
        
        // 更新按钮显示的当前倍速
        [speedButton setTitle:[NSString stringWithFormat:@"%.1fx", currentSpeed] forState:UIControlStateNormal];
    }
    
    %orig;
}

%new
- (float)getCurrentSpeed {
    NSString *speedKey = @"CurrentSpeedIndex";
    NSInteger currentSpeedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:speedKey];
    
    // 获取速度配置
    NSString *speedConfig = [[NSUserDefaults standardUserDefaults] stringForKey:@"SpeedSwitch"] ?: @"1,1.5,2";
    NSArray *speeds = [speedConfig componentsSeparatedByString:@","];
    
    if (currentSpeedIndex >= speeds.count || currentSpeedIndex < 0) {
        currentSpeedIndex = 0;
        [[NSUserDefaults standardUserDefaults] setInteger:currentSpeedIndex forKey:speedKey];
    }
    
    // 返回当前速度
    float speed = speeds.count > 0 ? [speeds[currentSpeedIndex] floatValue] : 1.0;
    return speed > 0 ? speed : 1.0;
}

%new
- (UIViewController *)firstAvailableUIViewController {
    UIResponder *responder = [self nextResponder];
    while (responder != nil) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)responder;
        }
        responder = [responder nextResponder];
    }
    return nil;
}

%new
- (void)speedButtonTapped:(UIButton *)sender {
    // 获取速度配置
    NSString *speedConfig = [[NSUserDefaults standardUserDefaults] stringForKey:@"SpeedSwitch"] ?: @"1,1.5,2";
    NSArray *speeds = [speedConfig componentsSeparatedByString:@","];
    
    if (speeds.count == 0) return;
    
    // 获取当前速度索引
    NSString *speedKey = @"CurrentSpeedIndex";
    NSInteger currentSpeedIndex = [[NSUserDefaults standardUserDefaults] integerForKey:speedKey];
    currentSpeedIndex = (currentSpeedIndex + 1) % speedOptions.count;
    [[NSUserDefaults standardUserDefaults] setInteger:currentSpeedIndex forKey:speedKey];
    float newSpeed = [speeds[currentSpeedIndex] floatValue];
    [sender setTitle:[NSString stringWithFormat:@"%.1fx", newSpeed] forState:UIControlStateNormal];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [UIView animateWithDuration:0.15 animations:^{
        sender.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];
    
    // 更新默认速度
    currentSpeed = newSpeed;
    
    // 查找当前视频控制器并调整速度
    if (currentVideoController) {
        [currentVideoController adjustPlaybackSpeed:newSpeed];
    } else {
        UIViewController *vc = [self firstAvailableUIViewController];
        while (vc && ![vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            vc = vc.parentViewController;
        }
        
        if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            AWEAwemePlayVideoViewController *videoVC = (AWEAwemePlayVideoViewController *)vc;
            [videoVC adjustPlaybackSpeed:newSpeed];
            currentVideoController = videoVC;
        }
    }
}

%new
- (void)buttonTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.alpha = 0.7;
        sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
    }];
}

%new
- (void)buttonTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.alpha = 1.0;
        sender.transform = CGAffineTransformIdentity;
    }];
}

%end

%ctor {
    %init;
    initializeSpeedOptions();
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"SpeedSwitch"]) {
        [defaults setObject:@"1.0,1.5,2.0" forKey:@"SpeedSwitch"];
    }
    if (![defaults objectForKey:@"CurrentSpeedIndex"]) {
        [defaults setInteger:0 forKey:@"CurrentSpeedIndex"];
    }
}