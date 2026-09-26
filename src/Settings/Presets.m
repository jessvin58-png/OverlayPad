#import "Presets.h"
#import "Common.h"
#import "DebugConsole.h"
#import "DefaultPreset.h"
#import <string.h>

static NSString *presetsDir(void) {
    NSString *docs = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (!docs) docs = NSTemporaryDirectory();
    NSString *dir = [docs stringByAppendingPathComponent:@"OverlayPad"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    return dir;
}

static NSString *presetsFile(void) {
    return [presetsDir() stringByAppendingPathComponent:@"presets.json"];
}

@implementation Preset

+ (instancetype)fromDict:(NSDictionary *)d {
    Preset *p = [Preset new];
    p.pid = [d[@"id"] isKindOfClass:[NSString class]]
        ? d[@"id"] : [[NSUUID UUID] UUIDString];
    p.name = [d[@"name"] isKindOfClass:[NSString class]]
        ? d[@"name"] : @"";
    p.created = [d[@"created"] doubleValue];
    p.modified = [d[@"modified"] doubleValue];
    p.data = [d[@"data"] isKindOfClass:[NSDictionary class]]
        ? d[@"data"] : @{};
    return p;
}

- (NSDictionary *)toDict {
    return @{
        @"id": self.pid ?: @"",
        @"name": self.name ?: @"",
        @"created": @(self.created),
        @"modified": @(self.modified),
        @"data": self.data ?: @{},
    };
}

- (NSDictionary *)toExportDict {
    NSString *outName = [self isBuiltin]
        ? LK(@"common.default") : (self.name ?: @"");
    return @{
        @"app": @"OverlayPad",
        @"schema": @1,
        @"preset": @{
            @"name": outName,
            @"data": self.data ?: @{},
        },
    };
}

+ (instancetype)fromExportDict:(NSDictionary *)d {
    if (![d isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *pr = d[@"preset"];
    if (![pr isKindOfClass:[NSDictionary class]]) return nil;
    NSDictionary *data = pr[@"data"];
    if (![data isKindOfClass:[NSDictionary class]]) return nil;

    Preset *p = [Preset new];
    p.pid = [[NSUUID UUID] UUIDString];
    p.name = [pr[@"name"] isKindOfClass:[NSString class]]
        ? pr[@"name"] : @"";
    p.created = [[NSDate date] timeIntervalSince1970];
    p.modified = p.created;
    p.data = data;
    return p;
}

- (BOOL)isBuiltin {
    return [self.pid isEqualToString:@"default"];
}

- (NSString *)displayName {
    if ([self isBuiltin]) return LK(@"common.default");
    if (self.name.length) return self.name;
    return LK(@"common.untitled");
}

@end

@implementation Presets {
    NSMutableArray<Preset *> *_list;
    NSString *_activeId;
}

+ (instancetype)shared {
    static Presets *s;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [Presets new]; [s load]; });
    return s;
}

- (instancetype)init {
    if (self = [super init]) _list = [NSMutableArray array];
    return self;
}

- (void)load {
    BOOL needsSave = NO;

    NSData *data = [NSData dataWithContentsOfFile:presetsFile()];
    if (data) {
        NSError *err = nil;
        id obj = [NSJSONSerialization JSONObjectWithData:data
                                                 options:0
                                                   error:&err];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSArray *arr = obj[@"presets"];
            if ([arr isKindOfClass:[NSArray class]]) {
                for (NSDictionary *pd in arr) {
                    if ([pd isKindOfClass:[NSDictionary class]]) {
                        [_list addObject:[Preset fromDict:pd]];
                    }
                }
            }
            NSString *aid = obj[@"active"];
            if ([aid isKindOfClass:[NSString class]]) _activeId = [aid copy];
        }
    }

    if (_list.count == 0) {
        [self loadBuiltinDefault];
        needsSave = YES;
    }

    BOOL has = NO;
    for (Preset *p in _list) {
        if ([p.pid isEqualToString:_activeId]) { has = YES; break; }
    }
    if (!has) {
        _activeId = _list.firstObject.pid;
        needsSave = YES;
    }

    if (needsSave) [self save];
    DBG(@"presets: load n=%lu active=%@",
        (unsigned long)_list.count, _activeId ?: @"nil");
}

- (void)loadBuiltinDefault {
    NSData *data = [NSData dataWithBytes:kDefaultPresetJSON
                                  length:strlen(kDefaultPresetJSON)];
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data
                                             options:0
                                               error:&err];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        DBG(@"presets: builtin parse fail %@", err);
        return;
    }
    Preset *p = [Preset fromExportDict:obj];
    if (!p) {
        DBG(@"presets: builtin fromExport nil");
        return;
    }
    p.pid = @"default";
    p.name = @"";
    p.created = [[NSDate date] timeIntervalSince1970];
    p.modified = p.created;
    [_list addObject:p];
    _activeId = p.pid;
    DBG(@"presets: builtin loaded buttons=%lu",
        (unsigned long)[(NSArray *)p.data[@"buttons"] count]);
}

