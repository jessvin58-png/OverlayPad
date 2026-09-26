#import "HUDInternal.h"

@implementation HUD (Presets)

+ (void)showPresetPanel {
    [self hidePresetPanel];
    CGRect scr = [UIScreen mainScreen].bounds;
    CGFloat w = MIN(360, scr.size.width - 40);
    CGFloat h = MIN(560, scr.size.height - 100);

    sPresetPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    sPresetPanel.center = CGPointMake(scr.size.width / 2,
                                      scr.size.height / 2);
    sPresetPanel.backgroundColor = PanelBg();
    sPresetPanel.layer.cornerRadius = 18;
    sPresetPanel.layer.masksToBounds = YES;
    [sWin.rootViewController.view addSubview:sPresetPanel];

    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 44)];
    bar.backgroundColor = PanelBarBg();
    bar.userInteractionEnabled = YES;
    [sPresetPanel addSubview:bar];
    [bar addGestureRecognizer:[[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(onPresetDrag:)]];

    UILabel *title = [[UILabel alloc]
        initWithFrame:CGRectMake(16, 0, w - 60, 44)];
    title.text = LK(@"presets.title");
    title.textColor = PanelText();
    title.font = [UIFont boldSystemFontOfSize:16];
    [bar addSubview:title];

    UIButton *close = PanelIconButton(@"xmark", @"X");
    close.frame = CGRectMake(w - 42, 8, 28, 28);
    [close addTarget:self action:@selector(hidePresetPanel)
        forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:close];

    CGFloat footH = 48;
    UIView *foot = [[UIView alloc]
        initWithFrame:CGRectMake(0, h - footH, w, footH)];
    foot.backgroundColor = PanelBarBg();
    [sPresetPanel addSubview:foot];

    CGFloat bw = (w - 24) / 2;
    UIButton *newBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    newBtn.frame = CGRectMake(8, 8, bw, 32);
    [newBtn setTitle:LK(@"presets.new") forState:UIControlStateNormal];
    [newBtn setTitleColor:PanelText() forState:UIControlStateNormal];
    newBtn.backgroundColor = PanelFieldBg();
    newBtn.layer.cornerRadius = 8;
    [newBtn addTarget:self action:@selector(onPresetNew)
        forControlEvents:UIControlEventTouchUpInside];
    [foot addSubview:newBtn];

    UIButton *impBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    impBtn.frame = CGRectMake(w / 2 + 4, 8, bw, 32);
    [impBtn setTitle:LK(@"presets.paste")
            forState:UIControlStateNormal];
    [impBtn setTitleColor:PanelText() forState:UIControlStateNormal];
    impBtn.backgroundColor = PanelFieldBg();
    impBtn.layer.cornerRadius = 8;
    [impBtn addTarget:self action:@selector(onPresetPaste)
        forControlEvents:UIControlEventTouchUpInside];
    [foot addSubview:impBtn];

    sPresetContent = [[UIScrollView alloc] initWithFrame:
        CGRectMake(0, 44, w, h - 44 - footH)];
    sPresetContent.alwaysBounceVertical = YES;
    [sPresetPanel addSubview:sPresetContent];

    [self buildPresetRows];
    DBG(@"hud: preset panel");
}

+ (void)hidePresetPanel {
    [sPresetPanel removeFromSuperview];
    sPresetPanel = nil;
    sPresetContent = nil;
}

+ (void)onPresetDrag:(UIPanGestureRecognizer *)g {
    UIView *bar = g.view;
    UIView *p = bar.superview;
    if (!p) return;
    CGPoint t = [g translationInView:p.superview];
    if (g.state == UIGestureRecognizerStateBegan ||
        g.state == UIGestureRecognizerStateChanged) {
        p.center = CGPointMake(p.center.x + t.x, p.center.y + t.y);
        [g setTranslation:CGPointZero inView:p.superview];
    }
}

