
#import <Cocoa/Cocoa.h>
#import <Nu/Nu.h>

#if defined(__x86_64__)
#import <mach_inject_bundle/mach_inject_bundle.h>
#else
#import "mach_inject_bundle.h"
#endif

@implementation Nu (Inject)

+ (void)injectBundleWithPath:(NSString *)bundlePath intoProcess:(pid_t)pid
{
    if ([bundlePath isAbsolutePath] == 0) {
        bundlePath = [[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:bundlePath] stringByStandardizingPath];
    }
    mach_error_t err = mach_inject_bundle_pid([bundlePath fileSystemRepresentation], pid);
    if (err != err_none)
        NSLog(@"Failure code %x", err);
}

@end
