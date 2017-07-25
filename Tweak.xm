#import "../PS.h"
#import <dlfcn.h>

%ctor {
    if (isiOS7Up)
        dlopen("/Library/Application Support/SC2/StillCapture2iOS789.dylib", RTLD_LAZY);
#if !__LP64__
    else
        dlopen("/Library/Application Support/SC2/StillCapture2iOS456.dylib", RTLD_LAZY);
#endif
}
