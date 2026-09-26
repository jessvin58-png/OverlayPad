#pragma once
#import <UIKit/UIKit.h>
#import "HUD.h"
#import "Common.h"
#import "Settings.h"
#import "Presets.h"
#import "Pad.h"
#import "Style.h"
#import "Lang.h"
#import "DebugConsole.h"
#import <objc/runtime.h>

@interface OverlayWindow : UIWindow @end

extern UIWindow *sWin;
extern UIView *sBall, *sPanel, *sEditPanel;
extern UIScrollView *sContent, *sEditContent;
extern UILabel *sTitle, *sEditTitle;
extern UIView *sDropBack;
extern UIView *sDropBox;
extern UILabel *sToast;
extern BOOL sEditing;
extern BOOL gHidden;
extern BtnCfg *gEditCfg;
extern BOOL gEditIsJoy;
extern BOOL gEditPressed;
extern CGPoint sEditPanelCenter;
extern UIView *sPresetPanel;
extern UIScrollView *sPresetContent;
extern NSTimer *sSaveTimer;

@interface HUD (Internal)
+ (void)toast:(NSString *)msg;
+ (void)shake:(UIView *)v;
+ (void)scheduleSaveAndSync;
+ (void)flushSave;
+ (void)applyAll;
+ (void)applyState:(HUDState)state;
+ (void)layoutPanel;
+ (void)clampBall;
+ (void)buildPanel;
+ (void)buildRows;
+ (NSArray *)menuSpec;
+ (void)confirm:(NSString *)title action:(void (^)(void))action;
+ (void)showDropdownAt:(UIView *)anchor
                 items:(NSArray<NSString *> *)items
               current:(NSInteger)cur
                onPick:(void (^)(NSInteger))cb;
+ (void)hideDropdown;
+ (void)onDropdownPick:(UIButton *)b;
+ (UIView *)rowWithLabel:(NSString *)title
                       y:(CGFloat)y h:(CGFloat)h w:(CGFloat)w;
+ (UIView *)makeSliderRow:(NSString *)title
                      key:(NSString *)key
                      min:(CGFloat)mn
                      max:(CGFloat)mx
                    value:(CGFloat)v
                     vtag:(NSInteger)vtag
                        y:(CGFloat)y
                        w:(CGFloat)w
                      fmt:(NSString *)fmt;
+ (void)buildEditRows;
+ (void)buildPressedRows;
+ (void)showEditPanel;
+ (void)closeEditPanel;
+ (void)cleanupEditUI;
+ (void)showPresetPanel;
+ (void)hidePresetPanel;
+ (void)buildPresetRows;
+ (void)onEditButton:(NSNotification *)n;
+ (void)onEditJoy:(NSNotification *)n;
+ (void)onPanelDrag:(UIPanGestureRecognizer *)g;
+ (void)onEditPanelDrag:(UIPanGestureRecognizer *)g;
+ (void)onPresetDrag:(UIPanGestureRecognizer *)g;
+ (void)onAction:(UIButton *)b;
+ (void)showLangPicker;
+ (void)onMin;
+ (void)onMax;
+ (void)onEditTab:(UISegmentedControl *)sg;
+ (void)onStyleDropdown:(UIButton *)b;
+ (void)onEditElement:(UIButton *)b;
+ (void)onEditRapidKey:(UIButton *)b;
+ (void)onTextEnd:(UITextField *)tf;
+ (void)onPTextEnd:(UITextField *)tf;
+ (void)onEditColor:(UIButton *)b;
+ (void)onPColorTap:(UITapGestureRecognizer *)g;
+ (void)onPShape:(UISegmentedControl *)sg;
+ (void)onPDisable:(UIButton *)b;
+ (void)onEditAddColor:(UIButton *)b;
+ (void)onEditShape:(UISegmentedControl *)sg;
+ (void)onEditTurbo:(UISwitch *)sw;
+ (void)onEditRapid:(UISwitch *)sw;
+ (void)onEditDelete:(UIButton *)b;
+ (void)onFieldEnd:(UITextField *)tf;
+ (void)applyField:(UITextField *)tf;
+ (void)onSliderMoved:(UISlider *)sl;
+ (void)onEditElementTap:(UITapGestureRecognizer *)g;
+ (void)onEditRapidKeyTap:(UITapGestureRecognizer *)g;
+ (void)onEditColorTap:(UITapGestureRecognizer *)g;
+ (void)onEditAddColorTap:(UITapGestureRecognizer *)g;
+ (void)onPresetRowTap:(UITapGestureRecognizer *)g;
+ (void)onPresetMore:(UIButton *)b;
+ (void)presetRename:(Preset *)p;
+ (void)onPresetNew;
+ (void)onPresetPaste;
@end