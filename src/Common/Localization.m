#import "Localization.h"

NSString * const LangDidChangeNotification = @"LangDidChangeNotification";

static LangMode gMode = LangAuto;
static BOOL gSysZhResolved = NO;
static BOOL gSysZh = NO;

static BOOL sysZh(void) {
    if (gSysZhResolved) return gSysZh;
    NSString *lang = [NSLocale preferredLanguages].firstObject ?: @"en";
    gSysZh = [lang hasPrefix:@"zh"];
    gSysZhResolved = YES;
    return gSysZh;
}

void LangSetMode(LangMode m) {
    if (gMode == m) return;
    gMode = m;
    void (^post)(void) = ^{
        [[NSNotificationCenter defaultCenter]
            postNotificationName:LangDidChangeNotification object:nil];
    };
    if ([NSThread isMainThread]) post();
    else dispatch_async(dispatch_get_main_queue(), post);
}

LangMode LangGetMode(void) { return gMode; }

NSString *L(NSString *en, NSString *zh) {
    if (gMode == LangEn) return en ?: @"";
    if (gMode == LangZh) return zh ?: en ?: @"";
    return sysZh() ? (zh ?: en ?: @"") : (en ?: @"");
}

NSString *LangName(LangMode m) {
    if (m == LangEn) return @"English";
    if (m == LangZh) return @"中文";
    return L(@"Auto", @"跟随系统");
}