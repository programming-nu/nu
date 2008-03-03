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
#import "bridge.h"
#import "class.h"
#import "enumerable.h"
#import <unistd.h>
#import "pcre.h"

id Nu__null = 0;

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

        // check UTF8 support in PCRE
        void *pcre_query_result = 0;
        pcre_config(PCRE_CONFIG_UTF8, &pcre_query_result);
        if (pcre_query_result == 0) {
            NSLog(@"Sorry, this build of Nu can't be used.");
            NSLog(@"The problem is with the PCRE (Perl-Compatible Regular Expression) library.");
            NSLog(@"Nu requires a PCRE that supports UTF8-encoded strings; the current one doesn't.");
            NSLog(@"Please see the notes/PCRE file in the Nu source distribution for more details.");
            NSLog(@"It includes instructions for building a PCRE that will work well with Nu.");
            exit(-1);
        }

        Nu__null = [NSNull null];

        // add enumeration to collection classes
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [NSArray include: [NuClass classWithClass:[NuEnumerable class]]];
        [NSSet include: [NuClass classWithClass:[NuEnumerable class]]];
        [pool release];

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

        #ifndef MININUSH
        // Load some standard files
        // Warning: since these loads are performed without a context, the non-global symbols defined in them
        // will not be available to other Nu scripts or at the console.  These loads should only be used
        // to set globals and to make changes to information stored in the ObjC runtime.
        [Nu loadNuFile:@"nu"            fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        [Nu loadNuFile:@"bridgesupport" fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        [Nu loadNuFile:@"cocoa"         fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        [Nu loadNuFile:@"help"          fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        #endif
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

@implementation Nu
+ (id<NuParsing>) parser
{
    return [[[NuParser alloc] init] autorelease];
}

+ (int) sizeOfPointer
{
    return sizeof(void *);
}

+ (BOOL) loadNuFile:(NSString *) fileName fromBundleWithIdentifier:(NSString *) bundleIdentifier withContext:(NSMutableDictionary *) context
{
    BOOL success = NO;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSBundle *bundle = [NSBundle bundleWithIdentifier:bundleIdentifier];
    NSString *filePath = [bundle pathForResource:fileName ofType:@"nu"];
    if (filePath) {
        NSString *fileNu = [NSString stringWithContentsOfFile:filePath];
        if (fileNu) {
            id parser = [Nu parser];
            id script = [parser parse:fileNu asIfFromFilename:[filePath cStringUsingEncoding:NSUTF8StringEncoding]];
            if (!context) context = [parser context];
            [script evalWithContext:context];
            success = YES;
        }
    }
    else {
        if ([bundleIdentifier isEqual:@"nu.programming.framework"]) {
            // try to read it if it's baked in
            @try
            {
                id baked_function = [NuBridgedFunction functionWithName:[NSString stringWithFormat:@"baked_%@", fileName] signature:@"@"];
                id baked_code = [baked_function evalWithArguments:nil context:nil];
                if (!context) {
                    id parser = [Nu parser];
                    context = [parser context];
                }
                [baked_code evalWithContext:context];
                success = YES;
            }
            @catch (id exception) {
                success = NO;
            }
        }
        else {
            success = NO;
        }
    }
    [pool release];
    return success;
}

@end
