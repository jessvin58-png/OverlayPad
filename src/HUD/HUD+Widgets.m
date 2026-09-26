#import "HUDInternal.h"

@implementation HUD (Widgets)

+ (void)toast:(NSString *)msg {
    if (!sWin || !msg.length) return;
    [sToast removeFromSuperview];
    UIView *root = sWin.rootViewController.view;
    UILabel *l = [[UILabel alloc] init];
    l.text = msg;
    l.textColor = [UIColor whiteColor];
    l.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 0;
    l.backgroundColor =
        [UIColor colorWithRed:0.15 green:0.62 blue:0.58 alpha:0.95];
    l.layer.cornerRadius = 10;
    l.layer.masksToBounds = YES;
    l.alpha = 0;
    [root addSubview:l];
    sToast = l;
    CGSize maxSz = CGSizeMake(root.bounds.size.width - 80, 200);
    CGRect rect = [msg boundingRectWithSize:maxSz
        options:NSStringDrawingUsesLineFragmentOrigin
        attributes:@{NSFontAttributeName: l.font} context:nil];
    CGFloat tw = MIN(maxSz.width, rect.size.width + 32);
    CGFloat th = MAX(36, rect.size.height + 20);
    l.bounds = CGRectMake(0, 0, tw, th);
    l.center = CGPointMake(root.bounds.size.width / 2,
                           root.bounds.size.height - 80);
    [UIView animateWithDuration:0.15 animations:^{ l.alpha = 1; }
        completion:^(BOOL ok) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            (int64_t)(1.6 * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.2 animations:^{ l.alpha = 0; }
                completion:^(BOOL ok2) {
                [l removeFromSuperview];
                if (sToast == l) sToast = nil;
            }];
        });
    }];
}

+ (void)shake:(UIView *)v {
    if (!v) return;
    CAKeyframeAnimation *a = [CAKeyframeAnimation
        animationWithKeyPath:@"transform.translation.x"];
    a.values = @[@0, @-8, @8, @-6, @6, @-3, @3, @0];
    a.duration = 0.4;
    [v.layer addAnimation:a forKey:@"shake"];
    UIColor *orig = v.backgroundColor;
    v.backgroundColor = [UIColor colorWithRed:1 green:0.6 blue:0.6 alpha:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
        (int64_t)(0.4 * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{ v.backgroundColor = orig; });
}

+ (void)scheduleSaveAndSync {
    [sSaveTimer invalidate];
    sSaveTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                  target:self
                                                selector:@selector(flushSave)
                                                userInfo:nil
                                                 repeats:NO];
}

+ (void)flushSave {
    sSaveTimer = nil;
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
    LOG(@"hud: save+sync");
}

+ (void)confirm:(NSString *)title action:(void (^)(void))action {
    UIAlertController *ac = [UIAlertController
        alertControllerWithTitle:title message:nil
        preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.cancel")
        style:UIAlertActionStyleCancel handler:nil]];
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.confirm")
        style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
            if (action) action();
        }]];
    ac.popoverPresentationController.sourceView = sPanel;
    ac.popoverPresentationController.sourceRect = sPanel.bounds;
    [sWin.rootViewController presentViewController:ac
                                          animated:YES completion:nil];
}

