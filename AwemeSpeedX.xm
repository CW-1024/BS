#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "AwemeHeaders.h"
#import "SpeedXSettingViewController.h" // 导入自定义设置视图控制器

@class AWEFeedCellViewController;
@class AWEAwemePlayVideoViewController; 
@class DUXToast;

void showToast(NSString *text);

// 完善AWEPlayInteractionViewController类定义，包括所有需要的属性和方法
@interface AWEPlayInteractionViewController : UIViewController
@property (nonatomic, strong, readonly) UIView *view; // 修改为readonly，因为它是从UIViewController继承的
- (void)setVideoControllerPlaybackRate:(float)rate; // 添加播放速率设置方法
@end

@interface AWEPlayInteractionViewController (SpeedControl) <SpeedXSettingViewControllerDelegate>
- (UIViewController *)firstAvailableUIViewController;
- (void)speedButtonTapped:(id)sender;
- (void)buttonTouchDown:(id)sender;
- (void)buttonTouchUp:(id)sender;
- (void)showSpeedSettingsDialog;
@end

// 声明悬浮按钮类
@interface FloatingSpeedButton : UIButton
@property (nonatomic, assign) CGPoint lastLocation;
@property (nonatomic, weak) AWEPlayInteractionViewController *interactionController;
@property (nonatomic, assign) BOOL isLocked; // 添加锁定状态属性
@property (nonatomic, strong) NSTimer *firstStageTimer; // 第一阶段计时器
@property (nonatomic, strong) NSTimer *secondStageTimer; // 第二阶段计时器
@property (nonatomic, assign) BOOL justToggledLock; // 添加锁定状态切换标记
@property (nonatomic, assign) BOOL originalLockState; // 保存原始锁定状态
- (void)saveButtonPosition;
- (void)loadSavedPosition;
- (void)resetButtonState; // 添加方法确保按钮状态可以被重置
@end

@implementation FloatingSpeedButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.accessibilityLabel = @"speedSwitchButton";
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.1];
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.3].CGColor;
        
        [self setTitleColor:[UIColor colorWithWhite:1.0 alpha:0.3] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowOpacity = 0.5;
        
        // 确保用户交互始终启用
        self.userInteractionEnabled = YES;
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:panGesture];
        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPressGesture.minimumPressDuration = 0.5;
        [self addGestureRecognizer:longPressGesture];
        
        // 简化为只有单击手势
        UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
        singleTapGesture.numberOfTapsRequired = 1;
        [self addGestureRecognizer:singleTapGesture];
        
        longPressGesture.delegate = (id<UIGestureRecognizerDelegate>)self;
        panGesture.delegate = (id<UIGestureRecognizerDelegate>)self;
        singleTapGesture.delegate = (id<UIGestureRecognizerDelegate>)self;
        
        // 加载保存的位置和锁定状态
        [self loadSavedPosition];
        
        // justToggledLock总是初始化为NO
        self.justToggledLock = NO;
    }
    return self;
}

// 改进手势识别器代理方法，优化手势处理
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // 长按和点击不应同时识别
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && 
        [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return NO; 
    }
    
    // 拖动和点击不应同时识别
    if (([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && 
         [otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) ||
        ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && 
         [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])) {
        return NO;
    }
    
    return YES;
}

// 确保点击手势的优先级高于其他手势
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && 
        ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] || 
         [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])) {
        return YES;
    }
    return NO;
}

