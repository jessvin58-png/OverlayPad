#import "Lang.h"

NSString * const LangDidChangeNotification = @"LangDidChangeNotification";

extern void LangRegEn(void);
extern void LangRegZh(void);

static NSMutableDictionary<NSString *, NSDictionary *> *gTables = nil;
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

void LangRegister(NSString *code, NSDictionary *table) {
    if (!code.length || ![table isKindOfClass:[NSDictionary class]]) return;
    if (!gTables) gTables = [NSMutableDictionary dictionary];
    gTables[code] = table;
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

static NSString *curCode(void) {
    if (gMode == LangEn) return @"en";
    if (gMode == LangZh) return @"zh";
    return sysZh() ? @"zh" : @"en";
}

NSString *LK(NSString *key) {
    if (!key.length) return @"";
    if (!gTables) return key;
    NSDictionary *t = gTables[curCode()];
    NSString *v = t[key];
    if (v) return v;
    t = gTables[@"en"];
    v = t[key];
    return v ?: key;
}

NSString *LangName(LangMode m) {
    if (m == LangEn) return @"English";
    if (m == LangZh) return @"中文";
    return LK(@"lang.auto");
}

void LangRegAll(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        LangRegEn();
        LangRegZh();
    });
}