- (void)save {
    NSMutableArray *arr = [NSMutableArray array];
    for (Preset *p in _list) [arr addObject:[p toDict]];
    NSDictionary *root = @{
        @"active": _activeId ?: @"",
        @"presets": arr,
    };
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:root
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&err];
    if (data) [data writeToFile:presetsFile() atomically:YES];
    else DBG(@"presets: save fail %@", err);
}

- (NSArray<Preset *> *)all { return [_list copy]; }
- (NSString *)activeId { return _activeId; }

- (Preset *)active {
    for (Preset *p in _list)
        if ([p.pid isEqualToString:_activeId]) return p;
    return _list.firstObject;
}

- (void)setActiveId:(NSString *)pid {
    if (!pid) return;
    _activeId = [pid copy];
    [self save];
}

- (Preset *)createFromCurrent:(NSString *)name {
    [self syncCurrent];

    Preset *p = [Preset new];
    p.pid = [[NSUUID UUID] UUIDString];
    p.name = (name.length ? name : LK(@"common.untitled"));
    p.created = [[NSDate date] timeIntervalSince1970];
    p.modified = p.created;
    p.data = [[Settings shared] exportDict];
    [_list addObject:p];
    _activeId = p.pid;
    [self save];
    DBG(@"presets: create '%@' n=%lu",
        p.name, (unsigned long)_list.count);
    return p;
}

- (void)syncCurrent {
    Preset *cur = self.active;
    if (!cur) return;
    cur.data = [[Settings shared] exportDict];
    cur.modified = [[NSDate date] timeIntervalSince1970];
    [self save];
    LOG(@"presets: sync '%@' hudState=%ld hidden=%d",
        [cur displayName],
        (long)[Settings shared].hudState,
        [Settings shared].hidden);
}

- (void)apply:(Preset *)p {
    if (!p) return;
    if ([p.pid isEqualToString:_activeId]) {
        [[Settings shared] importDict:p.data];
        [[Settings shared] save];
        DBG(@"presets: re-apply '%@'", [p displayName]);
        return;
    }
    [self syncCurrent];
    _activeId = p.pid;
    [[Settings shared] importDict:p.data];
    [[Settings shared] save];
    [self save];
    DBG(@"presets: apply '%@'", [p displayName]);
}

- (void)applyActive {
    Preset *p = self.active;
    if (!p) return;
    [[Settings shared] importDict:p.data];
    [[Settings shared] save];
    DBG(@"presets: applyActive '%@' hudState=%ld hidden=%d",
        [p displayName],
        (long)[Settings shared].hudState,
        [Settings shared].hidden);
}

- (void)rename:(Preset *)p name:(NSString *)newName {
    if (!p) return;
    if (!newName.length) return;

    BOOL wasBuiltin = [p isBuiltin];
    BOOL wasActive = [p.pid isEqualToString:_activeId];

    if (wasBuiltin) {
        p.pid = [[NSUUID UUID] UUIDString];
    }
    p.name = newName;
    p.modified = [[NSDate date] timeIntervalSince1970];

    if (wasActive) _activeId = p.pid;

    [self save];
    DBG(@"presets: rename -> '%@'", newName);
}

- (void)remove:(Preset *)p {
    if (!p) return;
    if (_list.count <= 1) return;
    [_list removeObject:p];
    if ([_activeId isEqualToString:p.pid]) {
        _activeId = _list.firstObject.pid;
        [[Settings shared] importDict:_list.firstObject.data];
        [[Settings shared] save];
    }
    [self save];
    DBG(@"presets: remove n=%lu", (unsigned long)_list.count);
}

- (NSString *)exportString:(Preset *)p {
    if (!p) return nil;
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:[p toExportDict]
                                                   options:0
                                                     error:&err];
    if (!data) return nil;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (Preset *)importString:(NSString *)s error:(NSString **)err {
#define FAIL(msg) do { if (err) *err = msg; return nil; } while(0)
    if (!s.length) FAIL(LK(@"err.empty"));

    NSData *data = [s dataUsingEncoding:NSUTF8StringEncoding];
    NSError *jerr = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data
                                             options:0
                                               error:&jerr];
    if (![obj isKindOfClass:[NSDictionary class]])
        FAIL(LK(@"err.invalidJSON"));

    NSString *app = obj[@"app"];
    if (![app isKindOfClass:[NSString class]] ||
        ![app isEqualToString:@"OverlayPad"])
        FAIL(LK(@"err.notPreset"));

    NSNumber *schema = obj[@"schema"];
    if (![schema isKindOfClass:[NSNumber class]] || schema.integerValue != 1)
        FAIL(LK(@"err.schema"));

    Preset *p = [Preset fromExportDict:obj];
    if (!p) FAIL(LK(@"err.malformed"));

    NSDictionary *d = p.data;
    if (d[@"joySize"] && ![d[@"joySize"] isKindOfClass:[NSNumber class]])
        FAIL(LK(@"err.badJoySize"));
    if (d[@"buttons"] && ![d[@"buttons"] isKindOfClass:[NSArray class]])
        FAIL(LK(@"err.badButtons"));

    [_list addObject:p];
    [self save];
    DBG(@"presets: import '%@' n=%lu",
        [p displayName], (unsigned long)_list.count);
    return p;
#undef FAIL
}

@end