#import "HUDInternal.h"

@implementation HUD (Edit)

+ (void)onEditButton:(NSNotification *)n {
    NSString *eid = n.userInfo[@"eid"];
    if (![eid isKindOfClass:[NSString class]]) return;
    BtnCfg *cfg = nil;
    for (BtnCfg *b in [Settings shared].buttons) {
        if ([b.eid isEqualToString:eid]) { cfg = b; break; }
    }
    if (!cfg) return;
    DBG(@"hud: edit btn %@", ElementLabel(cfg.elements.firstObject));
    gEditCfg = cfg;
    gEditIsJoy = NO;
    gEditPressed = NO;
    [self showEditPanel];
}

+ (void)onEditJoy:(NSNotification *)n {
    DBG(@"hud: edit joy");
    gEditCfg = nil;
    gEditIsJoy = YES;
    gEditPressed = NO;
    [self showEditPanel];
}

+ (void)cleanupEditUI {
    [self hideDropdown];
    [sEditPanel removeFromSuperview];
    sEditPanel = nil;
    sEditContent = nil;
}

+ (void)closeEditPanel {
    [self cleanupEditUI];
    gEditCfg = nil;
    gEditIsJoy = NO;
    gEditPressed = NO;
    [[Presets shared] syncCurrent];
    DBG(@"hud: edit closed");
}

+ (void)showEditPanel {
    [self cleanupEditUI];
    CGRect scr = [UIScreen mainScreen].bounds;
    CGFloat w = MIN(360, scr.size.width - 40);
    CGFloat h = MIN(620, scr.size.height - 100);
    if (sEditPanelCenter.x == 0 && sEditPanelCenter.y == 0) {
        sEditPanelCenter = CGPointMake(scr.size.width / 2,
                                       scr.size.height / 2);
    }
    sEditPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    sEditPanel.center = sEditPanelCenter;
    sEditPanel.backgroundColor = PanelBg();
    sEditPanel.layer.cornerRadius = 18;
    sEditPanel.layer.masksToBounds = YES;
    [sWin.rootViewController.view addSubview:sEditPanel];

    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 44)];
    bar.backgroundColor = PanelBarBg();
    bar.tag = 901;
    bar.userInteractionEnabled = YES;
    [sEditPanel addSubview:bar];

    UIPanGestureRecognizer *ed = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(onEditPanelDrag:)];
    ed.cancelsTouchesInView = NO;
    [bar addGestureRecognizer:ed];

    sEditTitle = [[UILabel alloc]
        initWithFrame:CGRectMake(16, 0, w - 60, 44)];
    sEditTitle.tag = 902;
    sEditTitle.text = gEditIsJoy
        ? LK(@"edit.titleJoy") : LK(@"edit.titleBtn");
    sEditTitle.textColor = PanelText();
    sEditTitle.font = [UIFont boldSystemFontOfSize:16];
    [bar addSubview:sEditTitle];

    UIButton *close = PanelIconButton(@"xmark", @"X");
    close.tag = 903;
    close.frame = CGRectMake(w - 42, 8, 28, 28);
    [close addTarget:self action:@selector(closeEditPanel)
        forControlEvents:UIControlEventTouchUpInside];
    [bar addSubview:close];

    CGFloat topY = 44;
    if (!gEditIsJoy && gEditCfg) {
        UISegmentedControl *tab = [[UISegmentedControl alloc]
            initWithItems:@[LK(@"edit.tabNormal"), LK(@"edit.tabPressed")]];
        tab.tag = 910;
        tab.frame = CGRectMake(16, 50, w - 32, 30);
        tab.selectedSegmentIndex = gEditPressed ? 1 : 0;
        [tab addTarget:self action:@selector(onEditTab:)
            forControlEvents:UIControlEventValueChanged];
        [sEditPanel addSubview:tab];
        topY = 88;
    }

    sEditContent = [[UIScrollView alloc] initWithFrame:
        CGRectMake(0, topY, w, h - topY)];
    sEditContent.tag = 904;
    sEditContent.alwaysBounceVertical = YES;
    sEditContent.showsVerticalScrollIndicator = NO;
    [sEditPanel addSubview:sEditContent];

    [self buildEditRows];
}

+ (void)onEditTab:(UISegmentedControl *)sg {
    if (gEditIsJoy || !gEditCfg) return;
    gEditPressed = (sg.selectedSegmentIndex == 1);
    DBG(@"hud: edit tab %@", gEditPressed ? @"pressed" : @"normal");
    if (gEditPressed && !gEditCfg.hasPressed) {
        gEditCfg.hasPressed = YES;
        gEditCfg.pSize = gEditCfg.size;
        gEditCfg.pAlpha = MAX(0.15, gEditCfg.alpha * 0.7);
        gEditCfg.pColor = gEditCfg.color;
        gEditCfg.pShape = gEditCfg.shape;
        gEditCfg.pText = gEditCfg.text;
        [[Settings shared] save];
    }
    [self buildEditRows];
}

