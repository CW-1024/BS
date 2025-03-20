#import "SpeedXSettingViewController.h"

@interface SpeedXSettingViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITextField *speedTextField;
@property (nonatomic, strong) UISwitch *showXSwitch;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint initialCenter;
// 新增属性
@property (nonatomic, strong) UISlider *buttonSizeSlider;
@property (nonatomic, strong) UILabel *buttonSizeLabel;

@end

@implementation SpeedXSettingViewController

- (instancetype)initWithSpeedConfig:(NSString *)speedConfig showX:(BOOL)showX {
    self = [super init];
    if (self) {
        _speedConfig = speedConfig;
        _showX = showX;
        // 从 UserDefaults 读取当前按钮大小或使用默认值 36
        _buttonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"SpeedButtonSize"] ?: 36;
        // 初始化背景和文字不透明度，默认值或从 UserDefaults 读取
        _bgOpacity = [[NSUserDefaults standardUserDefaults] floatForKey:@"SpeedBgOpacity"] ?: 0.7;
        _textOpacity = [[NSUserDefaults standardUserDefaults] floatForKey:@"SpeedTextOpacity"] ?: 1.0;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self setupBlurView];
    [self setupContentView];
    [self setupGestureRecognizers];
}

- (void)setupBlurView {
    // 使用更轻柔的毛玻璃效果
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
    _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    _blurView.frame = self.view.bounds;
    _blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_blurView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap:)];
    [_blurView addGestureRecognizer:tapGesture];
}