- (void)handleSingleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        // 如果刚刚切换了锁定状态，不触发点击事件
        if (self.justToggledLock) {
            return;
        }
        
        // 提供视觉反馈
        [UIView animateWithDuration:0.1 animations:^{
            self.transform = CGAffineTransformMakeScale(1.2, 1.2);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.1 animations:^{
                self.transform = CGAffineTransformIdentity;
            }];
        }];
        
        // 确保控制器存在再调用方法
        if (self.interactionController) {
            [self.interactionController speedButtonTapped:self];
        }
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // 取消可能存在的先前定时器
        if (self.firstStageTimer && [self.firstStageTimer isValid]) {
            [self.firstStageTimer invalidate];
        }
        if (self.secondStageTimer && [self.secondStageTimer isValid]) {
            [self.secondStageTimer invalidate];
        }
        
        // 保存原始锁定状态
        self.originalLockState = self.isLocked;
        
        // 第一阶段定时器
        self.firstStageTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                               target:self 
                                                             selector:@selector(firstStageLongPress) 
                                                             userInfo:nil 
                                                              repeats:NO];
        [[NSRunLoop mainRunLoop] addTimer:self.firstStageTimer forMode:NSRunLoopCommonModes];
        
        // 不在这里设置第二阶段计时器，而是在第一阶段计时器的回调中设置
    } else if (gesture.state == UIGestureRecognizerStateEnded || 
               gesture.state == UIGestureRecognizerStateCancelled || 
               gesture.state == UIGestureRecognizerStateFailed) {
        // 长按手势结束或取消时废弃计时器
        if (self.firstStageTimer && [self.firstStageTimer isValid]) {
            [self.firstStageTimer invalidate];
            self.firstStageTimer = nil;
        }
        if (self.secondStageTimer && [self.secondStageTimer isValid]) {
            [self.secondStageTimer invalidate];
            self.secondStageTimer = nil;
        }
    }
}

- (void)firstStageLongPress {
    // 切换锁定状态
    self.isLocked = !self.isLocked;
    self.justToggledLock = YES;
    
    // 显示锁定/解锁提示
    NSString *toastMessage = self.isLocked ? @"按钮已锁定" : @"按钮已解锁";
    showToast(toastMessage);
    
    // 如果锁定了，保存当前位置
    if (self.isLocked) {
        [self saveButtonPosition];
    }
    
    // 触觉反馈
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
    
    NSTimer *resetTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                    target:self 
                                  selector:@selector(resetToggleLockFlag) 
                                  userInfo:nil 
                                   repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:resetTimer forMode:NSRunLoopCommonModes];
    
    self.secondStageTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                            target:self 
                                                          selector:@selector(secondStageLongPress) 
                                                          userInfo:nil 
                                                           repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.secondStageTimer forMode:NSRunLoopCommonModes];
}

- (void)secondStageLongPress {
    // 恢复原始锁定状态
    if (self.isLocked != self.originalLockState) {
        self.isLocked = self.originalLockState;
        NSString *toastMessage = self.isLocked ? @"保持锁定状态" : @"保持解锁状态";
        showToast(toastMessage);
    }
    
    // 显示设置弹窗
    if (self.interactionController) {
        [self.interactionController showSpeedSettingsDialog];
        
        // 触觉反馈
        if (@available(iOS 10.0, *)) {
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
            [generator prepare];
            [generator impactOccurred];
        }
    }
}

- (void)resetToggleLockFlag {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.justToggledLock = NO;
    });
}

// 添加方法确保按钮状态可以被重置
- (void)resetButtonState {
    self.justToggledLock = NO;
    self.userInteractionEnabled = YES;
    self.transform = CGAffineTransformIdentity;
    self.alpha = 1.0;
    
    // 如果有定时器正在运行，取消它们
    if (self.firstStageTimer && [self.firstStageTimer isValid]) {
        [self.firstStageTimer invalidate];
        self.firstStageTimer = nil;
    }
    if (self.secondStageTimer && [self.secondStageTimer isValid]) {
        [self.secondStageTimer invalidate];
        self.secondStageTimer = nil;
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    // 如果按钮被锁定，不执行拖动
    if (self.isLocked) return;
    
    // 拖动时确保 justToggledLock 为 NO，避免影响后续点击
    self.justToggledLock = NO;
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.lastLocation = self.center;
    }
    
    CGPoint translation = [pan translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.lastLocation.x + translation.x, 
                                    self.lastLocation.y + translation.y);
    
    // 确保按钮不会超出屏幕边界，并且不会移动到底部导航栏区域
    CGFloat halfWidth = self.frame.size.width / 2;
    CGFloat halfHeight = self.frame.size.height / 2;
    CGRect superBounds = self.superview.bounds;
    CGFloat bottomSafeArea = 20.0; // 设置底部安全区域
    
    newCenter.x = MAX(halfWidth, MIN(newCenter.x, superBounds.size.width - halfWidth));
    newCenter.y = MAX(halfHeight, MIN(newCenter.y, superBounds.size.height - halfHeight - bottomSafeArea));
    
    self.center = newCenter;
    
    if (pan.state == UIGestureRecognizerStateEnded) {
        [self saveButtonPosition];
    }
}

