#import "../Common.h"

static BOOL SCisOn;

static CGFloat opacity;
static CGFloat kBtnScale;

static void SCELoader() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    SCisOn = prefs[@"SC2Enabled"] ? [prefs[@"SC2Enabled"] boolValue] : YES;
    kBtnScale = prefs[@"Scale"] ? [prefs[@"Scale"] floatValue] : 1.0;
    opacity = prefs[@"Opacity"] ? [prefs[@"Opacity"] floatValue] : 1.0;
}

extern "C" Boolean MGGetBoolAnswer(CFStringRef);
%hookf(Boolean, MGGetBoolAnswer, CFStringRef key) {
    if (CFEqual(key, CFSTR("video-stills")))
        return YES;
    return %orig(key);
}

%group preiOS8

%hook CAMBottomBar

- (void)_layoutForHorizontalOrientation {
    %orig;
    CGFloat X = self.stillDuringVideoButton.frame.origin.x;
    CGFloat Y = CGRectGetMaxY(self.stillDuringVideoButton.frame);
    CGFloat midY = Y - 0.5 * kBtnScale * (Y - 1);
    self.stillDuringVideoButton.frame = CGRectMake(X, midY, 47.0 * kBtnScale, 47.0 * kBtnScale);
}

- (void)_layoutForVerticalOrientation {
    %orig;
    CGRect frame = self.frame;
    CGFloat maxY = CGRectGetMaxY(frame) - 55.0;
    CGFloat midX = CGRectGetWidth(frame) / 2 - 23.5 * kBtnScale;
    self.stillDuringVideoButton.frame = CGRectMake(midX, maxY, 47.0 * kBtnScale, 47.0 * kBtnScale);
}

%end

%end

%group iPad

static BOOL padHook = NO;

%hook CAMCameraSpec

- (BOOL)isPhone {
    return padHook ? YES : %orig;
}

%end

%hook CAMPadApplicationSpec

- (BOOL)shouldCreateStillDuringVideo {
    return YES;
}

%end

%end

%group iPad7

%hook PLCameraView

- (void)_createStillDuringVideoButtonIfNecessary {
    padHook = YES;
    %orig;
    padHook = NO;
}

%end

%end

%group iPad8

%hook CAMCameraView

- (void)_createStillDuringVideoButtonIfNecessary {
    padHook = YES;
    %orig;
    padHook = NO;
}

%end

%end

%group iOS7

%hook PLCameraView

- (void)_showControlsForCapturingVideoAnimated: (BOOL)animated {
    %orig;
    self._stillDuringVideoButton.alpha = opacity;
}

%end

%end

%group iOS8

%hook CAMCameraView

- (void)_showControlsForCapturingVideoAnimated: (BOOL)animated {
    %orig;
    self._stillDuringVideoButton.alpha = opacity;
}

%end

%end

%hook CAMBottomBar

%group iPad9

- (void)_layoutStillDuringVideoButtonForTraitCollection: (id)arg1 {
    CGRect frame = self.frame;
    CGFloat maxY = CGRectGetMaxY(frame) - 55.0;
    CGFloat midX = CGRectGetWidth(frame) / 2 - 23.5 * kBtnScale;
    self.stillDuringVideoButton.frame = CGRectMake(midX, maxY, 47.0 * kBtnScale, 47.0 * kBtnScale);
}

%end

%group iPad10

- (void)_layoutStillDuringVideoButtonForLayoutStyle: (NSInteger)style {
    CGRect frame = self.frame;
    CGFloat maxY = CGRectGetMaxY(frame) - 55.0;
    CGFloat midX = CGRectGetWidth(frame) / 2 - 23.5 * kBtnScale;
    self.stillDuringVideoButton.frame = CGRectMake(midX, maxY, 47.0 * kBtnScale, 47.0 * kBtnScale);
}

%end

%end

%hook CAMViewfinderViewController

%group iOS9

- (void)_showControlsForMode: (NSInteger)mode device: (NSInteger)device animated: (BOOL)animated {
    %orig;
    if (mode == 1 || mode == 2)
        self._stillDuringVideoButton.alpha = opacity;
}

%end

%group iOS10

- (void)_showControlsForGraphConfiguration: (CAMCaptureGraphConfiguration *)configuration animated: (BOOL)animated {
    %orig;
    if (configuration.mode == 1 || configuration.mode == 2)
        self._stillDuringVideoButton.alpha = opacity;
}

%end

%end

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    SCELoader();
}

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    SCELoader();
    if (SCisOn) {
        %init;
        if (isiOS9Up) {
            openCamera9();
            if (isiOS10Up) {
                %init(iOS10);
                if (IS_IPAD) {
                    %init(iPad10);
                }
            } else {
                %init(iOS9)
                if (IS_IPAD) {
                    %init(iPad9);
                }
            }
        } else if (isiOS8) {
            openCamera8();
            %init(iOS8);
            if (IS_IPAD) {
                %init(iPad8);
            }
        } else if (isiOS7) {
            openCamera7();
            %init(iOS7);
            if (IS_IPAD) {
                %init(iPad7);
            }
            %init(preiOS8);
        }
        if (IS_IPAD) {
            %init(iPad);
        }
    }
}
