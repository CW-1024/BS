#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"

static AWEAwemePlayVideoViewController *currentVideoController = nil;
static UIButton *speedButton = nil;


void showToast(NSString *text) {
    [%c(DUXToast) showText:text];
}

// 获取倍速配置
NSArray* getSpeedOptions() {
    NSString *speedConfig = [[NSUserDefaults standardUserDefaults] stringForKey:@"SpeedSwitch"] ?: @"1.0,1.25,1.5,2.0";
    return [speedConfig componentsSeparatedByString:@","];
}

// 获取当前倍速索引
NSInteger getCurrentSpeedIndex() {
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentSpeedIndex"];
    NSArray *speeds = getSpeedOptions();
    
    // 确保索引合法
    if (index >= speeds.count || index < 0) {
        index = 0;
        [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"CurrentSpeedIndex"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // 显示当前索引
    showToast([NSString stringWithFormat:@"获取当前倍速索引: %ld", (long)index]);
    
    return index;
}

// 获取当前倍速值
float getCurrentSpeed() {
    NSArray *speeds = getSpeedOptions();
    NSInteger index = getCurrentSpeedIndex();
    
    if (speeds.count == 0) return 1.0;
    float speed = [speeds[index] floatValue];
    return speed > 0 ? speed : 1.0;
}

// 设置倍速索引并保存
void setCurrentSpeedIndex(NSInteger index) {
    NSArray *speeds = getSpeedOptions();
    
    // 确保索引合法
    if (speeds.count == 0) return;
    index = index % speeds.count;
    
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"CurrentSpeedIndex"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 显示设置的索引
    showToast([NSString stringWithFormat:@"设置新倍速索引: %ld", (long)index]);
}

// 更新倍速按钮UI
void updateSpeedButtonUI() {
    if (!speedButton) return;
    
    float currentSpeed = getCurrentSpeed();
    NSInteger currentIndex = getCurrentSpeedIndex(); // 获取当前索引用于显示
    NSString *speedFormat = (fmodf(currentSpeed * 100, 10) > 0) ? @"%.2fx" : @"%.1fx";
    [speedButton setTitle:[NSString stringWithFormat:speedFormat, currentSpeed] forState:UIControlStateNormal];
    
    // 显示当前按钮更新信息
    showToast([NSString stringWithFormat:@"按钮UI更新 - 索引: %ld, 速度: %@", 
               (long)currentIndex, 
               [NSString stringWithFormat:speedFormat, currentSpeed]]);
}

@interface AWEAwemePlayVideoViewController (SpeedControl)
- (void)adjustPlaybackSpeed:(float)speed;
@end

%hook AWEAwemePlayVideoViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
    // 获取当前保存的倍速设置
    float speed = getCurrentSpeed();
    NSInteger speedIndex = getCurrentSpeedIndex();
    
    // 应用倍速设置
    [self setVideoControllerPlaybackRate:speed];
    %orig(arg0);
    currentVideoController = self;
    
    // 显示视频控制器设置信息
    showToast([NSString stringWithFormat:@"视频控制器设置 - 索引: %ld, 速度: %.2f", 
               (long)speedIndex, speed]);
    
    // 更新按钮UI
    updateSpeedButtonUI();
}

%new
- (void)adjustPlaybackSpeed:(float)speed {
    [self setVideoControllerPlaybackRate:speed];
}

%end

// 在使用AWEPlayInteractionViewController之前添加类扩展
@interface AWEPlayInteractionViewController : UIViewController
@property(nonatomic, readonly) UIViewController *parentViewController;
@property(nonatomic, strong) UIView *view;
- (UIViewController *)firstAvailableUIViewController;
- (void)speedButtonTapped:(id)sender;
- (void)buttonTouchDown:(id)sender;
- (void)buttonTouchUp:(id)sender;
@end

@interface UIView (SpeedHelper)
- (UIViewController *)firstAvailableUIViewController;
@end

%hook AWEPlayInteractionViewController

- (void)viewDidLayoutSubviews {
    %orig;
    
    if (![self.parentViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
        return;
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYisEnableFullScreen"]) {
        CGRect frame = self.view.frame;
        frame.size.height = self.view.superview.frame.size.height - 83;
        self.view.frame = frame;
    }
    
    // 添加速度控制按钮
    UIView *containerView = self.view;
    
    BOOL buttonExists = NO;
    
    for (UIView *subview in containerView.subviews) {
        if ([subview isKindOfClass:[UIButton class]] && [subview.accessibilityLabel isEqualToString:@"speedSwitchButton"]) {
            buttonExists = YES;
            speedButton = (UIButton *)subview;
            break;
        }
    }
    
    // 获取右侧控件栈视图
    UIView *rightStackView = nil;
    for (UIView *subview in containerView.subviews) {
        if ([subview isKindOfClass:%c(AWEElementStackView)] && 
            [subview.accessibilityLabel isEqualToString:@"right"]) {
            rightStackView = subview;
            break;
        }
    }
    
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
        
        [speedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        speedButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        
        speedButton.layer.shadowColor = [UIColor blackColor].CGColor;
        speedButton.layer.shadowOffset = CGSizeMake(0, 2);
        speedButton.layer.shadowOpacity = 0.5;
    
        [containerView addSubview:speedButton];
        speedButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        // 位置在右侧控件栈的上方
        if (rightStackView) {
            [NSLayoutConstraint activateConstraints:@[
                [speedButton.bottomAnchor constraintEqualToAnchor:rightStackView.topAnchor constant:0], 
                [speedButton.trailingAnchor constraintEqualToAnchor:rightStackView.trailingAnchor constant:-7], 
                [speedButton.widthAnchor constraintEqualToConstant:buttonSize],
                [speedButton.heightAnchor constraintEqualToConstant:buttonSize]
            ]];
        } else {
            // 如果没找到右侧控件栈，则默认放在右下角
            [NSLayoutConstraint activateConstraints:@[
                [speedButton.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor constant:-100], 
                [speedButton.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor constant:-20], 
                [speedButton.widthAnchor constraintEqualToConstant:buttonSize],
                [speedButton.heightAnchor constraintEqualToConstant:buttonSize]
            ]];
        }
        
        // 获取当前速度并应用到视频上
        float currentSpeed = getCurrentSpeed();
        NSInteger currentIndex = getCurrentSpeedIndex();
        
        // 显示按钮创建信息
        showToast([NSString stringWithFormat:@"倍速按钮已创建 - 索引: %ld, 速度: %.2f倍", 
                   (long)currentIndex, currentSpeed]);
        
        // 查找当前视频控制器并调整速度
        if (currentVideoController) {
            [currentVideoController adjustPlaybackSpeed:currentSpeed];
        } else {
            UIViewController *vc = [self firstAvailableUIViewController];
            while (vc && ![vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
                vc = vc.parentViewController;
            }
            
            if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
                AWEAwemePlayVideoViewController *videoVC = (AWEAwemePlayVideoViewController *)vc;
                [videoVC adjustPlaybackSpeed:currentSpeed];
                currentVideoController = videoVC;
            }
        }
        
        // 更新按钮UI显示
        updateSpeedButtonUI();
        
        // 添加按钮事件
        [speedButton addTarget:self action:@selector(speedButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [speedButton addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [speedButton addTarget:self action:@selector(buttonTouchUp:) forControlEvents:UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    }
}

%new
- (UIViewController *)firstAvailableUIViewController {
    UIResponder *responder = [self.view nextResponder];
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
    // 切换到下一个倍速
    NSArray *speeds = getSpeedOptions();
    if (speeds.count == 0) return;
    
    // 获取并递增倍速索引
    NSInteger currentIndex = getCurrentSpeedIndex();
    showToast([NSString stringWithFormat:@"当前索引: %ld", (long)currentIndex]);
    
    NSInteger newIndex = (currentIndex + 1) % speeds.count;
    
    // 保存新的倍速索引
    setCurrentSpeedIndex(newIndex);
    
    // 获取新倍速值
    float newSpeed = [speeds[newIndex] floatValue];
    
    // 更新UI
    NSString *speedFormat = (fmodf(newSpeed * 100, 10) > 0) ? @"%.2fx" : @"%.1fx";
    [sender setTitle:[NSString stringWithFormat:speedFormat, newSpeed] forState:UIControlStateNormal];
    
    // 提示用户
    showToast([NSString stringWithFormat:@"已切换倍速 - 新索引: %ld, 速度: %@x", 
               (long)newIndex, speeds[newIndex]]);
    
    // 按钮动画
    [UIView animateWithDuration:0.15 animations:^{
        sender.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];
    
    // 应用倍速到视频
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
    
    // 初始化设置
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"SpeedSwitch"]) {
        [defaults setObject:@"1.0,1.25,1.5,2.0" forKey:@"SpeedSwitch"];
    }
    if (![defaults objectForKey:@"CurrentSpeedIndex"]) {
        [defaults setInteger:0 forKey:@"CurrentSpeedIndex"];
    }
    [defaults synchronize];
    
    // 显示初始化信息
    NSInteger initialIndex = getCurrentSpeedIndex();
    showToast([NSString stringWithFormat:@"插件初始化 - 当前索引: %ld", (long)initialIndex]);
}