+ (void)buildPresetRows {
    for (UIView *v in sPresetContent.subviews) [v removeFromSuperview];
    Presets *ps = [Presets shared];
    NSArray *list = [ps all];
    CGFloat w = sPresetContent.bounds.size.width;
    CGFloat rowH = 56;
    CGFloat y = 8;

    for (NSInteger i = 0; i < (NSInteger)list.count; i++) {
        Preset *p = list[i];
        BOOL active = [p.pid isEqualToString:[ps activeId]];

        UIView *row = [[UIView alloc] initWithFrame:
            CGRectMake(8, y, w - 16, rowH - 4)];
        row.backgroundColor = active ? PanelFieldBg() : [UIColor clearColor];
        row.layer.cornerRadius = 8;
        row.tag = i;
        [row addGestureRecognizer:[[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(onPresetRowTap:)]];

        UILabel *name = [[UILabel alloc] initWithFrame:
            CGRectMake(12, 6, w - 100, 20)];
        name.text = [p displayName];
        name.textColor = PanelText();
        name.font = [UIFont systemFontOfSize:15
                                      weight:UIFontWeightMedium];
        [row addSubview:name];

        NSArray *btns = p.data[@"buttons"];
        NSInteger cnt = [btns isKindOfClass:[NSArray class]] ? btns.count : 0;
        UILabel *meta = [[UILabel alloc] initWithFrame:
            CGRectMake(12, rowH - 26, w - 100, 14)];
        meta.text = [NSString stringWithFormat:@"%ld %@", (long)cnt,
                     LK(@"presets.buttonsSuffix")];
        meta.textColor = PanelSubText();
        meta.font = [UIFont systemFontOfSize:11];
        [row addSubview:meta];

        if (active) {
            UILabel *mark = [[UILabel alloc] initWithFrame:
                CGRectMake(w - 96, 6, 60, 18)];
            mark.text = @"✓";
            mark.textColor = PanelAccent();
            mark.font = [UIFont boldSystemFontOfSize:16];
            mark.textAlignment = NSTextAlignmentRight;
            [row addSubview:mark];
        }

        UIButton *more = [UIButton buttonWithType:UIButtonTypeSystem];
        more.frame = CGRectMake(w - 16 - 44, 10, 36, 32);
        [more setTitle:@"···" forState:UIControlStateNormal];
        [more setTitleColor:PanelText() forState:UIControlStateNormal];
        more.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        more.backgroundColor = PanelFieldBg();
        more.layer.cornerRadius = 8;
        more.tag = i;
        [more addTarget:self action:@selector(onPresetMore:)
            forControlEvents:UIControlEventTouchUpInside];
        [row addSubview:more];

        [sPresetContent addSubview:row];
        y += rowH;
    }
    sPresetContent.contentSize = CGSizeMake(w, y + 8);
}

+ (void)onPresetRowTap:(UITapGestureRecognizer *)g {
    NSInteger i = g.view.tag;
    Presets *ps = [Presets shared];
    NSArray *list = [ps all];
    if (i < 0 || i >= (NSInteger)list.count) return;
    Preset *p = list[i];
    DBG(@"hud: apply preset '%@'", [p displayName]);
    [ps apply:p];
    [Pad rebuild];
    [Pad apply];
    [self buildPresetRows];
    [self toast:LK(@"toast.presetApplied")];
}

+ (void)onPresetMore:(UIButton *)b {
    NSInteger i = b.tag;
    Presets *ps = [Presets shared];
    NSArray *list = [ps all];
    if (i < 0 || i >= (NSInteger)list.count) return;
    Preset *p = list[i];

    UIAlertController *ac = [UIAlertController
        alertControllerWithTitle:[p displayName] message:nil
        preferredStyle:UIAlertControllerStyleActionSheet];

    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.rename")
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [self presetRename:p];
        }]];
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"presets.copy")
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [ps syncCurrent];
            NSString *s = [ps exportString:p];
            if (s) {
                [UIPasteboard generalPasteboard].string = s;
                DBG(@"hud: preset '%@' copied %lu",
                    [p displayName], (unsigned long)s.length);
                [self toast:LK(@"toast.copied")];
            }
        }]];
    if ([list count] > 1) {
        [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.delete")
            style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
                DBG(@"hud: delete preset '%@'", [p displayName]);
                [ps remove:p];
                [Pad rebuild];
                [Pad apply];
                [self buildPresetRows];
            }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.cancel")
        style:UIAlertActionStyleCancel handler:nil]];
    ac.popoverPresentationController.sourceView = b;
    ac.popoverPresentationController.sourceRect = b.bounds;
    [sWin.rootViewController presentViewController:ac
                                          animated:YES completion:nil];
}

+ (void)presetRename:(Preset *)p {
    UIAlertController *ac = [UIAlertController
        alertControllerWithTitle:LK(@"common.rename")
        message:nil preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.text = [p displayName];
    }];
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.cancel")
        style:UIAlertActionStyleCancel handler:nil]];
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.ok")
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            NSString *n = ac.textFields.firstObject.text;
            DBG(@"hud: rename '%@'", n);
            [[Presets shared] rename:p name:n];
            [self buildPresetRows];
        }]];
    [sWin.rootViewController presentViewController:ac
                                          animated:YES completion:nil];
}

+ (void)onPresetNew {
    UIAlertController *ac = [UIAlertController
        alertControllerWithTitle:LK(@"presets.newTitle")
        message:LK(@"presets.newMsg")
        preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = LK(@"presets.namePh");
    }];
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.cancel")
        style:UIAlertActionStyleCancel handler:nil]];
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.ok")
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            NSString *n = ac.textFields.firstObject.text;
            DBG(@"hud: new preset '%@'", n);
            [[Presets shared] createFromCurrent:n];
            [self buildPresetRows];
        }]];
    [sWin.rootViewController presentViewController:ac
                                          animated:YES completion:nil];
}

+ (void)onPresetPaste {
    NSString *s = [UIPasteboard generalPasteboard].string;
    NSString *err = nil;
    Preset *p = [[Presets shared] importString:s error:&err];
    if (p) {
        DBG(@"hud: preset imported '%@'", [p displayName]);
        [self buildPresetRows];
        [self toast:LK(@"toast.imported")];
    } else {
        DBG(@"hud: preset import fail: %@", err);
        [self toast:err ?: LK(@"toast.importFailed")];
    }
}

@end