+ (void)onEditPanelDrag:(UIPanGestureRecognizer *)g {
    if (!sEditPanel) return;
    CGPoint t = [g translationInView:sEditPanel.superview];
    if (g.state == UIGestureRecognizerStateBegan ||
        g.state == UIGestureRecognizerStateChanged) {
        sEditPanel.center = CGPointMake(sEditPanel.center.x + t.x,
                                        sEditPanel.center.y + t.y);
        [g setTranslation:CGPointZero inView:sEditPanel.superview];
    } else if (g.state == UIGestureRecognizerStateEnded) {
        sEditPanelCenter = sEditPanel.center;
    }
}

+ (void)buildEditRows {
    for (UIView *v in sEditContent.subviews) [v removeFromSuperview];
    if (gEditPressed && !gEditIsJoy && gEditCfg) {
        [self buildPressedRows];
        return;
    }
    Settings *st = [Settings shared];
    CGFloat w = sEditPanel.bounds.size.width;
    CGFloat y = 8;

    if (!gEditIsJoy) {
        UIView *row = [self rowWithLabel:LK(@"edit.elements")
                                       y:y h:76 w:w];
        UIScrollView *hs = [[UIScrollView alloc] init];
        hs.frame = CGRectMake(16, 28, w - 32, 40);
        hs.showsHorizontalScrollIndicator = NO;
        hs.delaysContentTouches = NO;
        NSArray *els = GamepadElements();
        NSArray *cur = gEditCfg.elements ?: @[];
        CGFloat x = 0;
        for (NSInteger i = 0; i < (NSInteger)els.count; i++) {
            NSString *eid = els[i];
            BOOL sel = [cur containsObject:eid];
            UIButton *chip = [UIButton buttonWithType:UIButtonTypeSystem];
            chip.frame = CGRectMake(x, 4, 60, 32);
            [chip setTitle:ElementLabel(eid) forState:UIControlStateNormal];
            UIColor *cc = sel ? [UIColor blackColor] : PanelText();
            [chip setTitleColor:cc forState:UIControlStateNormal];
            chip.titleLabel.font = [UIFont boldSystemFontOfSize:13];
            chip.backgroundColor = sel ? [UIColor whiteColor] : PanelFieldBg();
            chip.layer.cornerRadius = 8;
            chip.tag = i;
            UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc]
                initWithTarget:self action:@selector(onEditElementTap:)];
            [t requireGestureRecognizerToFail:hs.panGestureRecognizer];
            [chip addGestureRecognizer:t];
            [hs addSubview:chip];
            x += 64;
        }
        hs.contentSize = CGSizeMake(x, 40);
        [row addSubview:hs];
        [sEditContent addSubview:row];
        y += 80;
    }

    if (!gEditIsJoy) {
        UIView *row = [self rowWithLabel:LK(@"edit.text") y:y h:56 w:w];
        UITextField *tf = [[UITextField alloc] init];
        tf.frame = CGRectMake(16, 26, w - 32, 26);
        tf.text = gEditCfg.text ?: @"";
        tf.placeholder = LK(@"edit.textPh");
        tf.textColor = PanelText();
        tf.backgroundColor = PanelFieldBg();
        tf.layer.cornerRadius = 6;
        tf.font = [UIFont systemFontOfSize:13];
        tf.textAlignment = NSTextAlignmentCenter;
        tf.returnKeyType = UIReturnKeyDone;
        [tf addTarget:self action:@selector(onTextEnd:)
            forControlEvents:UIControlEventEditingDidEnd |
                             UIControlEventEditingDidEndOnExit];
        [row addSubview:tf];
        [sEditContent addSubview:row];
        y += 60;
    }

    {
        UIView *row = [self rowWithLabel:LK(@"edit.color") y:y h:76 w:w];
        UIScrollView *hs = [[UIScrollView alloc] init];
        hs.frame = CGRectMake(16, 28, w - 32, 40);
        hs.showsHorizontalScrollIndicator = NO;
        hs.delaysContentTouches = NO;
        NSArray *colors = [st allColors];
        NSInteger cur = gEditIsJoy ? st.joyColor : gEditCfg.color;
        CGFloat x = 0;
        for (NSInteger i = 0; i < (NSInteger)colors.count; i++) {
            UIButton *dot = [UIButton buttonWithType:UIButtonTypeCustom];
            dot.frame = CGRectMake(x, 6, 28, 28);
            dot.backgroundColor = colors[i];
            dot.layer.cornerRadius = 14;
            dot.layer.borderWidth = (i == cur) ? 3 : 1;
            UIColor *bc = (i == cur) ? PanelAccent() : PanelBorder();
            dot.layer.borderColor = bc.CGColor;
            dot.tag = i;
            UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc]
                initWithTarget:self action:@selector(onEditColorTap:)];
            [t requireGestureRecognizerToFail:hs.panGestureRecognizer];
            [dot addGestureRecognizer:t];
            [hs addSubview:dot];
            x += 36;
        }
        UIButton *add = [UIButton buttonWithType:UIButtonTypeSystem];
        add.frame = CGRectMake(x, 6, 28, 28);
        [add setTitle:@"+" forState:UIControlStateNormal];
        [add setTitleColor:PanelText() forState:UIControlStateNormal];
        add.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        add.backgroundColor = PanelFieldBg();
        add.layer.cornerRadius = 14;
        UITapGestureRecognizer *ta = [[UITapGestureRecognizer alloc]
            initWithTarget:self action:@selector(onEditAddColorTap:)];
        [ta requireGestureRecognizerToFail:hs.panGestureRecognizer];
        [add addGestureRecognizer:ta];
        [hs addSubview:add];
        hs.contentSize = CGSizeMake(x + 36, 40);
        [row addSubview:hs];
        [sEditContent addSubview:row];
        y += 80;
    }

    {
        CGFloat mnS = gEditIsJoy ? 60 : 40;
        CGFloat mxS = gEditIsJoy ? 260 : 140;
        CGFloat vS = gEditIsJoy ? st.joySize : gEditCfg.size;
        UIView *row = [self makeSliderRow:LK(@"edit.size")
            key:@"size" min:mnS max:mxS value:vS
            vtag:911 y:y w:w fmt:@"%.0f"];
        [sEditContent addSubview:row];
        y += 60;
    }

    {
        CGFloat vA = gEditIsJoy ? st.joyAlpha : gEditCfg.alpha;
        UIView *row = [self makeSliderRow:LK(@"edit.opacity")
            key:@"alpha" min:0.15 max:1.0 value:vA
            vtag:912 y:y w:w fmt:@"%.2f"];
        [sEditContent addSubview:row];
        y += 60;
    }

    if (gEditIsJoy) {
        UIView *row = [self makeSliderRow:LK(@"edit.deadzone")
            key:@"deadzone" min:0.0 max:0.40 value:st.joyDeadzone
            vtag:913 y:y w:w fmt:@"%.2f"];
        [sEditContent addSubview:row];
        y += 60;
        UIView *row2 = [self makeSliderRow:LK(@"edit.curve")
            key:@"curve" min:0.5 max:2.5 value:st.joyCurve
            vtag:914 y:y w:w fmt:@"%.2f"];
        [sEditContent addSubview:row2];
        y += 60;
    }

    {
        UIView *row = [self rowWithLabel:LK(@"edit.style") y:y h:56 w:w];
        UIButton *dd = [UIButton buttonWithType:UIButtonTypeSystem];
        dd.frame = CGRectMake(16, 26, w - 32, 26);
        NSString *curName = LK(@"common.default");
        if (gEditIsJoy) {
            Skin *s = [Skin joyStyleBy:st.joyStyle];
            if (s) curName = LK(s.en);
        } else {
            Skin *s = [Skin btnStyleBy:gEditCfg.style];
            if (s) curName = LK(s.en);
        }
        NSString *dt = [NSString stringWithFormat:@"   %@   ▼", curName];
        [dd setTitle:dt forState:UIControlStateNormal];
        [dd setTitleColor:PanelText() forState:UIControlStateNormal];
        dd.titleLabel.font = [UIFont systemFontOfSize:13];
        dd.contentHorizontalAlignment =
            UIControlContentHorizontalAlignmentLeft;
        dd.backgroundColor = PanelFieldBg();
        dd.layer.cornerRadius = 6;
        objc_setAssociatedObject(dd, "kind",
            gEditIsJoy ? @"joy" : @"btn", OBJC_ASSOCIATION_COPY);
        [dd addTarget:self action:@selector(onStyleDropdown:)
            forControlEvents:UIControlEventTouchUpInside];
        [row addSubview:dd];
        [sEditContent addSubview:row];
        y += 60;
    }

    if (!gEditIsJoy) {
        UIView *row = [self rowWithLabel:LK(@"edit.shape") y:y h:62 w:w];
        UISegmentedControl *sg = [[UISegmentedControl alloc]
            initWithItems:@[LK(@"edit.square"), LK(@"edit.circle")]];
        sg.frame = CGRectMake(16, 26, w - 32, 28);
        sg.selectedSegmentIndex = gEditCfg.shape;
        [sg addTarget:self action:@selector(onEditShape:)
            forControlEvents:UIControlEventValueChanged];
        [row addSubview:sg];
        [sEditContent addSubview:row];
        y += 66;

        UIView *r1 = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 48)];
        UILabel *l1 = [[UILabel alloc]
            initWithFrame:CGRectMake(16, 0, w - 80, 48)];
        l1.text = LK(@"edit.turbo");
        l1.textColor = PanelSubText();
        l1.font = [UIFont systemFontOfSize:14];
        [r1 addSubview:l1];
        UISwitch *sw1 = [[UISwitch alloc] init];
        sw1.frame = CGRectMake(w - 66, 8, 51, 31);
        sw1.on = gEditCfg.turbo;
        [sw1 addTarget:self action:@selector(onEditTurbo:)
            forControlEvents:UIControlEventValueChanged];
        [r1 addSubview:sw1];
        [sEditContent addSubview:r1];
        y += 52;

        UIView *r2 = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 48)];
        UILabel *l2 = [[UILabel alloc]
            initWithFrame:CGRectMake(16, 0, w - 80, 48)];
        l2.text = LK(@"edit.rapidFire");
        l2.textColor = PanelSubText();
        l2.font = [UIFont systemFontOfSize:14];
        [r2 addSubview:l2];
        UISwitch *sw2 = [[UISwitch alloc] init];
        sw2.frame = CGRectMake(w - 66, 8, 51, 31);
        sw2.on = gEditCfg.rapidFire;
        [sw2 addTarget:self action:@selector(onEditRapid:)
            forControlEvents:UIControlEventValueChanged];
        [r2 addSubview:sw2];
        [sEditContent addSubview:r2];
        y += 52;
    }

    if (!gEditIsJoy && gEditCfg.rapidFire) {
        UIView *row = [self makeSliderRow:LK(@"edit.rapidInterval")
            key:@"interval" min:0.02 max:1.0 value:gEditCfg.rapidInterval
            vtag:915 y:y w:w fmt:@"%.2f"];
        [sEditContent addSubview:row];
        y += 60;

        UIView *rk = [self rowWithLabel:LK(@"edit.rapidKeys")
                                     y:y h:76 w:w];
        UIScrollView *hs = [[UIScrollView alloc] init];
        hs.frame = CGRectMake(16, 28, w - 32, 40);
        hs.showsHorizontalScrollIndicator = NO;
        hs.delaysContentTouches = NO;
        NSArray *els = GamepadElements();
        NSArray *cur = gEditCfg.rapidKeys ?: @[];
        CGFloat x = 0;
        for (NSInteger i = 0; i < (NSInteger)els.count; i++) {
            NSString *eid = els[i];
            BOOL sel = [cur containsObject:eid];
            UIButton *chip = [UIButton buttonWithType:UIButtonTypeSystem];
            chip.frame = CGRectMake(x, 4, 60, 32);
            [chip setTitle:ElementLabel(eid) forState:UIControlStateNormal];
            UIColor *cc = sel ? [UIColor blackColor] : PanelText();
            [chip setTitleColor:cc forState:UIControlStateNormal];
            chip.titleLabel.font = [UIFont boldSystemFontOfSize:13];
            chip.backgroundColor = sel ? [UIColor whiteColor] : PanelFieldBg();
            chip.layer.cornerRadius = 8;
            chip.tag = i;
            UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc]
                initWithTarget:self action:@selector(onEditRapidKeyTap:)];
            [t requireGestureRecognizerToFail:hs.panGestureRecognizer];
            [chip addGestureRecognizer:t];
            [hs addSubview:chip];
            x += 64;
        }
        hs.contentSize = CGSizeMake(x, 40);
        [rk addSubview:hs];
        [sEditContent addSubview:rk];
        y += 80;
    }

    if (!gEditIsJoy) {
        CGFloat dw = 160;
        UIButton *del = [UIButton buttonWithType:UIButtonTypeSystem];
        del.frame = CGRectMake((w - dw) / 2, y, dw, 40);
        [del setTitle:LK(@"edit.deleteBtn")
            forState:UIControlStateNormal];
        [del setTitleColor:[UIColor whiteColor]
                forState:UIControlStateNormal];
        del.backgroundColor = [UIColor systemRedColor];
        del.layer.cornerRadius = 8;
        [del addTarget:self action:@selector(onEditDelete:)
            forControlEvents:UIControlEventTouchUpInside];
        [sEditContent addSubview:del];
        y += 48;
    }
    sEditContent.contentSize = CGSizeMake(w, y + 8);
}

