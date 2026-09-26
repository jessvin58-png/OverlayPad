#import "HUD.h"
#import "HUDInternal.h"

@implementation HUD

+ (BOOL)isEditing { return sEditing; }

+ (void)setup {
    Settings *st = [Settings shared];
    CGRect scr = [UIScreen mainScreen].bounds;
    sWin = [[OverlayWindow alloc] initWithFrame:scr];
    sWin.windowLevel = UIWindowLevelNormal + 1;
    sWin.backgroundColor = [UIColor clearColor];
    sWin.rootViewController = [UIViewController new];
    sWin.hidden = NO;
    UIView *root = sWin.rootViewController.view;
    root.multipleTouchEnabled = YES;
    root.exclusiveTouch = NO;

    [[Presets shared] applyActive];
    [Pad buildIn:root];
    [self buildPanel];
    [root addSubview:sPanel];

    sBall = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
    sBall.backgroundColor = [UIColor colorWithWhite:0.10 alpha:0.92];
    sBall.layer.cornerRadius = 28;
    sBall.layer.shadowColor = [UIColor blackColor].CGColor;
    sBall.layer.shadowRadius = 8;
    sBall.layer.shadowOpacity = 0.4;
    sBall.layer.shadowOffset = CGSizeMake(0, 3);
    sBall.layer.shadowPath =
        [UIBezierPath bezierPathWithRoundedRect:sBall.bounds
                                   cornerRadius:28].CGPath;
    sBall.userInteractionEnabled = YES;
    [root addSubview:sBall];

    UIImageView *icon = [[UIImageView alloc] initWithFrame:sBall.bounds];
    icon.contentMode = UIViewContentModeCenter;
    icon.tintColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration
            configurationWithPointSize:20
                                weight:UIImageSymbolWeightRegular];
        icon.image = [UIImage systemImageNamed:@"slider.horizontal.3"
                             withConfiguration:cfg];
    }
    [sBall addSubview:icon];
    DBG(@"hud: ball icon %@", icon.image ? @"ok" : @"nil");

    UIPanGestureRecognizer *bp = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(onBallPan:)];
    bp.cancelsTouchesInView = NO;
    [sBall addGestureRecognizer:bp];

    UITapGestureRecognizer *bt = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(onBallTap:)];
    [sBall addGestureRecognizer:bt];

    UILongPressGestureRecognizer *bl = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(onBallLong:)];
    bl.minimumPressDuration = 0.7;
    bl.allowableMovement = 15;
    bl.cancelsTouchesInView = NO;
    [sBall addGestureRecognizer:bl];

    sBall.center = st.ballPos;
    [self clampBall];

    gHidden = st.hidden;

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(onRotate)
        name:UIDeviceOrientationDidChangeNotification object:nil];
    [nc addObserver:self selector:@selector(onEditButton:)
        name:@"JoyEditButton" object:nil];
    [nc addObserver:self selector:@selector(onEditJoy:)
        name:@"JoyEditJoy" object:nil];
    [nc addObserver:self selector:@selector(onLangChanged)
        name:LangDidChangeNotification object:nil];

    [self applyAll];
    DBG(@"hud: setup ballPos=%@ panelPos=%@ state=%ld hidden=%d edit=%d",
        NSStringFromCGPoint(st.ballPos), NSStringFromCGPoint(st.panelPos),
        (long)st.hudState, st.hidden, st.editMode);
}

+ (void)onLangChanged {
    if (!sWin) return;
    DBG(@"hud: lang -> %@", LangName([Settings shared].langMode));

    if (sTitle) sTitle.text = LK(@"settings.title");
    if (sContent) {
        CGFloat off = sContent.contentOffset.y;
        [self buildRows];
        [self layoutPanel];
        if (off > 0) {
            CGFloat maxY = MAX(0, sContent.contentSize.height
                                  - sContent.bounds.size.height);
            sContent.contentOffset = CGPointMake(0, MIN(off, maxY));
        }
    }

    if (sEditPanel) {
        if (sEditTitle) {
            sEditTitle.text = gEditIsJoy
                ? LK(@"edit.titleJoy") : LK(@"edit.titleBtn");
        }
        CGFloat eOff = sEditContent ? sEditContent.contentOffset.y : 0;
        [self buildEditRows];
        if (sEditContent && eOff > 0) {
            CGFloat maxY = MAX(0, sEditContent.contentSize.height
                                  - sEditContent.bounds.size.height);
            sEditContent.contentOffset = CGPointMake(0, MIN(eOff, maxY));
        }
    }

    if (sPresetPanel) {
        [self hidePresetPanel];
        [self showPresetPanel];
    }
}

