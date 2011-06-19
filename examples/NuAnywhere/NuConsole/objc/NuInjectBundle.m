//  NuInjectBundle.m

#import <Cocoa/Cocoa.h>
#import <Nu/Nu.h>

@interface ConsoleInitializer : NSObject
{}
@end

@implementation ConsoleInitializer

- (id) run:(id) object
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"starting");
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *main_path = [bundle pathForResource:@"main" ofType:@"nu"];
    if (main_path) {
        NSString *main = [NSString stringWithContentsOfFile:main_path];
        if (main) {
            id parser = [Nu parser];
            id script = [parser parse:main];
            [parser eval:script];
        }
    }
    [pool release];
}

@end

static ConsoleInitializer *consoleInitializer = nil;

__attribute__((constructor)) static void
InjectBundleInit (void)
{
    consoleInitializer = [[ConsoleInitializer alloc] init];
    [consoleInitializer performSelectorOnMainThread:@selector(run:) withObject:nil waitUntilDone:NO];
}