+ (void)buildPressedRows {
    Settings *st = [Settings shared];
    CGFloat w = sEditPanel.bounds.size.width;
    CGFloat y = 8;

    {
        UIView *row = [self rowWithLabel:LK(@"edit.pText") y:y h:56 w:w];
        UITextField *tf = [[UITextField alloc] init];
        tf.frame = CGRectMake(16, 26, w - 32, 26);
        tf.text = gEditCfg.pText ?: @"";
        tf.placeholder = LK(@"edit.pTextPh");
        tf.textColor = PanelText();
        tf.backgroundColor = PanelFieldBg();
        tf.layer.cornerRadius = 6;
        tf.font = [UIFont systemFontOfSize:13];
        tf.textAlignment = NSTextAlignmentCenter;
        tf.returnKeyType = UIReturnKeyDone;
        [tf addTarget:self action:@selector(onPTextEnd:)
            forControlEvents:UIControlEventEditingDidEnd |
                             UIControlEventEditingDidEndOnExit];
        [row addSubview:tf];
        [sEditContent addSubview:row];
        y += 60;
    }

    {
        UIView *row = [self rowWithLabel:LK(@"edit.pColor") y:y h:76 w:w];
        UIScrollView *hs = [[UIScrollView alloc] init];
        hs.frame = CGRectMake(16, 28, w - 32, 40);
        hs.showsHorizontalScrollIndicator = NO;
        hs.delaysContentTouches = NO;
        NSArray *colors = [st allColors];
        NSInteger cur = gEditCfg.pColor;
        CGFloat x = 0;
        for (NSInteger i = 0; i < (NSInteger)colors.count; i++) {
            UIButton *dot = [UIButton buttonWithType:UIButtonTypeCustom];
            dot.frame = CGRectMake(x, 6, 28, 28);
            dot.backgroundColor = colors[i];
            dot.layer.cornerRadius = 14;
            dot.layer.borderWidth = (i == cur) ? 3 : 1;
            UIColor *bc = (i == cur) ? PanelAccent() : PanelBorder();
            dot.layer.borderColor = bc.CGColor;
            dot.tag = i;
            UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc]
                initWithTarget:self action:@selector(onPColorTap:)];
            [t requireGestureRecognizerToFail:hs.panGestureRecognizer];
            [dot addGestureRecognizer:t];
            [hs addSubview:dot];
            x += 36;
        }
        hs.contentSize = CGSizeMake(x, 40);
        [row addSubview:hs];
        [sEditContent addSubview:row];
        y += 80;
    }

    {
        UIView *row = [self makeSliderRow:LK(@"edit.pSize")
            key:@"psize" min:40 max:140 value:gEditCfg.pSize
            vtag:921 y:y w:w fmt:@"%.0f"];
        [sEditContent addSubview:row];
        y += 60;
    }

    {
        UIView *row = [self makeSliderRow:LK(@"edit.pOpacity")
            key:@"palpha" min:0.15 max:1.0 value:gEditCfg.pAlpha
            vtag:922 y:y w:w fmt:@"%.2f"];
        [sEditContent addSubview:row];
        y += 60;
    }

    {
        UIView *row = [self rowWithLabel:LK(@"edit.pShape") y:y h:62 w:w];
        UISegmentedControl *sg = [[UISegmentedControl alloc]
            initWithItems:@[LK(@"edit.square"), LK(@"edit.circle")]];
        sg.frame = CGRectMake(16, 26, w - 32, 28);
        sg.selectedSegmentIndex = gEditCfg.pShape;
        [sg addTarget:self action:@selector(onPShape:)
            forControlEvents:UIControlEventValueChanged];
        [row addSubview:sg];
        [sEditContent addSubview:row];
        y += 66;
    }

    {
        UIButton *del = [UIButton buttonWithType:UIButtonTypeSystem];
        del.frame = CGRectMake(16, y, w - 32, 40);
        [del setTitle:LK(@"edit.pDisable")
            forState:UIControlStateNormal];
        [del setTitleColor:[UIColor whiteColor]
                forState:UIControlStateNormal];
        del.backgroundColor = [UIColor systemRedColor];
        del.layer.cornerRadius = 8;
        [del addTarget:self action:@selector(onPDisable:)
            forControlEvents:UIControlEventTouchUpInside];
        [sEditContent addSubview:del];
        y += 48;
    }
    sEditContent.contentSize = CGSizeMake(w, y + 8);
}

