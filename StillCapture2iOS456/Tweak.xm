#import "../Common.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIImage+Private.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

static BOOL SCisOn;
static BOOL MLisOn;
static BOOL SCBLock;

static CGFloat opacity;
static CGFloat kBtnScale;
CGFloat const restoreDuration = 0.1;

static void SCELoader() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    SCisOn = [[prefs objectForKey:@"SC2Enabled"] boolValue];
    SCBLock = [[prefs objectForKey:@"SCBLock"] boolValue];
    if (IS_IPAD)
        MLisOn = [[prefs objectForKey:@"iPadMidLeftEnabled"] boolValue];
    kBtnScale = [prefs objectForKey:@"Scale"] ? [[prefs objectForKey:@"Scale"] floatValue] : 1.0;
    opacity = [prefs objectForKey:@"Opacity"] ? [[prefs objectForKey:@"Opacity"] floatValue] : 1.0;
}

static BOOL dragged = YES;

static BOOL needRotate = NO;
static BOOL changed = NO;
static CGFloat xPos;
static CGFloat yPos;

static CGFloat kSpace;
static CGFloat kViewWidth;
static CGFloat kViewHeight;
static CGFloat kButtonWidth;
static CGFloat kButtonHeight;

static PLCameraVideoStillCaptureButton *stillCaptureButton = nil;
static PLReorientingButton *stillCaptureButtoniOS45 = nil;

#define StillCaptureButton ((UIButton *)((isiOS45) ? stillCaptureButtoniOS45 : stillCaptureButton))

