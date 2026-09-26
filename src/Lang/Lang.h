#pragma once
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LangMode) { LangAuto = 0, LangEn = 1, LangZh = 2 };

extern NSString * const LangDidChangeNotification;

void LangRegister(NSString *code, NSDictionary<NSString *, NSString *> *table);
void LangSetMode(LangMode m);
LangMode LangGetMode(void);
NSString *LK(NSString *key);
NSString *LangName(LangMode m);
void LangRegAll(void);