#import "HUDInternal.h"
#import "About.h"

static const NSInteger kRowTag   = 300;
static const NSInteger kIconTag  = 310;
static const NSInteger kTitleTag = 301;
static const NSInteger kValueTag = 302;
static const NSInteger kSepTag   = 320;

@implementation HUD (Panel)

+ (NSArray *)menuSpec {
    UIColor *blue   = [UIColor systemBlueColor];
    UIColor *indigo = [UIColor systemIndigoColor];
    UIColor *teal   = [UIColor systemTealColor];
    UIColor *green  = [UIColor systemGreenColor];
    UIColor *orange = [UIColor systemOrangeColor];
    UIColor *red    = [UIColor systemRedColor];
    UIColor *gray   = [UIColor systemGrayColor];
    return @[
        @{ @"title": LK(@"settings.lang"),      @"action": @"lang",
           @"icon": @"globe",                    @"color": blue },
        @{ @"title": LK(@"settings.presets"),   @"action": @"presets",
           @"icon": @"square.stack.3d.up.fill",  @"color": indigo },
        @{ @"title": LK(@"settings.editMode"),  @"action": @"editMode",
           @"icon": @"slider.horizontal.below.rectangle",
                                                  @"color": teal },
        @{ @"title": LK(@"settings.addButton"), @"action": @"addBtn",
           @"icon": @"plus.circle.fill",         @"color": green },
        @{ @"title": LK(@"settings.resetPos"),  @"action": @"resetPos",
           @"icon": @"arrow.counterclockwise",   @"color": orange },
        @{ @"title": LK(@"settings.resetAll"),  @"action": @"resetAll",
           @"icon": @"trash.fill",               @"color": red },
        @{ @"title": LK(@"settings.about"),     @"action": @"about",
           @"icon": @"info.circle.fill",         @"color": gray },
    ];
}

+ (UIView *)iconTile:(NSString *)sfName color:(UIColor *)color {
    UIView *tile = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    tile.backgroundColor = color ?: [UIColor systemGrayColor];
    tile.layer.cornerRadius = 7;
    tile.clipsToBounds = YES;
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration
            configurationWithPointSize:16
                                weight:UIImageSymbolWeightSemibold];
        UIImage *img = sfName ? [UIImage systemImageNamed:sfName
                                        withConfiguration:cfg] : nil;
        if (!img && sfName) {
            img = [UIImage systemImageNamed:@"questionmark"
                          withConfiguration:cfg];
        }
        if (img) {
            UIImageView *iv = [[UIImageView alloc] initWithImage:img];
            iv.tintColor = [UIColor whiteColor];
            iv.contentMode = UIViewContentModeCenter;
            iv.frame = tile.bounds;
            [tile addSubview:iv];
        }
    }
    return tile;
}

+ (void)buildPanel {
    sPanel = [[UIView alloc] init];
    sPanel.backgroundColor = PanelBg();
    sPanel.layer.cornerRadius = 18;
    sPanel.layer.masksToBounds = YES;
    sPanel.hidden = YES;

    UIView *bar = [[UIView alloc] init];
    bar.backgroundColor = PanelBarBg();
    bar.tag = 100;
    bar.userInteractionEnabled = YES;
    [sPanel addSubview:bar];

    UIPanGestureRecognizer *pd = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(onPanelDrag:)];
    pd.cancelsTouchesInView = NO;
    [bar addGestureRecognizer:pd];

    sTitle = [[UILabel alloc] init];
    sTitle.text = LK(@"settings.title");
    sTitle.textColor = PanelText();
    sTitle.font = [UIFont boldSystemFontOfSize:16];
    [bar addSubview:sTitle];

    UIButton *minBtn = PanelIconButton(@"minus", @"-");
    minBtn.tag = 101;
    [bar addSubview:minBtn];
    UIButton *maxBtn = PanelIconButton(
        @"arrow.up.left.and.arrow.down.right", @"+");
    maxBtn.tag = 102;
    [bar addSubview:maxBtn];
    [minBtn addTarget:self action:@selector(onMin)
        forControlEvents:UIControlEventTouchUpInside];
    [maxBtn addTarget:self action:@selector(onMax)
        forControlEvents:UIControlEventTouchUpInside];

    sContent = [[UIScrollView alloc] init];
    sContent.tag = 200;
    sContent.alwaysBounceVertical = YES;
    sContent.showsVerticalScrollIndicator = NO;
    [sPanel addSubview:sContent];

    [self buildRows];
}