+ (void)onStyleDropdown:(UIButton *)b {
    BOOL isJoy = [objc_getAssociatedObject(b, "kind") isEqualToString:@"joy"];
    NSArray<Skin *> *list = isJoy ? [Skin joyStyles] : [Skin btnStyles];
    if (list.count == 0) {
        [self toast:LK(@"err.noStyles")];
        return;
    }
    Settings *st = [Settings shared];
    NSInteger curIdx = isJoy ? st.joyStyle : (gEditCfg ? gEditCfg.style : 1);
    NSMutableArray *names = [NSMutableArray array];
    NSInteger cur = 0;
    for (NSInteger i = 0; i < (NSInteger)list.count; i++) {
        Skin *s = list[i];
        [names addObject:LK(s.en)];
        if (s.idx == curIdx) cur = i;
    }
    __weak typeof(self) weakSelf = self;
    [self showDropdownAt:b items:names current:cur onPick:^(NSInteger i) {
        if (i < 0 || i >= (NSInteger)list.count) return;
        Skin *picked = list[i];
        DBG(@"hud: style %@ idx=%ld", picked.en, (long)picked.idx);
        if (isJoy) st.joyStyle = picked.idx;
        else if (gEditCfg) gEditCfg.style = picked.idx;
        [st save];
        [[Presets shared] syncCurrent];
        [Pad apply];
        [weakSelf buildEditRows];
    }];
}

