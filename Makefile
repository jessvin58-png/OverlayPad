UNAME_S := $(shell uname -s 2>/dev/null)
ifeq ($(strip $(UNAME_S)),)
$(error cannot determine host OS)
endif

JBROOT_DIR := $(shell find /var/containers/Bundle/Application/ -maxdepth 1 \
                -name '.jbroot-*' \
                -exec test -d '{}/usr/share/SDKs/iPhoneOS.sdk' \; -print -quit \
                2>/dev/null)

ifneq ($(JBROOT_DIR),)
  HOST_KIND := iOS
  SDK ?= $(JBROOT_DIR)/usr/share/SDKs/iPhoneOS.sdk
  CC  := clang
  LD  := clang
else ifeq ($(UNAME_S),Darwin)
  HOST_KIND := macOS
  SDK ?= $(shell xcrun --sdk iphoneos --show-sdk-path 2>/dev/null)
  CC  := $(shell xcrun --sdk iphoneos -f clang 2>/dev/null)
  ifeq ($(CC),)
  CC  := clang
  endif
  LD  := $(CC)
else ifeq ($(UNAME_S),Linux)
  HOST_KIND := Linux
  SDK ?=
  CC  := clang
  LD  := clang
else
  HOST_KIND := unsupported
  SDK ?=
  CC  := clang
  LD  := clang
endif

ARCH     ?= arm64
MIN_IOS  ?= 15.0
TARGET   ?= OverlayPad.dylib
DEBUG    ?= 0
TAGS     ?=
LIDID    ?= ldid

SRC_DIR    := src
ASSET_DIR  := assets
COMMON_DIR := $(SRC_DIR)/Common
LANG_DIR   := $(SRC_DIR)/Lang
ABOUT_DIR  := $(SRC_DIR)/About
HUD_DIR    := $(SRC_DIR)/HUD
PAD_DIR    := $(SRC_DIR)/Pad
INPUT_DIR  := $(SRC_DIR)/Input
SET_DIR    := $(SRC_DIR)/Settings
STYLE_DIR  := $(SRC_DIR)/Style
STYLES_DIR := $(STYLE_DIR)/styles

VERSION_BASE := $(shell sed 's|//.*||' VERSION 2>/dev/null \
              | grep -v '^[[:space:]]*$$' | head -1 | tr -d '[:space:]')
VERSION_BASE := $(if $(VERSION_BASE),$(VERSION_BASE),0.0.0)
BUILD_DATE   := $(shell date +%Y%m%d)
GIT_HASH     := $(shell git rev-parse --short=7 HEAD 2>/dev/null)
GIT_DIRTY    := $(shell git diff --cached --quiet --exit-code 2>/dev/null || echo -dirty)

ifneq ($(GIT_HASH),)
VERSION_STR := v$(VERSION_BASE)$(if $(TAGS),-$(TAGS),)-$(BUILD_DATE)-$(GIT_HASH)$(GIT_DIRTY)
else
VERSION_STR := v$(VERSION_BASE)$(if $(TAGS),-$(TAGS),)-nogit-$(BUILD_DATE)
endif