- (void)saveButtonPosition {
    if (self.superview) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setFloat:self.center.x / self.superview.bounds.size.width forKey:@"SpeedButtonCenterXPercent"];
        [defaults setFloat:self.center.y / self.superview.bounds.size.height forKey:@"SpeedButtonCenterYPercent"];
        // 保存锁定状态
        [defaults setBool:self.isLocked forKey:@"SpeedButtonLocked"];
        [defaults synchronize];
    }
}

- (void)loadSavedPosition {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float centerXPercent = [defaults floatForKey:@"SpeedButtonCenterXPercent"];
    float centerYPercent = [defaults floatForKey:@"SpeedButtonCenterYPercent"];
    
    // 加载锁定状态
    self.isLocked = [defaults boolForKey:@"SpeedButtonLocked"];
    
    if (centerXPercent > 0 && centerYPercent > 0 && self.superview) {
        self.center = CGPointMake(centerXPercent * self.superview.bounds.size.width,
                                  centerYPercent * self.superview.bounds.size.height);
    }
}

@end

static AWEAwemePlayVideoViewController *currentVideoController = nil;
static FloatingSpeedButton *speedButton = nil;
// 添加一个静态变量来跟踪评论是否正在显示
static BOOL isCommentViewVisible = NO;
// 添加变量用于控制是否在速度后面显示"x"
static BOOL showSpeedX = NO;
// 添加按钮大小变量
static CGFloat speedButtonSize = 36.0;

// 添加对评论控制器的 hook
%hook AWECommentContainerViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 当评论界面即将显示时，设置标记为YES并隐藏按钮
    isCommentViewVisible = YES;
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = YES;
        });
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    // 评论界面完全显示后，再次确认按钮隐藏状态
    isCommentViewVisible = YES;
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = YES;
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    // 评论界面开始消失时，仍然保持按钮隐藏状态
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = YES;
        });
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    // 评论界面完全消失后，才设置标记为NO并恢复按钮显示
    isCommentViewVisible = NO;
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = NO;
        });
    }
}

// 处理视图布局完成情况
- (void)viewDidLayoutSubviews {
    %orig;
    // 在视图布局期间，保持按钮隐藏
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = YES;
        });
    }
}

