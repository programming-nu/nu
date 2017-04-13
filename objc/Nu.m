/*!
 @file Nu.m
 @description Nu.
 @copyright Copyright (c) 2007-2011 Radtastical Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
#define _GNU_SOURCE 1

#import <Foundation/Foundation.h>
#import <unistd.h>

#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#define NSRect CGRect
#define NSPoint CGPoint
#define NSSize CGSize
#endif

#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <stdint.h>
#import <math.h>
#import <time.h>
#import <sys/stat.h>
#import <sys/mman.h>

#ifdef DARWIN
#import <mach/mach.h>
#import <mach/mach_time.h>
#endif

#if !TARGET_OS_IPHONE
#import <readline/readline.h>
#import <readline/history.h>
#endif

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_IPHONE
#import "ffi.h"
#else
#ifdef DARWIN
#import <ffi/ffi.h>
#else
#import <x86_64-linux-gnu/ffi.h>
#endif
#endif

#import <dlfcn.h>

#import "Nu.h"
#import "NuInternals.h"
#import "NuReference.h"
#import "NuPointer.h"
#import "NSDictionary+Nu.h"
#import "NuEnumerable.h"
#import "NuException.h"
#import "NuBridge.h"
#import "NuBridgedFunction.h"
#import "NuClass.h"

#ifdef LINUX
id loadNuLibraryFile(NSString *nuFileName, id parser, id context, id symbolTable);
#endif


#pragma mark - NuMain

id Nu__null = 0;

bool nu_valueIsTrue(id value)
{
    bool result = value && (value != Nu__null);
    if (result && nu_objectIsKindOfClass(value, [NSNumber class])) {
        if ([value doubleValue] == 0.0)
            result = false;
    }
    return result;
}

@interface NuApplication : NSObject
{
    NSMutableArray *arguments;
}

@end

@implementation NuApplication

+ (NuApplication *) sharedApplication
{
    static NuApplication *_sharedApplication = 0;
    if (!_sharedApplication)
        _sharedApplication = [[NuApplication alloc] init];
    return _sharedApplication;
}

- (void) setArgc:(int) argc argv:(const char *[])argv startingAtIndex:(int) start
{
    arguments = [[NSMutableArray alloc] init];
    int i;
    for (i = start; i < argc; i++) {
        [arguments addObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
    }
}

- (NSArray *) arguments
{
    return arguments;
}

@end

int NuMain(int argc, const char *argv[])
{
    @autoreleasepool {
        NuInit();
        
        @try
        {
            // first we try to load main.nu from the application bundle.
            NSString *main_path = [[NSBundle mainBundle] pathForResource:@"main" ofType:@"nu"];
            if (main_path) {
                NSString *main_nu = [NSString stringWithContentsOfFile:main_path encoding:NSUTF8StringEncoding error:NULL];
                if (main_nu) {
                    NuParser *parser = [Nu sharedParser];
                    id script = [parser parse:main_nu asIfFromFilename:[main_nu UTF8String]];
                    [parser eval:script];
                    [parser release];
                    return 0;
                }
            }
            // if that doesn't work, use the arguments to decide what to execute
            else if (argc > 1) {
                NuParser *parser = [Nu sharedParser];
                id script, result;
                bool didSomething = false;
                bool goInteractive = false;
                int i = 1;
                bool fileEvaluated = false;           // only evaluate one filename
                while ((i < argc) && !fileEvaluated) {
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
                    else if (!strcmp(argv[i], "-v")) {
                        printf("Nu %s (%s)\n", NU_VERSION, NU_RELEASE_DATE);
                        didSomething = true;
                    }
                    else if (!strcmp(argv[i], "-i")) {
                        goInteractive = true;
                    }
                    else {
                        // collect the command-line arguments
                        [[NuApplication sharedApplication] setArgc:argc argv:argv startingAtIndex:i+1];
                        id string = [NSString stringWithContentsOfFile:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding] encoding:NSUTF8StringEncoding error:NULL];
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
                    i++;
                }
#if !TARGET_OS_IPHONE
                if (!didSomething || goInteractive)
                    [parser interact];
#endif
                [parser release];
                return 0;
            }
            // if there's no file, run at the terminal
            else {
                if (!isatty(fileno(stdin)))
                {
                    NuParser *parser = [Nu sharedParser];
                    id string = [[NSString alloc] initWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
                    id script = [parser parse:string asIfFromFilename:"stdin"];
                    [parser eval:script];
                    [parser release];
                }
                else {
#if !TARGET_OS_IPHONE
                    return [NuParser main];
#endif
                }
            }
        }
        @catch (NuException* nuException)
        {
            printf("%s\n", [[nuException dump] UTF8String]);
        }
        @catch (id exception)
        {
            NSLog(@"Terminating due to uncaught exception (below):");
            NSLog(@"%@: %@", [exception name], [exception reason]);
        }
        
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
    static BOOL initialized = NO;
    if (initialized) {
        return;
    }
    initialized = YES;
    @autoreleasepool {
        // as a convenience, we set a file static variable to nil.
        Nu__null = [NSNull null];
        
        // add enumeration to collection classes
        [NSArray include: [NuClass classWithClass:[NuEnumerable class]]];
        [NSSet include: [NuClass classWithClass:[NuEnumerable class]]];
        [NSString include: [NuClass classWithClass:[NuEnumerable class]]];
        
        // create "<<" messages that append their arguments to arrays, sets, and strings
        id parser = [Nu sharedParser];
        [[NuClass classWithClass:[NSMutableArray class]]
         addInstanceMethod:@"<<"
         signature:@"v*"
         body:[parser eval:[parser parse:@"(do (value) (self addObject:value))"]]];
        [[NuClass classWithClass:[NSMutableSet class]]
         addInstanceMethod:@"<<"
         signature:@"v*"
         body:[parser eval:[parser parse:@"(do (value) (self addObject:value))"]]];
        [[NuClass classWithClass:[NSMutableString class]]
         addInstanceMethod:@"<<"
         signature:@"v*"
         body:[parser eval:[parser parse:@"(do (object) (self appendString:(object stringValue)))"]]];
        
        // Copy some useful methods from NSObject to NSProxy.
        // Their implementations are identical; this avoids code duplication.
        transplant_nu_methods([NSProxy class], [NSObject class]);
        
        // swizzle container classes to allow us to add nil to collections (as NSNull).
        nu_swizzleContainerClasses();
        
#if !defined(MININUSH) && !TARGET_OS_IPHONE
        // Load some standard files
        [Nu loadNuFile:@"nu"            fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        [Nu loadNuFile:@"bridgesupport" fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        [Nu loadNuFile:@"cocoa"         fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
        [Nu loadNuFile:@"help"          fromBundleWithIdentifier:@"nu.programming.framework" withContext:nil];
#ifdef LINUX
        loadNuLibraryFile(@"nu", parser, [parser context], [parser symbolTable]);
#endif
#endif
    }
}


#import "NuRegex.h"

// Helpers for programmatic construction of Nu code.

id _nunull()
{
    return [NSNull null];
}

id _nustring(const unsigned char *string)
{
    return [NSString stringWithCString:(const char *) string encoding:NSUTF8StringEncoding];
}

id _nustring_with_length(const unsigned char *string, int length)
{
	NSData *data = [NSData dataWithBytes:string length:length];
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

id _nudata(const void *bytes, int length)
{
	return [NSData dataWithBytes:bytes length:length];
}

id _nusymbol(const unsigned char *cstring)
{
    return [[NuSymbolTable sharedSymbolTable] symbolWithString:_nustring(cstring)];
}

id _nusymbol_with_length(const unsigned char *string, int length)
{
	return [[NuSymbolTable sharedSymbolTable] symbolWithString:_nustring_with_length(string, length)];
}

id _nunumberd(double d)
{
    return [NSNumber numberWithDouble:d];
}

id _nucell(id car, id cdr)
{
    return [NuCell cellWithCar:car cdr:cdr];
}

id _nuregex(const unsigned char *pattern, int options)
{
    return [NSRegularExpression regexWithPattern:_nustring(pattern) options:options];
}

id _nuregex_with_length(const unsigned char *pattern, int length, int options)
{
    return [NSRegularExpression regexWithPattern:_nustring_with_length(pattern, length) options:options];
}

id _nulist(id firstObject, ...)
{
    id list = nil;
    id eachObject;
    va_list argumentList;
    if (firstObject) {
        // The first argument isn't part of the varargs list,
        // so we'll handle it separately.
        list = [[[NuCell alloc] init] autorelease];
        [list setCar:firstObject];
        id cursor = list;
        va_start(argumentList, firstObject);
        // Start scanning for arguments after firstObject.
        // As many times as we can get an argument of type "id"
        // that isn't nil, add it to self's contents.
        while ((eachObject = va_arg(argumentList, id))) {
            [cursor setCdr:[[[NuCell alloc] init] autorelease]];
            cursor = [cursor cdr];
            [cursor setCar:eachObject];
        }
        va_end(argumentList);
    }
    return list;
}

@implementation Nu
+ (NuParser *) parser
{
    return [[[NuParser alloc] init] autorelease];
}

+ (NuParser *) sharedParser
{
    static NuParser *sharedParser = nil;
    if (!sharedParser) {
        sharedParser = [[NuParser alloc] init];
    }
    return sharedParser;
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
        NSString *fileNu = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:NULL];
        if (fileNu) {
            NuParser *parser = [Nu sharedParser];
            id script = [parser parse:fileNu asIfFromFilename:[filePath UTF8String]];
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
                    NuParser *parser = [Nu parser];
                    context = [parser context];
                }
                [baked_code evalWithContext:context];
                success = YES;
            }
            @catch (id exception)
            {
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