SRCS := \
    $(SRC_DIR)/main.m \
    $(COMMON_DIR)/Common.m \
    $(COMMON_DIR)/DebugConsole.m \
    $(LANG_DIR)/Lang.m \
    $(LANG_DIR)/Lang_en.m \
    $(LANG_DIR)/Lang_zh.m \
    $(ABOUT_DIR)/About.m \
    $(ABOUT_DIR)/AboutContent.m \
    $(HUD_DIR)/HUD.m \
    $(HUD_DIR)/HUDInternal.m \
    $(HUD_DIR)/HUD+Widgets.m \
    $(HUD_DIR)/HUD+Panel.m \
    $(HUD_DIR)/HUD+Edit.m \
    $(HUD_DIR)/HUD+Presets.m \
    $(PAD_DIR)/Pad.m \
    $(INPUT_DIR)/Input.m \
    $(INPUT_DIR)/Injector.m \
    $(SET_DIR)/Settings.m \
    $(SET_DIR)/Presets.m \
    $(STYLE_DIR)/Style.m \
    $(wildcard $(STYLES_DIR)/*.m)

OBJS := $(SRCS:.m=.o)
DEPS := $(OBJS:.o=.d)

AVATAR_SRC := $(ASSET_DIR)/avatar.png
AVATAR_HDR := $(ABOUT_DIR)/avatar_data.h
AVATAR_DEP :=

ifneq ($(wildcard $(AVATAR_SRC)),)
  AVATAR_DEP := $(AVATAR_HDR)
  CFLAGS += -DJOY_HAS_AVATAR
  $(info [avatar] enabled  src=$(AVATAR_SRC) hdr=$(AVATAR_HDR))
else
  $(info [avatar] disabled (missing $(AVATAR_SRC), fallback to SF Symbol))
endif

INCLUDES := -I$(SRC_DIR) -I$(COMMON_DIR) -I$(LANG_DIR) -I$(ABOUT_DIR) \
            -I$(HUD_DIR) -I$(PAD_DIR) -I$(INPUT_DIR) \
            -I$(SET_DIR) -I$(STYLE_DIR)

CFLAGS += -target $(ARCH)-apple-ios$(MIN_IOS) \
         -isysroot $(SDK) \
         -DDEBUG=$(DEBUG) \
         -DAPP_VERSION=\"$(VERSION_STR)\" \
         -fobjc-arc -fPIC -fblocks \
         -MMD -MP \
         -Wall -Wextra \
         -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function \
         $(INCLUDES)

ifeq ($(DEBUG),1)
CFLAGS += -O0 -g3
else
CFLAGS += -Os -g0
endif

LDFLAGS += -target $(ARCH)-apple-ios$(MIN_IOS) \
           -isysroot $(SDK) \
           -dynamiclib \
           -install_name @rpath/$(TARGET) \
           -framework UIKit -framework Foundation \
           -framework CoreGraphics -framework QuartzCore \
           -framework GameController

.PHONY: all check-sdk sign clean install info print-target

all: check-sdk $(TARGET)

check-sdk:
	@echo "[host] $(HOST_KIND)  SDK=$(SDK)"
	@case "$(HOST_KIND)" in \
	  iOS|macOS) ;; \
	  Linux) echo "!! Linux cannot build iOS dylib" >&2; exit 1 ;; \
	  *) echo "!! unsupported host: '$(UNAME_S)'" >&2; exit 1 ;; \
	esac
	@test -n "$(SDK)" || { echo "!! empty SDK path" >&2; exit 1; }
	@test -d "$(SDK)"  || { echo "!! SDK not a directory: $(SDK)" >&2; exit 1; }
	@test -d "$(SDK)/System/Library/Frameworks/UIKit.framework" || \
	  { echo "!! not a valid iPhoneOS SDK: $(SDK)" >&2; exit 1; }

$(AVATAR_HDR): $(AVATAR_SRC)
	@mkdir -p $(dir $@)
	@echo "  GEN $@ ($$(wc -c < $(AVATAR_SRC) | tr -d ' ') bytes)"
	@{ \
	  echo '// auto-generated'; \
	  echo '#pragma once'; \
	  echo 'static const char g_avatar_b64[] ='; \
	  base64 $(AVATAR_SRC) | tr -d '\n' | fold -w 76 \
	    | sed 's/^/"/; s/$$/"/'; \
	  echo ';'; \
	} > $@
	@echo "  [$@ $$(wc -c < $@) bytes]"

%.o: %.m $(AVATAR_DEP)
	@mkdir -p $(dir $@)
	@echo "  CC  $<"
	@$(CC) $(CFLAGS) -c $< -o $@

$(TARGET): check-sdk $(OBJS)
	@echo "  LD  $@"
	@$(LD) $(LDFLAGS) -o $@ $(OBJS)
	@ls -lh $@

sign: check-sdk $(TARGET)
	@command -v $(LIDID) >/dev/null 2>&1 || \
	  { echo "!! ldid not found" >&2; exit 1; }
	@$(LIDID) -S $<
	@echo "==> signed $<"

install:
	@test -n "$(DEST)" || { echo "usage: make install DEST=<dir>" >&2; exit 1; }
	@$(MAKE) --no-print-directory sign
	@mkdir -p "$(DEST)" && cp $(TARGET) "$(DEST)/" && echo "==> $(DEST)/$(TARGET)"

clean:
	@rm -f $(OBJS) $(DEPS) $(TARGET) $(AVATAR_HDR)

info:
	@echo "host    = $(HOST_KIND)"
	@echo "sdk     = $(SDK)"
	@echo "cc      = $(CC)"
	@echo "arch    = $(ARCH)  min_ios = $(MIN_IOS)"
	@echo "debug   = $(DEBUG)"
	@echo "version = $(VERSION_STR)"
	@echo "avatar  = $(if $(AVATAR_DEP),yes ($(AVATAR_SRC)),no)"
	@echo "srcs    ="
	@for f in $(SRCS); do echo "  $$f"; done

print-target:
	@echo $(TARGET)

-include $(DEPS)