+ (void)onEditElementTap:(UITapGestureRecognizer *)g {
    [self onEditElement:(UIButton *)g.view];
}
+ (void)onEditRapidKeyTap:(UITapGestureRecognizer *)g {
    [self onEditRapidKey:(UIButton *)g.view];
}
+ (void)onEditColorTap:(UITapGestureRecognizer *)g {
    [self onEditColor:(UIButton *)g.view];
}
+ (void)onEditAddColorTap:(UITapGestureRecognizer *)g {
    [self onEditAddColor:(UIButton *)g.view];
}

+ (void)onPColorTap:(UITapGestureRecognizer *)g {
    if (!gEditCfg) return;
    gEditCfg.pColor = g.view.tag;
    DBG(@"hud: pColor %ld", (long)g.view.tag);
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
    [self buildEditRows];
}

+ (void)onEditElement:(UIButton *)b {
    if (gEditIsJoy || !gEditCfg) return;
    NSArray *els = GamepadElements();
    if (b.tag < 0 || b.tag >= (NSInteger)els.count) return;
    NSString *e = els[b.tag];
    NSMutableArray *cur =
        [NSMutableArray arrayWithArray:gEditCfg.elements ?: @[]];
    if ([cur containsObject:e]) {
        if (cur.count <= 1) {
            [self toast:LK(@"err.atLeastOne")];
            return;
        }
        [cur removeObject:e];
    } else {
        [cur addObject:e];
    }
    gEditCfg.elements = cur;
    DBG(@"hud: elements %@", [cur componentsJoinedByString:@"+"]);
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
    [Pad apply];
    [self buildEditRows];
}

