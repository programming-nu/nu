
#import <Cocoa/Cocoa.h>
#import <Nu/Nu.h>
#import "mach_inject_bundle.h"

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