+ (void)applyAll {
    if (!sPanel || !sBall) return;
    Settings *st = [Settings shared];
    HUDState state = st.hudState;
    DBG(@"hud: applyAll state=%ld hidden=%d edit=%d",
        (long)state, gHidden, st.editMode);
    if (gHidden) {
        sBall.hidden = NO;
        sPanel.hidden = YES;
        [Pad setVisible:NO];
        sEditing = NO;
        [Pad setEditing:NO];
        [self closeEditPanel];
        return;
    }
    [Pad setVisible:YES];
    if (state == HUDStateBall) {
        sBall.hidden = NO;
        sPanel.hidden = YES;
        sEditing = NO;
        [Pad setEditing:NO];
        [self closeEditPanel];
    } else {
        sBall.hidden = YES;
        sPanel.hidden = NO;
        sEditing = st.editMode;
        [Pad setEditing:st.editMode];
        [self layoutPanel];
    }
}

+ (void)applyState:(HUDState)state {
    Settings *st = [Settings shared];
    if (st.hudState == state) return;
    DBG(@"hud: applyState %ld -> %ld", (long)st.hudState, (long)state);
    st.hudState = state;
    [st save];
    [[Presets shared] syncCurrent];
    [self applyAll];
}

+ (void)onBallTap:(UITapGestureRecognizer *)g {
    if (gHidden) {
        gHidden = NO;
        Settings *st = [Settings shared];
        st.hidden = NO;
        [st save];
        [[Presets shared] syncCurrent];
        DBG(@"hud: ball tap, un-hide");
        [self applyAll];
    }
    DBG(@"hud: ball tap");
    [self applyState:HUDStateMedium];
}

+ (void)onBallLong:(UILongPressGestureRecognizer *)g {
    if (g.state != UIGestureRecognizerStateBegan) return;
    gHidden = !gHidden;
    Settings *st = [Settings shared];
    st.hidden = gHidden;
    [st save];
    [[Presets shared] syncCurrent];
    [self applyAll];
    DBG(@"hud: hidden -> %d", gHidden);
    [self toast:gHidden ? LK(@"toast.hidden") : LK(@"toast.shown")];
}

+ (void)onBallPan:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:sBall.superview];
    if (g.state == UIGestureRecognizerStateBegan) {
        sBall.layer.shouldRasterize = YES;
        sBall.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    if (g.state == UIGestureRecognizerStateBegan ||
        g.state == UIGestureRecognizerStateChanged) {
        sBall.center = CGPointMake(sBall.center.x + t.x,
                                   sBall.center.y + t.y);
        [g setTranslation:CGPointZero inView:sBall.superview];
    } else if (g.state == UIGestureRecognizerStateEnded ||
               g.state == UIGestureRecognizerStateCancelled) {
        sBall.layer.shouldRasterize = NO;
        [self clampBall];
        Settings *st = [Settings shared];
        st.ballPos = sBall.center;
        [st save];
        [[Presets shared] syncCurrent];
        DBG(@"hud: ball %@", NSStringFromCGPoint(st.ballPos));
    }
}

+ (void)clampBall {
    if (!sBall) return;
    CGRect scr = [UIScreen mainScreen].bounds;
    CGFloat r = sBall.bounds.size.width / 2;
    CGFloat x = MAX(r + 8, MIN(scr.size.width - r - 8, sBall.center.x));
    CGFloat y = MAX(r + 8, MIN(scr.size.height - r - 8, sBall.center.y));
    sBall.center = CGPointMake(x, y);
}

+ (void)onRotate {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!sWin) return;
        sWin.frame = [UIScreen mainScreen].bounds;
        Settings *st = [Settings shared];
        if (!gHidden && st.hudState != HUDStateBall) [self layoutPanel];

        if (sEditPanel) {
            CGFloat w = MIN(360, sWin.bounds.size.width - 40);
            CGFloat h = MIN(620, sWin.bounds.size.height - 100);
            sEditPanel.bounds = CGRectMake(0, 0, w, h);
            sEditPanel.center = CGPointMake(sWin.bounds.size.width / 2,
                                            sWin.bounds.size.height / 2);
            sEditPanelCenter = sEditPanel.center;
            UIView *bar = [sEditPanel viewWithTag:901];
            bar.frame = CGRectMake(0, 0, w, 44);
            sEditTitle.frame = CGRectMake(16, 0, w - 60, 44);
            UIButton *close = (UIButton *)[bar viewWithTag:903];
            close.frame = CGRectMake(w - 42, 8, 28, 28);
            UISegmentedControl *tab = [sEditPanel viewWithTag:910];
            CGFloat topY = 44;
            if (tab) {
                tab.frame = CGRectMake(16, 50, w - 32, 30);
                topY = 88;
            }
            sEditContent.frame = CGRectMake(0, topY, w, h - topY);
            [self buildEditRows];
        }

        if (sPresetPanel) {
            [self hidePresetPanel];
            [self showPresetPanel];
        }

        [self clampBall];
        DBG(@"hud: rotate");
    });
}

@end