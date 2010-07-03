#include "TargetConditionals.h"

#if TARGET_IPHONE_SIMULATOR
#import "ffi-iphonesimulator.h"
#else
#import "ffi-iphone.h"
#endif
