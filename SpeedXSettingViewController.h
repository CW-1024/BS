#import <UIKit/UIKit.h>

@protocol SpeedXSettingViewControllerDelegate <NSObject>

@optional
// 旧的代理方法，保留向后兼容性
- (void)settingsDidUpdateWithSpeedConfig:(NSString *)speedConfig showX:(BOOL)showX buttonSize:(CGFloat)buttonSize;
// 新的代理方法，包含全部参数
- (void)settingsDidUpdateWithSpeedConfig:(NSString *)speedConfig showX:(BOOL)showX buttonSize:(CGFloat)buttonSize bgOpacity:(CGFloat)bgOpacity textOpacity:(CGFloat)textOpacity;

@end

@interface SpeedXSettingViewController : UIViewController

@property (nonatomic, strong) NSString *speedConfig;
@property (nonatomic, assign) BOOL showX;
@property (nonatomic, assign) CGFloat buttonSize;
@property (nonatomic, assign) CGFloat bgOpacity;
@property (nonatomic, assign) CGFloat textOpacity;
@property (nonatomic, weak) id<SpeedXSettingViewControllerDelegate> delegate;

- (instancetype)initWithSpeedConfig:(NSString *)speedConfig showX:(BOOL)showX;
- (void)presentInViewController:(UIViewController *)viewController;

@end