+ (void)onEditRapidKey:(UIButton *)b {
    if (gEditIsJoy || !gEditCfg) return;
    NSArray *els = GamepadElements();
    if (b.tag < 0 || b.tag >= (NSInteger)els.count) return;
    NSString *e = els[b.tag];
    NSMutableArray *cur =
        [NSMutableArray arrayWithArray:gEditCfg.rapidKeys ?: @[]];
    if ([cur containsObject:e]) [cur removeObject:e];
    else [cur addObject:e];
    gEditCfg.rapidKeys = cur;
    DBG(@"hud: rapidKeys %@", [cur componentsJoinedByString:@"+"]);
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
    [self buildEditRows];
}

+ (void)onTextEnd:(UITextField *)tf {
    if (gEditIsJoy || !gEditCfg) return;
    gEditCfg.text = tf.text ?: @"";
    DBG(@"hud: text '%@'", gEditCfg.text);
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
    [Pad apply];
}

+ (void)onPTextEnd:(UITextField *)tf {
    if (!gEditCfg) return;
    gEditCfg.pText = tf.text ?: @"";
    DBG(@"hud: pText '%@'", gEditCfg.pText);
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
}

+ (void)onEditColor:(UIButton *)b {
    Settings *st = [Settings shared];
    if (gEditIsJoy) st.joyColor = b.tag;
    else if (gEditCfg) gEditCfg.color = b.tag;
    DBG(@"hud: color %ld", (long)b.tag);
    [st save];
    [[Presets shared] syncCurrent];
    [Pad apply];
    [self buildEditRows];
}