static void writeToFile(CGFloat x, CGFloat y){
    NSMutableDictionary *prefs = [NSMutableDictionary dictionary];
    [prefs addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
    [prefs setObject:@(x) forKey:@"xPos"];
    [prefs setObject:@(y) forKey:@"yPos"];
    [prefs writeToFile:PREF_PATH atomically:YES];
}

NSBundle *(*PLPhotoLibraryFrameworkBundle)();
CGFloat (*PLScreenScale)();

static void initBtn(){
    kSpace = (10.0 + (IS_IPAD ? 2.0 : 0.0)) * ((isiOS4 || isiOS50) ? 2.0 : 1.0);
    kViewWidth = (320.0 + (IS_IPAD ? 395.0 : 0.0)) * ((isiOS4 || isiOS50) ? 2.0 : 1.0);
    kViewHeight = (426.0 + (IS_IPAD ? 545.0 : 0.0)) * ((isiOS4 || isiOS50) ? 2.0 : 1.0);
    kButtonWidth = 74.0 * ((isiOS4 || isiOS50) ? 2.0 : 1.0);
    kButtonHeight = 35.0 * ((isiOS4 || isiOS50) ? 2.0 : 1.0);
    if (isiOS45) {
        stillCaptureButtoniOS45 = [[%c(PLReorientingButton) alloc] initWithFrame:CGRectZero];
        if (isiOS4) {
            [stillCaptureButtoniOS45 setBackgroundColor:[UIColor colorWithRed:0.88 green:0.88 blue:0.88 alpha:0.58]];
            stillCaptureButtoniOS45.layer.borderWidth = 1.7;
            stillCaptureButtoniOS45.layer.cornerRadius = 35.0;
            UIImage *icon = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PhotoLibrary.framework/PLCameraVideoStillCaptureIcon_2only_-568%@~iphone.png", PLScreenScale() == 2.0 ? @"h@2x" : @"h"]];
            UIImage *newIcon = [UIImage imageWithCGImage:[icon CGImage] scale:1 orientation:icon.imageOrientation];
            UIImage *iconPressed = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/PrivateFrameworks/PhotoLibrary.framework/PLCameraVideoStillCaptureIconPressed_2only_-568%@~iphone.png", PLScreenScale() == 2.0 ? @"h@2x" : @"h"]];
            UIImage *newIconPressed = [UIImage imageWithCGImage:[iconPressed CGImage] scale:1.0 orientation:iconPressed.imageOrientation];
            [stillCaptureButtoniOS45 setImage:newIcon forState:UIControlStateNormal];
            [stillCaptureButtoniOS45 setImage:newIconPressed forState:UIControlStateHighlighted];
            stillCaptureButtoniOS45.tintColor = [UIColor whiteColor];
        } else {
            [stillCaptureButtoniOS45 setImage:[UIImage imageNamed:[NSString stringWithFormat:@"PLCameraVideoStillCaptureIcon_2only_-568%@", isiOS50 ? PLScreenScale() == 2.0 ? @"h@2x" : @"h" : @"h"] inBundle:PLPhotoLibraryFrameworkBundle()] forState:UIControlStateNormal];
            [stillCaptureButtoniOS45 setImage:[UIImage imageNamed:[NSString stringWithFormat:@"PLCameraVideoStillCaptureIconPressed_2only_-568%@", isiOS50 ? PLScreenScale() == 2.0 ? @"h@2x" : @"h" : @"h"] inBundle:PLPhotoLibraryFrameworkBundle()] forState:UIControlStateHighlighted];
        }
    } else
        stillCaptureButton = [[%c(PLCameraVideoStillCaptureButton) alloc] initWithFrame:CGRectMake(0.0f, 0.0f, StillCaptureButton.frame.size.width, StillCaptureButton.frame.size.height)];
}

static void setPos(CGFloat x, CGFloat y) {
    if (isiOS45)
        stillCaptureButtoniOS45.frame = CGRectMake(x, y, kButtonWidth, kButtonHeight);
    else
        stillCaptureButton.frame = CGRectMake(x, y, StillCaptureButton.frame.size.width, StillCaptureButton.frame.size.height);
}

static void setButtonPosition() {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    int orientation = [[UIApplication sharedApplication] statusBarOrientation];
    id X = [prefs objectForKey:@"xPos"];
    id Y = [prefs objectForKey:@"yPos"];
    if (X == nil || Y == nil) {
        if (!changed) {
            if (!IS_IPAD) {
                if (orientation == 1)
                    setPos(kViewWidth - kSpace - 0.5 * (1 + kBtnScale) * kButtonWidth, kViewHeight - kSpace - 0.5 * kButtonHeight * (1 + kBtnScale));
                else if (orientation == 2)
                    setPos(kSpace + 0.5 * kButtonWidth * (kBtnScale - 1), kSpace + 0.5 * kButtonHeight * (kBtnScale - 1));
                else if (orientation == 3 || orientation == 4)
                    setPos(kSpace + 0.5 * kButtonWidth * (kBtnScale - 1), kViewWidth - kSpace - 0.5 * kButtonHeight * (1 + kBtnScale));
            }
        }
    } else {
        xPos = [X floatValue];
        yPos = [Y floatValue];
        if (orientation == 1 || orientation == 2) {
            if (xPos > kViewWidth - kSpace - 0.5 * (1 + kBtnScale) * kButtonWidth)
                xPos = kViewWidth - kSpace - 0.5 * (1 + kBtnScale) * kButtonWidth;
            else if (xPos < kSpace + 0.5 * kButtonWidth * (kBtnScale - 1))
                xPos = kSpace + 0.5 * kButtonWidth * (kBtnScale - 1);
            if (yPos < kSpace + 0.5 * kButtonHeight * (kBtnScale - 1))
                yPos = kSpace + 0.5 * kButtonHeight * (kBtnScale - 1);
        } else if (orientation == 3 || orientation == 4) {
            if (xPos > kViewHeight - kSpace - 0.5 * (1 + kBtnScale) * kButtonWidth)
                xPos = kViewHeight - kSpace - 0.5 * (1 + kBtnScale) * kButtonWidth;
            if (xPos < kSpace + 0.5 * kButtonWidth * (kBtnScale - 1))
                xPos = kSpace + 0.5 * kButtonWidth * (kBtnScale - 1);
            if (yPos < kSpace + 0.5 * kButtonHeight * (kBtnScale - 1))
                yPos = kSpace + 0.5 * kButtonHeight * (kBtnScale - 1);
        }
        if (orientation == 1 || orientation == 2) {
            if (yPos > kViewHeight - kSpace - 0.5 * (1 + kBtnScale) * kButtonHeight)
                yPos = kViewHeight - kSpace - 0.5 * (1 + kBtnScale) * kButtonHeight;
        } else if (orientation == 3 || orientation == 4) {
            if (yPos > kViewWidth - kSpace - 0.5 * (1 + kBtnScale) * kButtonWidth)
                yPos = kViewWidth - kSpace - 0.5 * (1 + kBtnScale) * kButtonWidth;
        }
        setPos(xPos, yPos);
    }
    if (IS_IPAD && !changed) {
        CGFloat MLLength = (orientation == 1 || orientation == 2) ? kViewHeight : kViewWidth;
        setPos(kSpace + 0.5 * kButtonWidth * (kBtnScale - 1), MLLength - kSpace - 0.5 * kButtonHeight * (1 + kBtnScale));
        if (MLisOn)
            setPos(kSpace + 0.5 * kButtonWidth * (kBtnScale - 1), (MLLength + 53.0 - kButtonHeight) / 2);
    }
    changed = YES;
    needRotate = orientation == 2;
    if (!needRotate)
        [StillCaptureButton setTransform:CGAffineTransformScale(CGAffineTransformIdentity, kBtnScale, kBtnScale)];
}

static void removeButton() {
    if (isiOS45) {
        if (stillCaptureButtoniOS45) {
            [stillCaptureButtoniOS45 removeFromSuperview];
            stillCaptureButtoniOS45 = nil;
            [stillCaptureButtoniOS45 release];
        }
    } else {
        if (stillCaptureButton) {
            [stillCaptureButton removeFromSuperview];
            stillCaptureButton = nil;
            [stillCaptureButton release];
        }
    }
}

%hook PLCameraView

%new
- (void)SCBFinishedDragging: (UIButton *)button withEvent: (UIEvent *)event {
    int orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == 1 || orientation == 2) {
        if (button.frame.origin.x > kViewWidth - kSpace - kButtonWidth * kBtnScale)
            [UIView animateWithDuration:restoreDuration animations:^{
                button.frame = CGRectMake(kViewWidth - kSpace - kButtonWidth * kBtnScale, button.frame.origin.y, button.frame.size.width, button.frame.size.height);
            }];
        else if (button.frame.origin.x < kSpace)
            [UIView animateWithDuration:restoreDuration animations:^{
                button.frame = CGRectMake(kSpace, button.frame.origin.y, button.frame.size.width, button.frame.size.height);
            }];
        if (button.frame.origin.y > kViewHeight - kSpace - kButtonHeight * kBtnScale)
            [UIView animateWithDuration:restoreDuration animations:^{
                button.frame = CGRectMake(button.frame.origin.x, kViewHeight - kSpace - kButtonHeight*kBtnScale, button.frame.size.width, button.frame.size.height);
            }];
        else if (button.frame.origin.y < kSpace)
            [UIView animateWithDuration:restoreDuration animations:^{
                button.frame = CGRectMake(button.frame.origin.x, kSpace, button.frame.size.width, button.frame.size.height);
            }];
    } else if (orientation == 3 || orientation == 4) {
        if (button.frame.origin.x > kViewHeight - kSpace - kButtonWidth * kBtnScale)
            [UIView animateWithDuration:restoreDuration animations:^{
                button.frame = CGRectMake(kViewHeight - kSpace - kButtonWidth * kBtnScale, button.frame.origin.y, button.frame.size.width, button.frame.size.height);
            }];
        else if (button.frame.origin.x < kSpace)
            [UIView animateWithDuration:restoreDuration animations:^{
                button.frame = CGRectMake(kSpace, button.frame.origin.y, button.frame.size.width, button.frame.size.height);
            }];
        if (button.frame.origin.y > kViewWidth - kSpace - kButtonHeight * kBtnScale)
            [UIView animateWithDuration:restoreDuration animations:^{
                button.frame = CGRectMake(button.frame.origin.x, kViewWidth - kSpace - kButtonHeight * kBtnScale, button.frame.size.width, button.frame.size.height);
            }];
        else if (button.frame.origin.y < kSpace)
            [UIView animateWithDuration:restoreDuration animations:^{
                button.frame = CGRectMake(button.frame.origin.x, kSpace, button.frame.size.width, button.frame.size.height);
            }];
    }
    dragged = YES;
}

