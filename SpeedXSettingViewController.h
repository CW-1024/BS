#import <UIKit/UIKit.h>

@protocol SpeedXSettingViewControllerDelegate <NSObject>
- (void)settingsDidUpdateWithSpeedConfig:(NSString *)speedConfig showX:(BOOL)showX buttonSize:(CGFloat)buttonSize autoRestoreSpeed:(BOOL)autoRestoreSpeed;
@end

@interface SpeedXSettingViewController : UIViewController

@property (nonatomic, weak) id<SpeedXSettingViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *speedConfig;
@property (nonatomic, assign) BOOL showX;
@property (nonatomic, assign) CGFloat buttonSize;
@property (nonatomic, assign) CGFloat bgOpacity;
@property (nonatomic, assign) CGFloat textOpacity;
@property (nonatomic, assign) BOOL autoRestoreSpeed; 

- (instancetype)initWithSpeedConfig:(NSString *)speedConfig showX:(BOOL)showX;
- (void)presentInViewController:(UIViewController *)viewController;

@end