+ (void)onPShape:(UISegmentedControl *)sg {
    if (!gEditCfg) return;
    gEditCfg.pShape = (BtnShape)sg.selectedSegmentIndex;
    DBG(@"hud: pShape %ld", (long)sg.selectedSegmentIndex);
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
}

+ (void)onPDisable:(UIButton *)b {
    if (!gEditCfg) return;
    gEditCfg.hasPressed = NO;
    gEditPressed = NO;
    DBG(@"hud: pDisable");
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
    UISegmentedControl *tab = [sEditPanel viewWithTag:910];
    if (tab) tab.selectedSegmentIndex = 0;
    [self buildEditRows];
}

+ (void)onEditAddColor:(UIButton *)b {
    UIAlertController *ac = [UIAlertController
        alertControllerWithTitle:LK(@"alert.customColor")
        message:LK(@"alert.customColorMsg")
        preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"#FF8800";
        tf.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        tf.keyboardType = UIKeyboardTypeASCIICapable;
    }];
    __weak typeof(self) weakSelf = self;
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"common.cancel")
        style:UIAlertActionStyleCancel handler:nil]];
    [ac addAction:[UIAlertAction actionWithTitle:LK(@"alert.add")
        style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            UITextField *tf = ac.textFields.firstObject;
            NSString *hex = tf.text;
            Settings *st = [Settings shared];
            NSInteger idx = [st addCustomColor:hex];
            if (idx < 0) {
                NSString *m = [NSString stringWithFormat:
                    LK(@"alert.invalidHex"), hex ?: @""];
                DBG(@"hud: bad hex '%@'", hex ?: @"");
                [weakSelf toast:m];
                return;
            }
            DBG(@"hud: add color '%@' idx=%ld", hex ?: @"", (long)idx);
            if (gEditIsJoy) st.joyColor = idx;
            else if (gEditCfg) gEditCfg.color = idx;
            [st save];
            [[Presets shared] syncCurrent];
            [Pad apply];
            [weakSelf buildEditRows];
            [weakSelf toast:LK(@"toast.colorAdded")];
        }]];
    [sWin.rootViewController presentViewController:ac
                                          animated:YES completion:nil];
}

+ (void)onEditShape:(UISegmentedControl *)sg {
    if (gEditIsJoy || !gEditCfg) return;
    gEditCfg.shape = (BtnShape)sg.selectedSegmentIndex;
    DBG(@"hud: shape %ld", (long)sg.selectedSegmentIndex);
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
    [Pad apply];
}

+ (void)onEditTurbo:(UISwitch *)sw {
    if (gEditIsJoy || !gEditCfg) return;
    gEditCfg.turbo = sw.on;
    DBG(@"hud: turbo %d", sw.on);
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
}

+ (void)onEditRapid:(UISwitch *)sw {
    if (gEditIsJoy || !gEditCfg) return;
    gEditCfg.rapidFire = sw.on;
    DBG(@"hud: rapid %d", sw.on);
    [[Settings shared] save];
    [[Presets shared] syncCurrent];
    [self buildEditRows];
}

+ (void)onEditDelete:(UIButton *)b {
    if (gEditIsJoy || !gEditCfg) return;
    BtnCfg *cfg = gEditCfg;
    __weak typeof(self) weakSelf = self;
    [self confirm:LK(@"alert.deleteBtn") action:^{
        DBG(@"hud: delete btn");
        [[Settings shared] removeButton:cfg];
        [[Settings shared] save];
        [[Presets shared] syncCurrent];
        [Pad rebuild];
        [weakSelf closeEditPanel];
        [weakSelf toast:LK(@"toast.btnRemoved")];
    }];
}

+ (void)onFieldEnd:(UITextField *)tf { [self applyField:tf]; }

