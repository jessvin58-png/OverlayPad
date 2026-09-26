#import "HUDInternal.h"

UIWindow *sWin = nil;
UIView *sBall = nil, *sPanel = nil, *sEditPanel = nil;
UIScrollView *sContent = nil, *sEditContent = nil;
UILabel *sTitle = nil, *sEditTitle = nil;
UIView *sDropBack = nil;
UIView *sDropBox = nil;
UILabel *sToast = nil;
BOOL sEditing = NO;
BOOL gHidden = NO;
BtnCfg *gEditCfg = nil;
BOOL gEditIsJoy = NO;
BOOL gEditPressed = NO;
CGPoint sEditPanelCenter = {0, 0};
UIView *sPresetPanel = nil;
UIScrollView *sPresetContent = nil;
NSTimer *sSaveTimer = nil;

@implementation OverlayWindow
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    if (sWin.rootViewController.presentedViewController)
        return [super hitTest:p withEvent:e];
    UIView *hit = [super hitTest:p withEvent:e];
    if (!hit) return nil;
    if (hit == self.rootViewController.view) return nil;
    UIView *root = self.rootViewController.view;
    UIView *v = hit;
    UIView *panel = nil;
    while (v && v != root) {
        if (v == sPanel || v == sEditPanel || v == sPresetPanel ||
            v.tag == 7777) {
            panel = v; break;
        }
        v = v.superview;
    }
    if (panel && panel.superview) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (panel.superview) [panel.superview bringSubviewToFront:panel];
        });
    }
    return hit;
}
@end