#define UNRESTRICTED_AVAILABILITY
#import <PSHeader/CameraApp/CAMBottomBar.h>
#import <PSHeader/Misc.h>

#define BUTTON_SIZE 47.0

extern bool AVGestaltGetBoolAnswer(CFStringRef key);

%hookf(bool, AVGestaltGetBoolAnswer, CFStringRef key) {
    if (CFStringEqual(key, CFSTR("AVGQVideoStillsCapability"))) return true;
    return %orig;
}

%hook CAMBottomBar

- (void)_layoutStillDuringVideoButtonForLayoutStyle:(NSInteger)style {
    CGRect frame = self.frame;
    CGFloat maxY = CGRectGetMaxY(frame) - BUTTON_SIZE - 16.0;
    CGFloat midX = CGRectGetWidth(frame) / 2 - (BUTTON_SIZE / 2);
    self.stillDuringVideoButton.frame = CGRectMake(midX, maxY, BUTTON_SIZE, BUTTON_SIZE);
}

%end
