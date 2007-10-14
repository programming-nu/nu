// extensions.m
//  Nu extensions to basic Objective-C types.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "extensions.h"
#import "symbol.h"
#import "cell.h"
#import "block.h"
#import "class.h"
#import "parser.h"
#import <objc/objc.h>
#import <objc/objc-runtime.h>
#import <objc/objc-class.h>
#import <stdlib.h>
#import <math.h>
#import <time.h>
#import <sys/stat.h>

static id __nuzero = 0;
@implementation NuZero
+ (id) zero
{
    if (!__nuzero) __nuzero = [[self alloc] init];
    return __nuzero;
}

@end

extern id Nu__null;

@implementation NSNull(Nu)
- (bool) atom
{
    return false;
}

- (int) length
{
    return 0;
}

- (id) stringValue
{
    return @"()";
}

- (const char *) cStringUsingEncoding:(unsigned int) encoding
{
    return [[self stringValue] cStringUsingEncoding:encoding];
}

@end

@implementation NSString(Nu)
- (id) stringValue
{
    return self;
    //...    return [NSString stringWithFormat:@"\"%@\"", self];
}

- (id) evalWithContext:(NSMutableDictionary *) context
{
    NSMutableString *result;
    NSArray *components = [self componentsSeparatedByString:@"#{"];
    if ([components count] == 1) {
        result = [NSMutableString stringWithString:self];
    }
    else {
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id parser = [context objectForKey:[symbolTable symbolWithString:@"_parser"]];
        result = [NSMutableString stringWithString:[components objectAtIndex:0]];
        int i;
        for (i = 1; i < [components count]; i++) {
            NSArray *parts = [[components objectAtIndex:i] componentsSeparatedByString:@"}"];
            NSString *expression = [parts objectAtIndex:0];
            // evaluate each expression
            id value = Nu__null;
            if (expression) {
                id body = [parser parse: expression];
                value = [body evalWithContext:context];
            }
            value = [value stringValue];
            [result appendString:value];
            [result appendString:[parts objectAtIndex:1]];
            int j = 2;
            while (j < [parts count]) {
                [result appendString:@"}"];
                [result appendString:[parts objectAtIndex:j]];
                j++;
            }
        }
    }
    [result replaceOccurrencesOfString:@"\\\"" withString:@"\"" options:0 range:NSMakeRange(0, [result length])];
    return result;
}

+ (id) carriageReturn
{
    return [self stringWithCString:"\n" encoding:NSUTF8StringEncoding];
}

// Read the text output of a shell command into a string and return the string.
+ (NSString *) stringWithShellCommand:(NSString *) command
{
    NSTask *task = [NSTask new];
    [task setLaunchPath:@"/bin/sh"];
    NSPipe *input = [NSPipe new];
    [task setStandardInput:input];
    NSPipe *output = [NSPipe new];
    [task setStandardOutput:output];
    [task launch];
    [[input fileHandleForWriting] writeData:[command dataUsingEncoding:NSUTF8StringEncoding]];
    [[input fileHandleForWriting] closeFile];
    NSData *data = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

@end

@implementation NSNumber(Nu)

- (id) times:(id) block
{
    id args = [[NuCell alloc] init];
    if ([block isKindOfClass:[NuBlock class]]) {
        int x = [self intValue];
        int i;
        for (i = 0; i < x; i++) {
            [args setCar:[NSNumber numberWithInt:i]];
            [block evalWithArguments:args context:Nu__null];
        }
    }
    return self;
}

- (NSString *) hexValue
{
    int x = [self intValue];
    return [NSString stringWithFormat:@"0x%x", x];
}

@end

@implementation NuMath

+ (double) cos: (double) x {return cos(x);}
+ (double) sin: (double) x {return sin(x);}
+ (double) sqrt: (double) x {return sqrt(x);}
+ (double) square: (double) x {return x*x;}
+ (double) exp: (double) x {return exp(x);}
+ (double) log: (double) x {return log(x);}

+ (int) integerDivide:(int) x by:(int) y {return x / y;}
+ (int) integerMod:(int) x by:(int) y {return x % y;}

+ (double) abs: (double) x {return (x < 0) ? -x : x;}

+ (long) random
{
    long r = random();
    return r;
}

+ (void) srandom:(unsigned long) seed
{
    srandom(seed);
}

@end

@implementation NSDate (Nu)

+ dateWithTimeIntervalSinceNow:(NSTimeInterval) seconds
{
    return [[[NSDate alloc] initWithTimeIntervalSinceNow:seconds] autorelease];
}

@end

@implementation NSFileManager (Nu)

// crashes
+ (id) _timestampForFileNamed:(NSString *) filename
{
    if (filename == Nu__null) return nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] fileAttributesAtPath:filename traverseLink:YES];
    return [attributes valueForKey:NSFileModificationDate];
}