- (void)setupContentView {
    // 创建主内容视图 - 更现代的设计
    _contentView = [[UIView alloc] init];
    // 半透明深灰色背景提供更好的视觉对比
    _contentView.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.85];
    _contentView.layer.cornerRadius = 24; // 更大的圆角
    _contentView.layer.masksToBounds = YES;
    
    // 添加微妙的边框和阴影效果
    _contentView.layer.borderWidth = 0.5;
    _contentView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.25].CGColor;
    [self.view addSubview:_contentView];
    
    // 设置内容视图大小和位置 - 增加高度以适应新控件
    CGFloat contentWidth = MIN(340, self.view.bounds.size.width - 40);
    _contentView.frame = CGRectMake((self.view.bounds.size.width - contentWidth) / 2,
                                  (self.view.bounds.size.height - 400) / 2,
                                  contentWidth, 380);
    
    // 添加顶部装饰条 - 现代UI设计元素
    UIView *decorationBar = [[UIView alloc] init];
    decorationBar.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.9];
    decorationBar.frame = CGRectMake((_contentView.bounds.size.width - 60) / 2, 12, 60, 4);
    decorationBar.layer.cornerRadius = 2;
    [_contentView addSubview:decorationBar];
    
    // 添加标题
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"AwemeSpeedX";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold]; // 使用系统字重
    titleLabel.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0]; 
    titleLabel.frame = CGRectMake(0, 30, _contentView.bounds.size.width, 30);
    [_contentView addSubview:titleLabel];
    
    // 添加分隔线 - 更细更现代的线条
    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    separator.frame = CGRectMake(20, titleLabel.frame.origin.y + titleLabel.frame.size.height + 12, 
                                _contentView.bounds.size.width - 40, 0.5);
    [_contentView addSubview:separator];
    
    // 添加速度输入说明
    UILabel *speedLabel = [[UILabel alloc] init];
    speedLabel.text = @"输入用逗号分隔的倍速值";
    speedLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    speedLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.95];
    speedLabel.frame = CGRectMake(20, separator.frame.origin.y + separator.frame.size.height + 20,
                                 _contentView.bounds.size.width - 40, 22);
    [_contentView addSubview:speedLabel];
    
    // 示例标签 - 更加精致的样式
    UILabel *exampleLabel = [[UILabel alloc] init];
    exampleLabel.text = @"例如: 0.75,1.0,1.25,1.5,2.0,3.0";
    exampleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    exampleLabel.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.8];
    exampleLabel.frame = CGRectMake(20, speedLabel.frame.origin.y + speedLabel.frame.size.height + 4,
                                  _contentView.bounds.size.width - 40, 20);
    [_contentView addSubview:exampleLabel];
    
    // 速度输入框 - 更现代的输入框样式
    _speedTextField = [[UITextField alloc] init];
    _speedTextField.text = self.speedConfig;
    _speedTextField.placeholder = @"输入倍速值";
    _speedTextField.attributedPlaceholder = [[NSAttributedString alloc] 
                                           initWithString:@"输入倍速值" 
                                           attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.6 alpha:1.0]}];
    _speedTextField.backgroundColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    _speedTextField.textColor = [UIColor whiteColor];
    _speedTextField.layer.cornerRadius = 12;
    _speedTextField.layer.borderWidth = 1;
    _speedTextField.layer.borderColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.9 alpha:0.3].CGColor;
    _speedTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 20)];
    _speedTextField.leftViewMode = UITextFieldViewModeAlways;
    _speedTextField.returnKeyType = UIReturnKeyDone;
    _speedTextField.delegate = self;
    _speedTextField.frame = CGRectMake(20, exampleLabel.frame.origin.y + exampleLabel.frame.size.height + 10,
                                     _contentView.bounds.size.width - 40, 44);
    [_contentView addSubview:_speedTextField];
    
    // 开关容器 - 新增设计元素
    UIView *switchContainer = [[UIView alloc] init];
    switchContainer.backgroundColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    switchContainer.layer.cornerRadius = 12;
    switchContainer.frame = CGRectMake(20, _speedTextField.frame.origin.y + _speedTextField.frame.size.height + 20,
                                    _contentView.bounds.size.width - 40, 50);
    [_contentView addSubview:switchContainer];
    
    // 显示"x"开关标签
    UILabel *switchLabel = [[UILabel alloc] init];
    switchLabel.text = @"显示数字后的 \"x\"";
    switchLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    switchLabel.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.95];
    switchLabel.frame = CGRectMake(15, (switchContainer.bounds.size.height - 30) / 2,
                                 switchContainer.bounds.size.width - 80, 30);
    [switchContainer addSubview:switchLabel];
    
    // 显示"x"开关 - 现代风格
    _showXSwitch = [[UISwitch alloc] init];
    _showXSwitch.on = self.showX;
    _showXSwitch.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    _showXSwitch.frame = CGRectMake(switchContainer.bounds.size.width - 65, (switchContainer.bounds.size.height - 31) / 2,
                                   51, 31);
    [switchContainer addSubview:_showXSwitch];
    
    // 添加按钮大小容器
    UIView *sizeContainer = [[UIView alloc] init];
    sizeContainer.backgroundColor = [UIColor colorWithWhite:0.18 alpha:1.0];
    sizeContainer.layer.cornerRadius = 12;
    sizeContainer.frame = CGRectMake(20, switchContainer.frame.origin.y + switchContainer.frame.size.height + 20,
                                  _contentView.bounds.size.width - 40, 70);
    [_contentView addSubview:sizeContainer];
    
    // 添加按钮大小标签
    UILabel *sizeTitle = [[UILabel alloc] init];
    sizeTitle.text = @"按钮大小";
    sizeTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    sizeTitle.textColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.95];
    sizeTitle.frame = CGRectMake(15, 10, sizeContainer.bounds.size.width - 30, 22);
    [sizeContainer addSubview:sizeTitle];
    
    // 添加按钮大小显示标签
    _buttonSizeLabel = [[UILabel alloc] init];
    _buttonSizeLabel.text = [NSString stringWithFormat:@"%.0f", self.buttonSize];
    _buttonSizeLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    _buttonSizeLabel.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    _buttonSizeLabel.textAlignment = NSTextAlignmentRight;
    _buttonSizeLabel.frame = CGRectMake(sizeContainer.bounds.size.width - 60, 10, 45, 22);
    [sizeContainer addSubview:_buttonSizeLabel];
    
    // 添加滑块控制按钮大小
    _buttonSizeSlider = [[UISlider alloc] init];
    _buttonSizeSlider.minimumValue = 20.0; // 最小值 20
    _buttonSizeSlider.maximumValue = 60.0; // 最大值 60
    _buttonSizeSlider.value = self.buttonSize;
    _buttonSizeSlider.minimumTrackTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    _buttonSizeSlider.thumbTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    _buttonSizeSlider.frame = CGRectMake(15, sizeTitle.frame.origin.y + sizeTitle.frame.size.height + 6,
                                       sizeContainer.bounds.size.width - 30, 30);
    [_buttonSizeSlider addTarget:self action:@selector(buttonSizeSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [sizeContainer addSubview:_buttonSizeSlider];
    
    // 按钮容器视图 - 调整位置
    UIView *buttonContainer = [[UIView alloc] init];
    buttonContainer.frame = CGRectMake(20, sizeContainer.frame.origin.y + sizeContainer.frame.size.height + 25,
                                     _contentView.bounds.size.width - 40, 50);
    [_contentView addSubview:buttonContainer];
    
    // 取消按钮 - 现代扁平化设计
    _cancelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[UIColor colorWithWhite:0.9 alpha:0.9] forState:UIControlStateNormal];
    _cancelButton.backgroundColor = [UIColor colorWithWhite:0.25 alpha:0.8];
    _cancelButton.layer.cornerRadius = 12;
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _cancelButton.frame = CGRectMake(0, 0, (buttonContainer.bounds.size.width - 10) / 2, 50);
    [_cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:_cancelButton];
    
    // 保存按钮 - 醒目的渐变效果
    _saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_saveButton setTitle:@"保存" forState:UIControlStateNormal];
    [_saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _saveButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
    _saveButton.layer.cornerRadius = 12;
    _saveButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    // 添加渐变效果
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.frame = CGRectMake(0, 0, (buttonContainer.bounds.size.width - 10) / 2, 50);
    gradientLayer.cornerRadius = 12;
    gradientLayer.colors = @[
        (id)[UIColor colorWithRed:0.0 green:0.7 blue:1.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.5 blue:0.9 alpha:1.0].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    [_saveButton.layer insertSublayer:gradientLayer atIndex:0];
    
    _saveButton.frame = CGRectMake(_cancelButton.frame.size.width + 10, 0,
                                 (buttonContainer.bounds.size.width - 10) / 2, 50);
    [_saveButton addTarget:self action:@selector(saveButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:_saveButton];
    
    // 添加作者信息 - 更精致的版权信息
    UILabel *authorLabel = [[UILabel alloc] init];
    authorLabel.text = @"作者: 维他入我心 | Telegram: @vita_app";
    authorLabel.font = [UIFont systemFontOfSize:11];
    authorLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    authorLabel.textAlignment = NSTextAlignmentCenter;
    authorLabel.frame = CGRectMake(0, buttonContainer.frame.origin.y + buttonContainer.frame.size.height + 10,
                                  _contentView.bounds.size.width, 15);
    [_contentView addSubview:authorLabel];
    
    // 调整内容视图的大小以适应所有内容
    CGRect contentFrame = _contentView.frame;
    contentFrame.size.height = authorLabel.frame.origin.y + authorLabel.frame.size.height + 15;
    _contentView.frame = contentFrame;
    
    // 添加轻微的阴影效果增强视觉层次感
    _contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    _contentView.layer.shadowOffset = CGSizeMake(0, 5);
    _contentView.layer.shadowOpacity = 0.3;
    _contentView.layer.shadowRadius = 15;
    _contentView.layer.masksToBounds = NO;
}

- (void)setupGestureRecognizers {
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [_contentView addGestureRecognizer:_panGesture];
}

#pragma mark - Gesture Handlers

- (void)handleBackgroundTap:(UITapGestureRecognizer *)recognizer {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.initialCenter = self.contentView.center;
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        self.contentView.center = CGPointMake(self.initialCenter.x, self.initialCenter.y + translation.y);
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGFloat velocity = [recognizer velocityInView:self.view].y;
        
        if (velocity > 1500 || self.contentView.center.y > self.view.center.y + 100) {
            // 如果速度足够快或者拖拽距离足够，则关闭视图
            [self dismissWithAnimation];
        } else {
            // 否则回到原位
            [UIView animateWithDuration:0.3 animations:^{
                self.contentView.center = self.initialCenter;
            }];
        }
    }
}

#pragma mark - Button Actions

- (void)cancelButtonTapped {
    [self dismissWithAnimation];
}

- (void)saveButtonTapped {
    NSString *speedConfig = [self.speedTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (speedConfig.length > 0) {
        NSArray *speedValues = [speedConfig componentsSeparatedByString:@","];
        BOOL isValid = YES;
        
        for (NSString *value in speedValues) {
            float speed = [value floatValue];
            if (speed <= 0.0 || value.length == 0) {
                isValid = NO;
                break;
            }
        }
        
        if (isValid && speedValues.count > 0) {
            // 更新代理方法调用，传递按钮大小参数
            if ([self.delegate respondsToSelector:@selector(settingsDidUpdateWithSpeedConfig:showX:buttonSize:)]) {
                [self.delegate settingsDidUpdateWithSpeedConfig:speedConfig 
                                                         showX:self.showXSwitch.isOn
                                                    buttonSize:self.buttonSize];
            }
            [self dismissWithAnimation];
        } else {
            [self showErrorMessage:@"格式错误，请输入有效的速度值"];
        }
    } else {
        [self showErrorMessage:@"请输入有效的速度值"];
    }
}

// 添加滑块值变化处理方法
- (void)buttonSizeSliderChanged:(UISlider *)slider {
    // 将值四舍五入到整数
    CGFloat roundedValue = roundf(slider.value);
    slider.value = roundedValue;
    self.buttonSize = roundedValue;
    
    // 更新显示标签
    self.buttonSizeLabel.text = [NSString stringWithFormat:@"%.0f", roundedValue];
}

- (void)showErrorMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"错误" 
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" 
                                              style:UIAlertActionStyleDefault 
                                            handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Presentation Methods

- (void)presentInViewController:(UIViewController *)viewController {
    // 初始状态设置
    self.view.alpha = 0;
    self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    
    [viewController presentViewController:self animated:NO completion:^{
        // 执行出现动画
        [UIView animateWithDuration:0.3 animations:^{
            self.view.alpha = 1.0;
            self.contentView.transform = CGAffineTransformIdentity;
        }];
    }];
}

- (void)dismissWithAnimation {
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        self.contentView.alpha = 0;
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 注册键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillShow:) 
                                                 name:UIKeyboardWillShowNotification 
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardWillHide:) 
                                                 name:UIKeyboardWillHideNotification 
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // 移除键盘通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard Handling

- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    CGFloat keyboardHeight = keyboardSize.height;
    
    CGRect contentFrame = self.contentView.frame;
    CGFloat contentBottom = contentFrame.origin.y + contentFrame.size.height;
    CGFloat screenHeight = self.view.bounds.size.height;
    
    // 如果内容视图的底部会被键盘遮挡
    if (contentBottom > (screenHeight - keyboardHeight)) {
        CGFloat offset = contentBottom - (screenHeight - keyboardHeight) + 10; // 额外10点的间距
        
        [UIView animateWithDuration:0.3 animations:^{
            self.contentView.center = CGPointMake(self.contentView.center.x, self.contentView.center.y - offset);
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    // 键盘隐藏时恢复内容视图位置
    [UIView animateWithDuration:0.3 animations:^{
        self.contentView.center = CGPointMake(self.view.center.x, self.view.center.y);
    }];
}

@end