+ (void)showDropdownAt:(UIView *)anchor
                 items:(NSArray<NSString *> *)items
               current:(NSInteger)cur
                onPick:(void (^)(NSInteger))cb {
    [self hideDropdown];
    if (!anchor || !items.count) return;
    UIView *root = sWin.rootViewController.view;
    CGRect af = [anchor convertRect:anchor.bounds toView:root];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeCustom];
    back.frame = root.bounds;
    back.backgroundColor = [UIColor clearColor];
    [back addTarget:self action:@selector(hideDropdown)
        forControlEvents:UIControlEventTouchUpInside];
    [root addSubview:back];
    sDropBack = back;

    CGFloat rowH = 40;
    CGFloat dw = MAX(160, af.size.width);
    CGFloat dh = rowH * items.count;
    CGFloat dx = af.origin.x;
    CGFloat dy = af.origin.y + af.size.height + 4;
    if (dy + dh > root.bounds.size.height - 20) dy = af.origin.y - dh - 4;
    if (dx + dw > root.bounds.size.width - 12)
        dx = root.bounds.size.width - 12 - dw;
    if (dx < 12) dx = 12;
    if (dy < 12) dy = 12;

    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(dx, dy, dw, dh)];
    box.backgroundColor = PanelBg();
    box.layer.cornerRadius = 12;
    box.layer.borderWidth = 1;
    box.layer.borderColor = PanelBorder().CGColor;
    box.layer.shadowColor = [UIColor blackColor].CGColor;
    box.layer.shadowRadius = 14;
    box.layer.shadowOpacity = 0.28;
    box.layer.shadowOffset = CGSizeMake(0, 6);
    box.layer.masksToBounds = NO;
    [root addSubview:box];
    sDropBox = box;

    for (NSInteger i = 0; i < (NSInteger)items.count; i++) {
        UIButton *r = [UIButton buttonWithType:UIButtonTypeSystem];
        r.frame = CGRectMake(0, i * rowH, dw, rowH);
        NSString *t = [@"   " stringByAppendingString:items[i]];
        [r setTitle:t forState:UIControlStateNormal];
        UIColor *tc = (i == cur) ? PanelAccent() : PanelText();
        [r setTitleColor:tc forState:UIControlStateNormal];
        r.titleLabel.font = [UIFont systemFontOfSize:14];
        r.contentHorizontalAlignment =
            UIControlContentHorizontalAlignmentLeft;
        r.tag = i;
        objc_setAssociatedObject(r, "cb", cb, OBJC_ASSOCIATION_COPY);
        [r addTarget:self action:@selector(onDropdownPick:)
            forControlEvents:UIControlEventTouchUpInside];
        [box addSubview:r];
        if (i > 0) {
            UIView *sep = [[UIView alloc] initWithFrame:
                CGRectMake(8, i * rowH, dw - 16, 0.5)];
            sep.backgroundColor = PanelBorder();
            [box addSubview:sep];
        }
    }
}

+ (void)hideDropdown {
    [sDropBox removeFromSuperview];
    [sDropBack removeFromSuperview];
    sDropBox = nil;
    sDropBack = nil;
}

+ (void)onDropdownPick:(UIButton *)b {
    void (^cb)(NSInteger) = objc_getAssociatedObject(b, "cb");
    NSInteger idx = b.tag;
    [self hideDropdown];
    if (cb) cb(idx);
}

+ (UIView *)rowWithLabel:(NSString *)title
                       y:(CGFloat)y h:(CGFloat)h w:(CGFloat)w {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, h)];
    UILabel *lbl = [[UILabel alloc] init];
    lbl.frame = CGRectMake(16, 4, w - 32, 18);
    lbl.text = title;
    lbl.textColor = PanelSubText();
    lbl.font = [UIFont systemFontOfSize:13];
    [row addSubview:lbl];
    return row;
}

+ (UIView *)makeSliderRow:(NSString *)title
                      key:(NSString *)key
                      min:(CGFloat)mn
                      max:(CGFloat)mx
                    value:(CGFloat)v
                     vtag:(NSInteger)vtag
                        y:(CGFloat)y
                        w:(CGFloat)w
                      fmt:(NSString *)fmt {
    UIView *row = [self rowWithLabel:title y:y h:56 w:w];

    UISlider *sl = [[UISlider alloc] init];
    sl.tag = 910;
    sl.frame = CGRectMake(16, 26, w - 116, 24);
    sl.minimumValue = mn;
    sl.maximumValue = mx;
    sl.value = v;
    sl.tintColor = PanelAccent();
    objc_setAssociatedObject(sl, "k", key, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(sl, "vt", @(vtag), OBJC_ASSOCIATION_RETAIN);
    [sl addTarget:self action:@selector(onSliderMoved:)
        forControlEvents:UIControlEventValueChanged];
    [row addSubview:sl];

    UITextField *tf = [[UITextField alloc] init];
    tf.tag = vtag;
    tf.frame = CGRectMake(w - 92, 24, 76, 28);
    tf.text = [NSString stringWithFormat:fmt, v];
    tf.textColor = PanelText();
    tf.backgroundColor = PanelFieldBg();
    tf.layer.cornerRadius = 6;
    tf.font = [UIFont monospacedDigitSystemFontOfSize:13
                                                weight:UIFontWeightMedium];
    tf.textAlignment = NSTextAlignmentCenter;
    tf.keyboardType = UIKeyboardTypeDecimalPad;
    tf.returnKeyType = UIReturnKeyDone;
    objc_setAssociatedObject(tf, "k", key, OBJC_ASSOCIATION_COPY);
    objc_setAssociatedObject(tf, "mn", @(mn), OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(tf, "mx", @(mx), OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(tf, "fmt", fmt, OBJC_ASSOCIATION_COPY);
    [tf addTarget:self action:@selector(onFieldEnd:)
        forControlEvents:UIControlEventEditingDidEnd |
                         UIControlEventEditingDidEndOnExit];
    [row addSubview:tf];
    return row;
}

@end