#import <UIKit/UIKit.h>
#import "Common.h"
#import "HUD.h"
#import "Injector.h"
#import "Style.h"
#import "Lang.h"
#import "DebugConsole.h"

__attribute__((constructor))
static void boot(void) {
    DBGInit();
    DBG(@"boot: begin");
    LangRegAll();
    SkinRegAll();
    DBG(@"boot: lang=%ld skin joy=%lu btn=%lu",
        (long)LangGetMode(),
        (unsigned long)[Skin joyStyles].count,
        (unsigned long)[Skin btnStyles].count);
    dispatch_async(dispatch_get_main_queue(), ^{
        DBG(@"boot: ui queue");
        [DebugConsole setup];
        [Injector setup];
        [HUD setup];
        DBG(@"boot: done");
    });
}