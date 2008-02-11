// nu.m
//  Top-level Nu functions.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "parser.h"
#import "symbol.h"
#import "Nu.h"
#import "extensions.h"
#import "object.h"
#import "objc_runtime.h"
#import "regex.h"
#import <unistd.h>

id Nu__null = 0;

@implementation Nu
+ (id<NuParsing>) parser
{
    return [[[NuParser alloc] init] autorelease];
}

+ (int) sizeOfPointer
{
    return sizeof(void *);
}

@end

@interface NuApplication : NSObject
{
    NSMutableArray *arguments;
}

@end

static NuApplication *_sharedApplication = 0;

@implementation NuApplication
+ (NuApplication *) sharedApplication
{
    if (!_sharedApplication)
        _sharedApplication = [[NuApplication alloc] init];
    return _sharedApplication;
}

- (void) setArgc:(int) argc argv:(const char *[])argv
{
    arguments = [[NSMutableArray alloc] init];
    int i;
    // skip the first two.  They are usually "nush" and the script name.
    for (i = 2; i < argc; i++) {
        [arguments addObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
    }
}

- (NSArray *) arguments
{
    return arguments;
}

@end

void write_arguments(int argc, char *argv[])
{
    NSLog(@"launched with arguments");
    int i;
    for (i = 0; i < argc; i++) {
        NSLog(@"argv[%d]: %s", i, argv[i]);
    }
}

int NuMain(int argc, const char *argv[])
{
    void NuInit();
    NuInit();

    @try
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        // collect the command-line arguments
        [[NuApplication sharedApplication] setArgc:argc argv:argv];

        // first we try to load main.nu from the application bundle.
        NSString *main_path = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"nu"];
        if (main_path) {
            NSString *main_nu = [NSString stringWithContentsOfFile:main_path];
            if (main_nu) {
                NuParser *parser = [[NuParser alloc] init];
                id script = [parser parse:main_nu asIfFromFilename:[main_nu cStringUsingEncoding:NSUTF8StringEncoding]];
                [parser eval:script];
                [parser release];
                [pool release];
                return 0;
            }
        }
        // if that doesn't work, use the arguments to decide what to execute
        else if (argc > 1) {
            NuParser *parser = [[NuParser alloc] init];
            id script, result;
            bool didSomething = false;
            int i = 1;
            bool fileEvaluated = false;           // only evaluate one filename
            while (i < argc) {
                if (!strcmp(argv[i], "-e")) {
                    i++;
                    script = [parser parse:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
                    result = [parser eval:script];
                    didSomething = true;
                }
                else if (!strcmp(argv[i], "-f")) {
                    i++;
                    script = [parser parse:[NSString stringWithFormat:@"(load \"%s\")", argv[i]] asIfFromFilename:argv[i]];
                    result = [parser eval:script];
                }
                else if (!strcmp(argv[i], "-i")) {
                    [parser interact];
                    didSomething = true;
                }
                else {
                    if (!fileEvaluated) {
                        id string = [NSString stringWithContentsOfFile:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
                        if (string) {
                            id script = [parser parse:string asIfFromFilename:argv[i]];
                            [parser eval:script];
                            fileEvaluated = true;
                        }
                        else {
                            // complain somehow. Throw an exception?
                            NSLog(@"Error: can't open file named %s", argv[i]);
                        }
                        didSomething = true;
                    }
                }
                i++;
            }
            if (!didSomething)
                [parser interact];
            [parser release];
            [pool release];
            return 0;
        }
        // if there's no file, run at the terminal
        else {
            if (!isatty(stdin->_file)) {
                NuParser *parser = [[NuParser alloc] init];
                id string = [[NSString alloc] initWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
                id script = [parser parse:string asIfFromFilename:"stdin"];
                [parser eval:script];
                [parser release];
                [pool release];
            }
            else {
                [pool release];
                return [NuParser main];
            }
        }
    }
    @catch (id exception) {
        NSLog(@"Terminating due to uncaught exception (below):");
        NSLog(@"%@: %@", [exception name], [exception reason]);
    }
    return 0;
}

static int load_nu_files(NSString *bundleIdentifier, NSString *mainFile)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSBundle *bundle = [NSBundle bundleWithIdentifier:bundleIdentifier];
    NSString *main_path = [bundle pathForResource:mainFile ofType:@"nu"];
    if (main_path) {
        NSString *main_nu = [NSString stringWithContentsOfFile:main_path];
        if (main_nu) {
            id parser = [Nu parser];
            id script = [parser parse:main_nu asIfFromFilename:[main_path cStringUsingEncoding:NSUTF8StringEncoding]];
            [parser eval:script];
        }
    }
    [pool release];
    return 0;
}

static void transplant_nu_methods(Class destination, Class source)
{
    if (!nu_copyInstanceMethod(destination, source, @selector(evalWithArguments:context:)))
        NSLog(@"method copy failed");
    if (!nu_copyInstanceMethod(destination, source, @selector(sendMessage:withContext:)))
        NSLog(@"method copy failed");
    if (!nu_copyInstanceMethod(destination, source, @selector(stringValue)))
        NSLog(@"method copy failed");
    if (!nu_copyInstanceMethod(destination, source, @selector(evalWithContext:)))
        NSLog(@"method copy failed");
    if (!nu_copyInstanceMethod(destination, source, @selector(handleUnknownMessage:withContext:)))
        NSLog(@"method copy failed");
}

void NuInit()
{
    static int initialized = 0;
    if (!initialized) {
        initialized = 1;

        Nu__null = [NSNull null];

        // Copy some useful methods from NSObject to NSProxy.
        // Their implementations are identical; this avoids code duplication.
        transplant_nu_methods([NSProxy class], [NSObject class]);

        // Stop NSView from complaining when we retain alloc-ed views.
        Class NSView = NSClassFromString(@"NSView");
        [NSView exchangeInstanceMethod:@selector(retain) withMethod:@selector(nuRetain)];

        // Apply swizzles to container classes to make them tolerant of nil insertions.
        extern void nu_swizzleContainerClasses();
        nu_swizzleContainerClasses();

        // Enable support for protocols in Nu.  Apple doesn't have an API for this, so we use our own.
        extern void nu_initProtocols();
        nu_initProtocols();

        // if you don't like making Protocol a subclass of NSObject (see nu_initProtocols), you can do this instead.
        // transplant_nu_methods([Protocol class], [NSObject class]);

        // Load some standard files
        load_nu_files(@"nu.programming.framework", @"nu");
        load_nu_files(@"nu.programming.framework", @"bridgesupport");
        load_nu_files(@"nu.programming.framework", @"cocoa");
        load_nu_files(@"nu.programming.framework", @"help");
    }
}

// Helpers for programmatic construction of Nu code.

id _nunull()
{
    return [NSNull null];
}

id _nustring(const char *string)
{
    return [NSString stringWithCString:string encoding:NSUTF8StringEncoding];
}

id _nusymbol(const char *string)
{
    return [[NuSymbolTable sharedSymbolTable] symbolWithCString:string];
}

id _nunumberd(double d)
{
    return [NSNumber numberWithDouble:d];
}

id _nucell(id car, id cdr)
{
    return [NuCell cellWithCar:car cdr:cdr];
}

id _nuregex(const char *pattern, int options)
{
    return [NuRegex regexWithPattern:_nustring(pattern) options:options];
}
