#import "AboutContent.h"

#ifndef APP_VERSION
#define APP_VERSION "v0.0.0-unknown"
#endif

NSString *AboutName(void) { return @"locationovo"; }

NSString *AboutVersion(void) {
    return @APP_VERSION;
}

NSArray<NSString *> *AboutLineKeys(void) {
    return @[ @"about.line1", @"about.line2", @"about.line3" ];
}