+ (id) creationTimeForFileNamed:(NSString *) filename
{
    if (!filename)
        return nil;
    const char *path = [filename cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:sb.st_ctimespec.tv_sec];
}

+ (id) modificationTimeForFileNamed:(NSString *) filename
{
    if (!filename)
        return nil;
    const char *path = [filename cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:sb.st_mtimespec.tv_sec];
}

+ (int) directoryExistsNamed:(NSString *) filename
{
    if (!filename)
        return NO;
    const char *path = [filename cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return NO;
    }
    return (S_ISDIR(sb.st_mode) != 0) ? 1 : 0;
}

+ (int) fileExistsNamed:(NSString *) filename
{
    if (!filename)
        return NO;
    const char *path = [filename cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return NO;
    }
    return (S_ISDIR(sb.st_mode) == 0) ? 1 : 0;
}

@end

@implementation NSBundle (Nu)

+ (NSBundle *) frameworkWithName:(NSString *) frameworkName
{
    NSBundle *framework = nil;

    // is the framework already loaded?
    NSArray *fw = [NSBundle allFrameworks];
    NSEnumerator *frameworkEnumerator = [fw objectEnumerator];
    while ((framework = [frameworkEnumerator nextObject])) {
        if ([frameworkName isEqual: [[framework infoDictionary] objectForKey:@"CFBundleName"]]) {
            return framework;
        }
    }

    // first try the current directory
    framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@.framework", frameworkName]];

    // then /Library/Frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/Frameworks/%@.framework", frameworkName]];

    // then /System/Library/Frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/System/Library/Frameworks/%@.framework", frameworkName]];

    if (framework) {
        if ([framework load])
            return framework;
    }
    return nil;
}

- (id) loadNuFile:(NSString *) nuFileName withContext:(NSMutableDictionary *) context
{
    NSString *fileName = [self pathForResource:nuFileName ofType:@"nu"];
    if (fileName) {
        NSString *string = [NSString stringWithContentsOfFile: fileName];
        id value = Nu__null;
        if (string) {
            NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
            id parser = [context objectForKey:[symbolTable symbolWithString:@"_parser"]];
            id body = [parser parse: string];
            value = [body evalWithContext:context];
            return [symbolTable symbolWithCString:"t"];
        }
        return nil;
    }
    else {
        return nil;
    }
}

@end

@implementation NSView (Nu)

- (id) nuRetain
{
    if (!self->_viewAuxiliary) {
        return [super retain];
    }
    else {
        return [self nuRetain];
    }
}

- (void) nuRelease
{
    if (!self->_viewAuxiliary) {
        return [super release];
    }
    else {
        return [self nuRelease];
    }
}

@end

@implementation NSMethodSignature (Nu)

- (NSString *) typeString
{
    // in 10.5, we can do this:
    // return [self _typeString];
    NSMutableString *result = [NSMutableString stringWithFormat:@"%s", [self methodReturnType]];
    int i;
    int max = [self numberOfArguments];
    for (i = 0; i < max; i++) {
        [result appendFormat:@"%s", [self getArgumentTypeAtIndex:i]];
    }
    return result;
}

@end
