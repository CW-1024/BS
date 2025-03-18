#import <UIKit/UIKit.h>

@interface DUXToast : NSObject
+ (void)showText:(NSString *)text;
@end

@interface AWEAwemePlayVideoViewController : UIViewController
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context;
- (void)setVideoControllerPlaybackRate:(double)arg0;
@end

@interface AWEElementStackView : UIView
@property (nonatomic, copy) NSString *accessibilityLabel;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong) NSArray *subviews;
@property (nonatomic, assign) CGAffineTransform transform;
@end
