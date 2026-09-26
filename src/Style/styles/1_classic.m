#import "Style.h"

void SkinReg1(void) {
    [Skin registerJoy:1 en:@"style.classic" zh:@""
        block:^(UIView *base, UIView *thumb, UIColor *color, CGFloat alpha) {
            base.backgroundColor = [color colorWithAlphaComponent:alpha * 0.15];
            base.layer.borderWidth = 1.5;
            base.layer.borderColor = [color colorWithAlphaComponent:alpha * 0.55].CGColor;
            thumb.backgroundColor = [UIColor colorWithWhite:1.0 alpha:alpha];
        }];

    [Skin registerBtn:1 en:@"style.classic" zh:@""
        block:^(UIView *visual, UILabel *label, UIColor *color, CGFloat alpha) {
            visual.backgroundColor = [color colorWithAlphaComponent:alpha];
            label.textColor = [UIColor colorWithWhite:0.10 alpha:0.95];
        }];
}