+ (void)applyField:(UITextField *)tf {
    NSString *which = objc_getAssociatedObject(tf, "k");
    if (!which) return;
    CGFloat mn = [objc_getAssociatedObject(tf, "mn") floatValue];
    CGFloat mx = [objc_getAssociatedObject(tf, "mx") floatValue];
    NSString *fmt = objc_getAssociatedObject(tf, "fmt") ?: @"%.2f";
    Settings *st = [Settings shared];
    CGFloat cur = 0;
    if ([which isEqualToString:@"size"])
        cur = gEditIsJoy ? st.joySize : (gEditCfg ? gEditCfg.size : 64);
    else if ([which isEqualToString:@"alpha"])
        cur = gEditIsJoy ? st.joyAlpha : (gEditCfg ? gEditCfg.alpha : 0.85);
    else if ([which isEqualToString:@"deadzone"]) cur = st.joyDeadzone;
    else if ([which isEqualToString:@"curve"]) cur = st.joyCurve;
    else if ([which isEqualToString:@"interval"])
        cur = gEditCfg ? gEditCfg.rapidInterval : 0.10;
    else if ([which isEqualToString:@"psize"])
        cur = gEditCfg ? gEditCfg.pSize : 64;
    else if ([which isEqualToString:@"palpha"])
        cur = gEditCfg ? gEditCfg.pAlpha : 0.6;

    NSString *s = tf.text ?: @"";
    s = [s stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceCharacterSet]];
    BOOL ok = s.length > 0 && ![s isEqualToString:@"."];
    NSInteger dots = 0;
    for (NSUInteger i = 0; ok && i < s.length; i++) {
        unichar c = [s characterAtIndex:i];
        if (c == '.') { if (++dots > 1) ok = NO; }
        else if (!(c >= '0' && c <= '9')) ok = NO;
    }
    CGFloat v = cur;
    BOOL clamped = NO;
    if (ok) {
        v = (CGFloat)[s doubleValue];
        if (v < mn) { v = mn; clamped = YES; }
        if (v > mx) { v = mx; clamped = YES; }
    }
    if (!ok) {
        NSString *m = [NSString stringWithFormat:LK(@"err.invalidRange"),
            (double)mn, (double)mx];
        DBG(@"hud: field %@ bad '%@'", which, s);
        [self toast:m];
        [self shake:tf];
    } else if (clamped) {
        NSString *m = [NSString stringWithFormat:LK(@"err.clamped"),
            (double)v];
        DBG(@"hud: field %@ clamp %.2f", which, (double)v);
        [self toast:m];
        [self shake:tf];
    }
    if ([which isEqualToString:@"size"]) {
        if (gEditIsJoy) st.joySize = v;
        else if (gEditCfg) gEditCfg.size = v;
    } else if ([which isEqualToString:@"alpha"]) {
        if (gEditIsJoy) st.joyAlpha = v;
        else if (gEditCfg) gEditCfg.alpha = v;
    } else if ([which isEqualToString:@"deadzone"]) st.joyDeadzone = v;
    else if ([which isEqualToString:@"curve"]) st.joyCurve = v;
    else if ([which isEqualToString:@"interval"]) {
        if (gEditCfg) gEditCfg.rapidInterval = v;
    } else if ([which isEqualToString:@"psize"]) {
        if (gEditCfg) gEditCfg.pSize = v;
    } else if ([which isEqualToString:@"palpha"]) {
        if (gEditCfg) gEditCfg.pAlpha = v;
    }
    tf.text = [NSString stringWithFormat:fmt, v];
    UIView *pv = tf.superview;
    UIView *sv = pv ? [pv viewWithTag:910] : nil;
    if ([sv isKindOfClass:[UISlider class]]) {
        UISlider *slider = (UISlider *)sv;
        slider.value = v;
    }
    [Pad apply];
    [self scheduleSaveAndSync];
}

+ (void)onSliderMoved:(UISlider *)sl {
    NSString *which = objc_getAssociatedObject(sl, "k");
    NSNumber *vtag = objc_getAssociatedObject(sl, "vt");
    Settings *st = [Settings shared];
    if ([which isEqualToString:@"size"]) {
        if (gEditIsJoy) st.joySize = sl.value;
        else if (gEditCfg) gEditCfg.size = sl.value;
    } else if ([which isEqualToString:@"alpha"]) {
        if (gEditIsJoy) st.joyAlpha = sl.value;
        else if (gEditCfg) gEditCfg.alpha = sl.value;
    } else if ([which isEqualToString:@"deadzone"]) st.joyDeadzone = sl.value;
    else if ([which isEqualToString:@"curve"]) st.joyCurve = sl.value;
    else if ([which isEqualToString:@"interval"]) {
        if (gEditCfg) gEditCfg.rapidInterval = sl.value;
    } else if ([which isEqualToString:@"psize"]) {
        if (gEditCfg) gEditCfg.pSize = sl.value;
    } else if ([which isEqualToString:@"palpha"]) {
        if (gEditCfg) gEditCfg.pAlpha = sl.value;
    }
    UIView *pv = sl.superview;
    UIView *tv = (pv && vtag) ? [pv viewWithTag:vtag.integerValue] : nil;
    if ([tv isKindOfClass:[UITextField class]]) {
        UITextField *field = (UITextField *)tv;
        NSString *fmt = objc_getAssociatedObject(field, "fmt") ?: @"%.2f";
        field.text = [NSString stringWithFormat:fmt, sl.value];
    }
    [Pad apply];
    [self scheduleSaveAndSync];
}

@end