%end

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
    
    if (index >= speeds.count || index < 0) {
        index = 0;
        [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"CurrentSpeedIndex"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
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

    if (speeds.count == 0) return;
    index = index % speeds.count;
    
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"CurrentSpeedIndex"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

// 更新倍速按钮UI
void updateSpeedButtonUI() {
    if (!speedButton) return;
    
    float currentSpeed = getCurrentSpeed();
    
    // 更精确的格式控制
    NSString *formattedSpeed;
    if (fmodf(currentSpeed, 1.0) == 0) {
        // 整数值 (1.0, 2.0) -> "1", "2"
        formattedSpeed = [NSString stringWithFormat:@"%.0f", currentSpeed];
    } else if (fmodf(currentSpeed * 10, 1.0) == 0) {
        // 一位小数 (1.5) -> "1.5"
        formattedSpeed = [NSString stringWithFormat:@"%.1f", currentSpeed];
    } else {
        // 两位小数 (1.25) -> "1.25"
        formattedSpeed = [NSString stringWithFormat:@"%.2f", currentSpeed];
    }
    
    // 如果需要显示"x"，则添加"x"
    if (showSpeedX) {
        formattedSpeed = [formattedSpeed stringByAppendingString:@"x"];
    }
    
    [speedButton setTitle:formattedSpeed forState:UIControlStateNormal];
}

@interface AWEAwemePlayVideoViewController (SpeedControl)
- (void)adjustPlaybackSpeed:(float)speed;
@end

%hook AWEAwemePlayVideoViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
    float speed = getCurrentSpeed();
    NSInteger speedIndex = getCurrentSpeedIndex();
    
    [self setVideoControllerPlaybackRate:speed];
    %orig(arg0);
    currentVideoController = self;
    
    updateSpeedButtonUI();
}

%new
- (void)adjustPlaybackSpeed:(float)speed {
    [self setVideoControllerPlaybackRate:speed];
}

%end


@interface UIView (SpeedHelper)
- (UIViewController *)firstAvailableUIViewController;
@end

%hook AWEPlayInteractionViewController

- (void)viewDidLayoutSubviews {
    %orig;

    // 添加悬浮速度控制按钮
    if (speedButton == nil) {
        // 使用保存的按钮大小或默认值
        speedButtonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"SpeedButtonSize"] ?: 36.0;
        
        CGRect screenBounds = [UIScreen mainScreen].bounds;
        // 修改初始位置为屏幕中间
        CGRect initialFrame = CGRectMake((screenBounds.size.width - speedButtonSize) / 2, 
                                         (screenBounds.size.height - speedButtonSize) / 2, 
                                         speedButtonSize, speedButtonSize);
        
        speedButton = [[FloatingSpeedButton alloc] initWithFrame:initialFrame];
        
        // 设置按钮的控制器引用
        speedButton.interactionController = self;
        
        // 加载"显示x"的设置
        showSpeedX = [[NSUserDefaults standardUserDefaults] boolForKey:@"SpeedShowX"];
        
        updateSpeedButtonUI();
    } else {
        // 在每次布局时重置按钮状态，确保它始终可点击
        [speedButton resetButtonState];
        
        // 更新按钮大小如果有变化
        if (speedButton.frame.size.width != speedButtonSize) {
            CGPoint center = speedButton.center;
            CGRect newFrame = CGRectMake(0, 0, speedButtonSize, speedButtonSize);
            speedButton.frame = newFrame;
            speedButton.center = center;
            speedButton.layer.cornerRadius = speedButtonSize / 2;
        }
    }
    
    // 确保按钮总是添加到顶层窗口
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    if (keyWindow && ![speedButton isDescendantOfView:keyWindow]) {
        [keyWindow addSubview:speedButton];
        [speedButton loadSavedPosition]; 
        
        // 确保按钮在顶层显示
        speedButton.layer.zPosition = 999;
    }
    
    // 只在评论不可见时才显示按钮
    if (speedButton) {
        speedButton.hidden = isCommentViewVisible;
    }
    
    if (currentVideoController) {
        [currentVideoController adjustPlaybackSpeed:getCurrentSpeed()];
    } else {
        UIViewController *vc = [self firstAvailableUIViewController];
        while (vc && ![vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            vc = vc.parentViewController;
        }
        
        if ([vc isKindOfClass:%c(AWEAwemePlayVideoViewController)]) {
            AWEAwemePlayVideoViewController *videoVC = (AWEAwemePlayVideoViewController *)vc;
            [videoVC adjustPlaybackSpeed:getCurrentSpeed()];
            currentVideoController = videoVC;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    // 视图出现时检查评论状态
    if (speedButton) {
        dispatch_async(dispatch_get_main_queue(), ^{
            speedButton.hidden = isCommentViewVisible;
            
            // 确保按钮位于顶层视图
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (keyWindow && ![speedButton isDescendantOfView:keyWindow]) {
                [keyWindow addSubview:speedButton];
                [speedButton loadSavedPosition];
            }
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    // 临时隐藏按钮，但不移除
    if (speedButton) {
        speedButton.hidden = YES;
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
    
    NSInteger currentIndex = getCurrentSpeedIndex();
    NSInteger newIndex = (currentIndex + 1) % speeds.count;
    
    setCurrentSpeedIndex(newIndex);
    
    float newSpeed = [speeds[newIndex] floatValue];

    // 更精确的格式控制
    NSString *formattedSpeed;
    if (fmodf(newSpeed, 1.0) == 0) {
        // 整数值 (1.0, 2.0) -> "1", "2"
        formattedSpeed = [NSString stringWithFormat:@"%.0f", newSpeed];
    } else if (fmodf(newSpeed * 10, 1.0) == 0) {
        // 一位小数 (1.5) -> "1.5"
        formattedSpeed = [NSString stringWithFormat:@"%.1f", newSpeed];
    } else {
        // 两位小数 (1.25) -> "1.25"
        formattedSpeed = [NSString stringWithFormat:@"%.2f", newSpeed];
    }
    
    // 如果需要显示"x"，则添加"x"
    if (showSpeedX) {
        formattedSpeed = [formattedSpeed stringByAppendingString:@"x"];
    }
    
    [sender setTitle:formattedSpeed forState:UIControlStateNormal];
    
    // 按钮动画
    [UIView animateWithDuration:0.15 animations:^{
        sender.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.15 animations:^{
            sender.transform = CGAffineTransformIdentity;
        }];
    }];
    
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

%new
- (void)showSpeedSettingsDialog {
    // 获取当前配置
    NSString *currentSpeedConfig = [[NSUserDefaults standardUserDefaults] stringForKey:@"SpeedSwitch"] ?: @"1.0,1.25,1.5,2.0";
    BOOL currentShowX = [[NSUserDefaults standardUserDefaults] boolForKey:@"SpeedShowX"];
    
    // 创建设置视图控制器
    SpeedXSettingViewController *settingsVC = [[SpeedXSettingViewController alloc] initWithSpeedConfig:currentSpeedConfig 
                                                                                               showX:currentShowX];
    settingsVC.delegate = self;
    
    // 显示设置视图控制器
    UIViewController *topVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    
    [settingsVC presentInViewController:topVC];
}

%new
- (void)settingsDidUpdateWithSpeedConfig:(NSString *)speedConfig showX:(BOOL)showX buttonSize:(CGFloat)buttonSize {
    // 保存设置
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:speedConfig forKey:@"SpeedSwitch"];
    [defaults setBool:showX forKey:@"SpeedShowX"];
    [defaults setFloat:buttonSize forKey:@"SpeedButtonSize"];
    [defaults setInteger:0 forKey:@"CurrentSpeedIndex"]; 
    [defaults synchronize];
    
    // 更新全局变量
    showSpeedX = showX;
    speedButtonSize = buttonSize;
    
    // 更新按钮UI
    if (speedButton) {
        // 更新按钮大小
        CGPoint center = speedButton.center;
        CGRect newFrame = CGRectMake(0, 0, buttonSize, buttonSize);
        speedButton.frame = newFrame;
        speedButton.center = center;
        speedButton.layer.cornerRadius = buttonSize / 2;
        
        // 更新按钮文本
        updateSpeedButtonUI();
    }
    
    // 应用新的播放速度
    if (currentVideoController) {
        [currentVideoController adjustPlaybackSpeed:getCurrentSpeed()];
    }
    
    // 显示确认消息
    showToast(@"速度设置已更新");
}

%end

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    
    // 当窗口变为key window时，根据评论状态决定按钮显示
    if (speedButton && ![speedButton isDescendantOfView:self]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self addSubview:speedButton];
            [speedButton loadSavedPosition];
            speedButton.layer.zPosition = 999;
            speedButton.hidden = isCommentViewVisible;
        });
    }
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
    if (![defaults objectForKey:@"SpeedButtonSize"]) {
        [defaults setFloat:36.0 forKey:@"SpeedButtonSize"];
    }
    // 读取全局设置
    showSpeedX = [defaults boolForKey:@"SpeedShowX"];
    speedButtonSize = [defaults floatForKey:@"SpeedButtonSize"] ?: 36.0;
    
    [defaults synchronize];
 
    NSInteger initialIndex = getCurrentSpeedIndex();
}