+ (void)buildRows {
    for (UIView *v in sContent.subviews) [v removeFromSuperview];
    Settings *st = [Settings shared];
    NSArray *spec = [self menuSpec];
    CGFloat w = sPanel.bounds.size.width;
    if (w < 100) w = 320;
    CGFloat y = 8;

    for (NSInteger i = 0; i < (NSInteger)spec.count; i++) {
        NSDictionary *item = spec[i];
        NSString *act = item[@"action"];

        UIView *row = [[UIView alloc] initWithFrame:
            CGRectMake(0, y, w, 56)];
        row.tag = kRowTag;
        row.backgroundColor = [UIColor clearColor];
        row.userInteractionEnabled = YES;

        UIView *tile = [self iconTile:item[@"icon"] color:item[@"color"]];
        tile.tag = kIconTag;
        tile.frame = CGRectMake(16, 13, 30, 30);
        [row addSubview:tile];

        UILabel *title = [[UILabel alloc] init];
        title.text = item[@"title"];
        title.textColor = PanelText();
        title.font = [UIFont systemFontOfSize:15];
        title.tag = kTitleTag;
        title.frame = CGRectMake(58, 0, w - 58 - 90, 56);
        [row addSubview:title];

        UILabel *value = [[UILabel alloc] init];
        value.textColor = PanelSubText();
        value.textAlignment = NSTextAlignmentRight;
        value.tag = kValueTag;
        value.frame = CGRectMake(w - 110, 0, 94, 56);
        if ([act isEqualToString:@"lang"]) {
            value.font = [UIFont systemFontOfSize:14];
            value.text = [NSString stringWithFormat:@"%@  ›",
                          LangName(st.langMode)];
        } else if ([act isEqualToString:@"editMode"]) {
            value.font = [UIFont systemFontOfSize:14];
            value.text = st.editMode ? LK(@"common.on") : LK(@"common.off");
            value.textColor = st.editMode ? PanelAccent() : PanelSubText();
        } else {
            value.font = [UIFont systemFontOfSize:18
                                            weight:UIFontWeightMedium];
            value.text = @"›";
        }
        [row addSubview:value];

        UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(onRowTap:)];
        objc_setAssociatedObject(row, "act", act, OBJC_ASSOCIATION_COPY);
        [row addGestureRecognizer:t];

        [sContent addSubview:row];

        if (i + 1 < (NSInteger)spec.count) {
            UIView *sep = [[UIView alloc]
                initWithFrame:CGRectMake(58, 55.5, w - 58, 0.5)];
            sep.backgroundColor = PanelBorder();
            sep.tag = kSepTag;
            [row addSubview:sep];
        }

        y += 56;
    }
    sContent.contentSize = CGSizeMake(w, y + 8);
}

+ (void)layoutPanel {
    if (!sPanel || !sWin) return;
    Settings *st = [Settings shared];
    CGRect scr = [UIScreen mainScreen].bounds;
    UIEdgeInsets safe = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) safe = sWin.safeAreaInsets;
    const CGFloat barH = 44;
    CGSize sz;
    CGPoint ctr;

    if (st.hudState == HUDStateFull) {
        sz = scr.size;
        ctr = CGPointMake(scr.size.width / 2, scr.size.height / 2);
        sPanel.layer.cornerRadius = 0;
    } else {
        NSInteger rows = (NSInteger)[self menuSpec].count;
        CGFloat contentH = rows * 56 + 16;
        CGFloat maxW = scr.size.width - 40;
        CGFloat maxH = scr.size.height - safe.top - safe.bottom - 60;
        CGFloat pw = MIN(340, maxW);
        CGFloat ph = MIN(contentH + barH, maxH);
        sz = CGSizeMake(pw, ph);
        if (st.panelPos.x == 0 && st.panelPos.y == 0)
            ctr = CGPointMake(scr.size.width - pw / 2 - 16,
                              scr.size.height / 2);
        else
            ctr = CGPointMake(scr.size.width / 2 + st.panelPos.x,
                              scr.size.height / 2 + st.panelPos.y);
        sPanel.layer.cornerRadius = 18;
    }
    sPanel.bounds = CGRectMake(0, 0, sz.width, sz.height);
    sPanel.center = ctr;

    UIView *bar = [sPanel viewWithTag:100];
    bar.frame = CGRectMake(0, 0, sz.width, barH);
    sTitle.frame = CGRectMake(16, 0, sz.width - 100, barH);
    UIButton *minBtn = (UIButton *)[bar viewWithTag:101];
    minBtn.frame = CGRectMake(sz.width - 76, 8, 28, 28);
    UIButton *maxBtn = (UIButton *)[bar viewWithTag:102];
    maxBtn.frame = CGRectMake(sz.width - 42, 8, 28, 28);
    sContent.frame = CGRectMake(0, barH, sz.width, sz.height - barH);

    CGFloat y = 8;
    for (UIView *row in sContent.subviews) {
        if (row.tag != kRowTag) continue;
        row.frame = CGRectMake(0, y, sz.width, 56);

        UIView *tile = [row viewWithTag:kIconTag];
        tile.frame = CGRectMake(16, 13, 30, 30);

        UILabel *title = [row viewWithTag:kTitleTag];
        title.frame = CGRectMake(58, 0, sz.width - 58 - 100, 56);

        UILabel *value = [row viewWithTag:kValueTag];
        value.frame = CGRectMake(sz.width - 110, 0, 94, 56);

        UIView *sep = [row viewWithTag:kSepTag];
        sep.frame = CGRectMake(58, 55.5, sz.width - 58, 0.5);

        y += 56;
    }
    sContent.contentSize = CGSizeMake(sz.width, y + 8);
}