%new
- (void)SCBTouchMoved: (UIButton *)button withEvent: (UIEvent *)event {
    if (SCBLock)
        return;
    UITouch *touch = [[event touchesForView:button] anyObject];
    PLPreviewOverlayView *cameraView = MSHookIvar<PLPreviewOverlayView *>(self, "_overlayView");
    CGPoint previousLocation = [touch previousLocationInView:cameraView];
    CGPoint location = [touch locationInView:cameraView];
    CGFloat delta_x = location.x - previousLocation.x;
    CGFloat delta_y = location.y - previousLocation.y;
    StillCaptureButton.center = CGPointMake(button.center.x + delta_x, button.center.y + delta_y);
    xPos = StillCaptureButton.frame.origin.x;
    yPos = StillCaptureButton.frame.origin.y;
    writeToFile(xPos, yPos);
    dragged = NO;
}

- (void)cameraControllerVideoCaptureDidStart:(id)cameraControllerVideoCapture {
    %orig;
    if ([(PLCameraController *)[%c(PLCameraController) sharedInstance] isCameraApp] && ([(NSObject *) self respondsToSelector:@selector(isTallScreen)] ? ![self isTallScreen] : YES)) {
        initBtn();
        setButtonPosition();
        if (needRotate) {
            CGAffineTransform transform = StillCaptureButton.transform;
            transform = CGAffineTransformRotate(transform, M_PI);
            transform = CGAffineTransformScale(transform, kBtnScale, kBtnScale);
            StillCaptureButton.transform = transform;
            needRotate = NO;
        }
        if (isiOS45)
            StillCaptureButton.alpha = opacity;
        [MSHookIvar<PLPreviewOverlayView *>(self, "_overlayView") addSubview:StillCaptureButton];
        if (isiOS4) {
            [StillCaptureButton addTarget:self action:@selector(highlight) forControlEvents:UIControlEventTouchDown];
            [StillCaptureButton addTarget:self action:@selector(unhighlight) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        }
        [StillCaptureButton addTarget:self action:@selector(sc2_captureImage) forControlEvents:UIControlEventTouchUpInside];
        [StillCaptureButton addTarget:self action:@selector(SCBTouchMoved:withEvent:) forControlEvents:UIControlEventTouchDragInside];
        [StillCaptureButton addTarget:self action:@selector(SCBFinishedDragging:withEvent:) forControlEvents:UIControlEventTouchDragExit | UIControlEventTouchUpInside];
    }
}

%new
- (void)highlight {
    [stillCaptureButtoniOS45 setBackgroundColor:[UIColor colorWithRed:0.88f green:0.88f blue:0.88f alpha:0.75f]];
}

%new
- (void)unhighlight {
    [stillCaptureButtoniOS45 setBackgroundColor:[UIColor colorWithRed:0.88f green:0.88f blue:0.88f alpha:0.58f]];
}

- (void)cameraControllerVideoCaptureDidStop:(id)cameraControllerVideoCapture withReason:(int)reason userInfo:(id)info {
    if (([(NSObject *) self respondsToSelector:@selector(isTallScreen)] ? ![self isTallScreen] : YES)) {
        removeButton();
        changed = NO;
    }
    %orig;
}

%end

%group CamRotate

%hook PLCameraController

- (void)accelerometer: (id)accelerometer didChangeDeviceOrientation: (NSInteger)orientation {
    %orig;
    BOOL isLocked = ([[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.springboard.plist"] objectForKey:@"SBLastRotationLockedOrientation"] boolValue]);
    if ([self isCapturingVideo]) {
        if ([[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.PS.CamRotate.plist"] objectForKey:@"SyncOrientation"] boolValue] && !isLocked) {
            [(PLReorientingButton *) stillCaptureButton setButtonOrientation:orientation animated:YES];
            setButtonPosition();
        }
    }
}

%end

%end

%group iOS6

static BOOL preventNativeBtn = NO;

%hook PLCameraView

%new
- (void)sc2_captureImage {
    if (dragged)
        [self _captureStillDuringVideo];
}

- (void)takePictureDuringVideoOpenIrisAnimationFinished {
    %orig;
    [self _disableBottomBarForContinuousCapture];
}

- (void)_showVideoCaptureControls {
    preventNativeBtn = YES;
    %orig;
    preventNativeBtn = NO;
}

%end

%hook PLCameraController

- (BOOL)canCapturePhotoDuringRecording {
    return [self isCameraApp] ? !preventNativeBtn : %orig;
}

%end

%hook PLCameraVideoStillCaptureButton

- (id)initWithFrame: (CGRect)frame {
    self = %orig;
    if (self)
        self.alpha = opacity;
    return self;
}

%end

%end

%group iPod5

%hook PLCameraController

- (BOOL)canCapturePhotoDuringRecording {
    return [self isCameraApp] ? YES : %orig;
}

%end

%end

%group iOS45

%hook PLCameraView

%new
- (void)sc2_captureImage {
    if (!dragged)
        return;
    [self _setShouldShowFocus:NO];
    if (![(PLCameraController *)[%c(PLCameraController) sharedInstance] flashWillFire])
        [self pausePreview];
    AVCaptureStillImageOutput *imageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil];
    imageOutput.outputSettings = outputSettings;
    [MSHookIvar<PLCameraController *>(self, "_cameraController").currentSession addOutput:imageOutput];
    [outputSettings release];
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in [imageOutput connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection)
            break;
    }
    [self closeIrisWithDidFinishSelector:nil withDuration:0.2];
    MPMusicPlayerController *musicPlayer = [[MPMusicPlayerController alloc] init];
    float defaultVolume = musicPlayer.volume;
    if (musicPlayer.volume > 0)
        musicPlayer.volume = 0.0;
    [imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        if (imageSampleBuffer) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
            [image release];
        }
        [MSHookIvar<PLCameraController *>(self, "_cameraController").currentSession removeOutput:imageOutput];
        [imageOutput release];
        [self openIrisWithDidFinishSelector:nil withDuration:0.2];
        [self resumePreview];
        [self _setShouldShowFocus:YES];
        [self _checkDiskSpaceAfterCapture];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        musicPlayer.volume = defaultVolume;
        [musicPlayer release];
    });
}

%end

%end

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    SCELoader();
}

%ctor {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
    SCELoader();
    if (SCisOn) {
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *modelName = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        MSImageRef pls = MSGetImageByName("/System/Library/PrivateFrameworks/PhotoLibraryServices.framework/PhotoLibraryServices");
        PLPhotoLibraryFrameworkBundle = (NSBundle *(*)())MSFindSymbol(pls, "_PLPhotoLibraryFrameworkBundle");
        PLScreenScale = (CGFloat (*)())MSFindSymbol(pls, "_PLScreenScale");
        if (![modelName isEqualToString:@"iPod5,1"]) {
            if (isiOS5 || (isiOS4 && [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.camera"])) {
                %init(iOS45);
            } else if (isiOS6) {
                %init(iOS6);
            }
            %init;
        } else {
            %init(iPod5);
        }
        if (dlopen("/Library/MobileSubstrate/DynamicLibraries/CamRotate.dylib", RTLD_LAZY)) {
            %init(CamRotate);
        }
    }
    [pool drain];
}