+ (void)onPanelDrag:(UIPanGestureRecognizer *)g {
    UIView *panel = g.view.superview;
    if (!panel) return;
    CGPoint t = [g translationInView:panel.superview];
    if (g.state == UIGestureRecognizerStateBegan) {
        panel.layer.shouldRasterize = YES;
        panel.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    if (g.state == UIGestureRecognizerStateBegan ||
        g.state == UIGestureRecognizerStateChanged) {
        panel.center = CGPointMake(panel.center.x + t.x,
                                   panel.center.y + t.y);
        [g setTranslation:CGPointZero inView:panel.superview];
    } else if (g.state == UIGestureRecognizerStateEnded ||
               g.state == UIGestureRecognizerStateCancelled) {
        panel.layer.shouldRasterize = NO;
        Settings *st = [Settings shared];
        CGRect scr = [UIScreen mainScreen].bounds;
        st.panelPos = CGPointMake(panel.center.x - scr.size.width / 2,
                                  panel.center.y - scr.size.height / 2);
        [st save];
        [[Presets shared] syncCurrent];
        DBG(@"hud: panel %@", NSStringFromCGPoint(st.panelPos));
    }
}

+ (void)onRowTap:(UITapGestureRecognizer *)g {
    NSString *act = objc_getAssociatedObject(g.view, "act");
    [self doAction:act];
}

+ (void)onAction:(UIButton *)b {
    NSString *act = objc_getAssociatedObject(b, "act");
    [self doAction:act];
}

+ (void)doAction:(NSString *)act {
    if (!act.length) return;
    Settings *st = [Settings shared];
    DBG(@"hud: action %@", act);
    if ([act isEqualToString:@"lang"]) {
        [self showLangPicker];
    } else if ([act isEqualToString:@"presets"]) {
        [self showPresetPanel];
    } else if ([act isEqualToString:@"editMode"]) {
        st.editMode = !st.editMode;
        sEditing = st.editMode;
        [st save];
        [[Presets shared] syncCurrent];
        [Pad setEditing:st.editMode];
        [self buildRows];
        DBG(@"hud: editMode -> %d", st.editMode);
        [self toast:st.editMode ? LK(@"toast.editOn") : LK(@"toast.editOff")];
    } else if ([act isEqualToString:@"addBtn"]) {
        [st addButton];
        [st save];
        [[Presets shared] syncCurrent];
        [Pad rebuild];
        [self buildRows];
        [self layoutPanel];
        [self toast:LK(@"toast.btnAdded")];
    } else if ([act isEqualToString:@"resetPos"]) {
        [self confirm:LK(@"alert.resetPos") action:^{
            [st resetPositions];
            [st save];
            [[Presets shared] syncCurrent];
            [Pad resetPositions];
            [self toast:LK(@"toast.posReset")];
        }];
    } else if ([act isEqualToString:@"resetAll"]) {
        [self confirm:LK(@"alert.resetAll") action:^{
            [st resetAll];
            gHidden = st.hidden;
            sEditing = st.editMode;
            [Pad rebuild];
            [Pad resetPositions];
            [Pad setEditing:st.editMode];
            [self buildRows];
            [self layoutPanel];
            [self applyAll];
            [[Presets shared] syncCurrent];
            [self toast:LK(@"toast.allReset")];
        }];
    } else if ([act isEqualToString:@"about"]) {
        [About showIn:sWin.rootViewController.view];
    }
}

+ (void)showLangPicker {
    UIAlertController *ac = [UIAlertController
        alertControllerWithTitle:LK(@"settings.lang")
        message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    Settings *st = [Settings shared];
    for (NSInteger i = 0; i < 3; i++) {
        NSString *title = LangName(i);
        [ac addAction:[UIAlertAction actionWithTitle:title
            style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
                DBG(@"hud: lang %ld", (long)i);
                st.langMode = (LangMode)i;
                [st save];
                [[Presets shared] syncCurrent];
            }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.cancel")
        style:UIAlertActionStyleCancel handler:nil]];
    ac.popoverPresentationController.sourceView = sPanel;
    ac.popoverPresentationController.sourceRect = sPanel.bounds;
    [sWin.rootViewController presentViewController:ac
                                          animated:YES completion:nil];
}

+ (void)onMin { [self applyState:HUDStateBall]; }

+ (void)onMax {
    Settings *st = [Settings shared];
    HUDState next = (st.hudState == HUDStateFull)
        ? HUDStateMedium : HUDStateFull;
    [self applyState:next];
}

@end