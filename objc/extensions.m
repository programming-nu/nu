/*!
@file extensions.m
@description Nu extensions to basic Objective-C types.
@copyright Copyright (c) 2007 Neon Design Technology, Inc.

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
#import "nuinternals.h"
#import "extensions.h"
#import "symbol.h"
#import "cell.h"
#import "block.h"
#import "class.h"
#import "parser.h"
#import "objc_runtime.h"
#import <stdlib.h>
#import <math.h>
#import <time.h>
#import <sys/stat.h>

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

- (BOOL) isEqual:(id) other
{
    return ((self == other) || (other == 0)) ? 1l : 0l;
}

- (const char *) cStringUsingEncoding:(NSStringEncoding) encoding
{
    return [[self stringValue] cStringUsingEncoding:encoding];
}

@end

@implementation NSArray(Nu)
+ (NSArray *) arrayWithList:(id) list
{
    NSMutableArray *a = [NSMutableArray array];
    id cursor = list;
    while (cursor && cursor != Nu__null) {
        [a addObject:[cursor car]];
        cursor = [cursor cdr];
    }
    return a;
}

@end

@implementation NSSet(Nu)
+ (NSSet *) setWithList:(id) list
{
    NSMutableSet *s = [NSMutableSet set];
    id cursor = list;
    while (cursor && cursor != Nu__null) {
        [s addObject:[cursor car]];
        cursor = [cursor cdr];
    }
    return s;
}

@end

@implementation NSDictionary(Nu)
+ (NSDictionary *) dictionaryWithList:(id) list
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    id cursor = list;
    while (cursor && (cursor != Nu__null) && ([cursor cdr]) && ([cursor cdr] != Nu__null)) {
        id key = [cursor car];
        id value = [[cursor cdr] car];
        if ([key isKindOfClass:[NuSymbol class]] && [key isLabel]) {
            [d setValue:value forKey:[key labelName]];
        }
        else {
            [d setValue:value forKey:key];
        }
        cursor = [[cursor cdr] cdr];
    }
    return d;
}

- (id) objectForKey:(id)key withDefault:(id)defaultValue
{
    id value = [self objectForKey:key];
    return value ? value : defaultValue;
}

@end

@implementation NSMutableDictionary(Nu)
- (id) lookupObjectForKey:(id)key
{
    id object = [self objectForKey:key];
    if (object) return object;
    id parent = [self objectForKey:PARENT_KEY];
    if (!parent) return nil;
    return [parent lookupObjectForKey:key];
}

#ifdef LINUX
- (void) setValue:(id) value forKey:(id) key
{
    [self setObject:value forKey:key];
}
#endif
@end

@implementation NSString(Nu)
- (id) stringValue
{
    return self;
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
        id parser = [context lookupObjectForKey:[symbolTable symbolWithString:@"_parser"]];
        result = [NSMutableString stringWithString:[components objectAtIndex:0]];
        int i;
        for (i = 1; i < [components count]; i++) {
            NSArray *parts = [[components objectAtIndex:i] componentsSeparatedByString:@"}"];
            NSString *expression = [parts objectAtIndex:0];
            // evaluate each expression
            id value = Nu__null;
            if (expression) {
                id body = [parser parse:expression];
                value = [body evalWithContext:context];
                id stringValue = [value stringValue];
                [result appendString:stringValue];
            }
            [result appendString:[parts objectAtIndex:1]];
            int j = 2;
            while (j < [parts count]) {
                [result appendString:@"}"];
                [result appendString:[parts objectAtIndex:j]];
                j++;
            }
        }
    }
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
#ifdef DARWIN
    NSPipe *input = [NSPipe new];
    [task setStandardInput:input];
    NSPipe *output = [NSPipe new];
#else
    NSPipe *input = [NSPipe pipe];
    [task setStandardInput:input];
    NSPipe *output = [NSPipe pipe];
#endif
    [task setStandardOutput:output];
    [task launch];
    [[input fileHandleForWriting] writeData:[command dataUsingEncoding:NSUTF8StringEncoding]];
    [[input fileHandleForWriting] closeFile];
    NSData *data = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
    return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

// If the last character is a newline, delete it.
- (NSString *) chomp
{
    int lastIndex = [self length] - 1;
    if (lastIndex >= 0) {
        if ([self characterAtIndex:lastIndex] == 10) {
            return [self substringWithRange:NSMakeRange(0, lastIndex)];
        }
        else {
            return self;
        }
    }
    else {
        return self;
    }
}

+ (NSString *) stringWithCharacter:(unichar) c
{
#ifdef DARWIN
    return [self stringWithFormat:@"%C", c];
#else
   return [self stringWithFormat:@"%c", (char ) c];
#endif
}

#ifdef LINUX
+ (NSString *) stringWithCString:(const char *) cString encoding:(NSStringEncoding) encoding
{
    return [[[NSString alloc] initWithCString:cString] autorelease];
}

- (const char *) cStringUsingEncoding:(NSStringEncoding) encoding
{
    return [self cString];
}
#endif
@end

@implementation NSMutableString(Nu)
- (void) appendCharacter:(unichar) c
{
#ifdef DARWIN
    [self appendFormat:@"%C", c];
#else
    [self appendFormat:@"%c", (char) c];
#endif
}

@end

@implementation NSNumber(Nu)

- (id) times:(id) block
{
    id args = [[NuCell alloc] init];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
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

@implementation NSDate(Nu)

+ dateWithTimeIntervalSinceNow:(NSTimeInterval) seconds
{
    return [[[NSDate alloc] initWithTimeIntervalSinceNow:seconds] autorelease];
}

@end

@implementation NSFileManager(Nu)

// crashes
+ (id) _timestampForFileNamed:(NSString *) filename
{
    if (filename == Nu__null) return nil;
    NSDictionary *attributes = [[NSFileManager defaultManager] fileAttributesAtPath:[filename stringByExpandingTildeInPath] traverseLink:YES];
    return [attributes valueForKey:NSFileModificationDate];
}

+ (id) creationTimeForFileNamed:(NSString *) filename
{
    if (!filename)
        return nil;
    const char *path = [[filename stringByExpandingTildeInPath] cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return nil;
    }
    #ifdef DARWIN
    return [NSDate dateWithTimeIntervalSince1970:sb.st_ctimespec.tv_sec];
    #else
    return [NSDate dateWithTimeIntervalSince1970:sb.st_ctime];
    #endif
}

+ (id) modificationTimeForFileNamed:(NSString *) filename
{
    if (!filename)
        return nil;
    const char *path = [[filename stringByExpandingTildeInPath] cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return nil;
    }
    #ifdef DARWIN
    return [NSDate dateWithTimeIntervalSince1970:sb.st_mtimespec.tv_sec];
    #else
    return [NSDate dateWithTimeIntervalSince1970:sb.st_mtime];
    #endif
}

+ (int) directoryExistsNamed:(NSString *) filename
{
    if (!filename)
        return NO;
    const char *path = [[filename stringByExpandingTildeInPath] cStringUsingEncoding:NSUTF8StringEncoding];
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
    const char *path = [[filename stringByExpandingTildeInPath] cStringUsingEncoding:NSUTF8StringEncoding];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return NO;
    }
    return (S_ISDIR(sb.st_mode) == 0) ? 1 : 0;
}

@end

@implementation NSBundle(Nu)

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
            id parser = [context lookupObjectForKey:[symbolTable symbolWithString:@"_parser"]];
            id body = [parser parse:string asIfFromFilename:[fileName cStringUsingEncoding:NSUTF8StringEncoding]];
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

#ifdef DARWIN
#ifndef IPHONE
#import <Cocoa/Cocoa.h>

@implementation NSView(Nu)

- (id) nuRetain
{
    extern void nu_disableNSLog();
    extern void nu_enableNSLog();
    // Send
    //    "NSView not correctly initialized. Did you forget to call super?”
    // into a black hole.
    nu_disableNSLog();
    id result = [self nuRetain];
    nu_enableNSLog();
    return result;
}

@end
#endif
#endif

@implementation NSMethodSignature(Nu)

- (NSString *) typeString
{
#ifdef DARWIN
    // in 10.5, we can do this:
    // return [self _typeString];
    NSMutableString *result = [NSMutableString stringWithFormat:@"%s", [self methodReturnType]];
    int i;
    int max = [self numberOfArguments];
    for (i = 0; i < max; i++) {
        [result appendFormat:@"%s", [self getArgumentTypeAtIndex:i]];
    }
    return result;
#else
    return [NSString stringWithCString:types];
#endif
}

@end

#ifdef LINUX
@implementation NXConstantString (extra)
- (const char *) cStringUsingEncoding:(NSStringEncoding) encoding
{
    return [self cString];
}

@end

@implementation NSObject (morestuff)

- (void)willChangeValueForKey:(NSString *)key
{
}

- (void)didChangeValueForKey:(NSString *)key
{
}

+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    register const char *types = NULL;

    if (aSelector == NULL)                        // invalid selector
        return nil;

    if (types == NULL) {
        // lookup method for selector
        struct objc_method *mth;
        mth = (object_is_instance(self) ?
            class_get_instance_method(self->class_pointer, aSelector)
            : class_get_class_method(self->class_pointer, aSelector));
        if (mth) types = mth->method_types;
    }

    if (types == NULL) {
        /* construct a id-signature */
        register const char *sel;
        if ((sel = sel_get_name(aSelector))) {
            register int colCount = 0;
            static char *idSigs[] = {
                "@@:", "@@:@", "@@:@@", "@@:@@@", "@@:@@@@", "@@:@@@@@",
                "@@:@@@@@@", "@@:@@@@@@", "@@:@@@@@@@", "@@:@@@@@@@@"
            };

            while (*sel) {
                if (*sel == ':')
                    colCount++;
                sel++;
            }
            types = idSigs[colCount];
        }
        else
            return nil;
    }

    //    NSLog(@"types: %s", types);
    return [NSMethodSignature signatureWithObjCTypes:types];
}

@end

const char *stringValue(id object)
{
    return [[object stringValue] cString];
}
#endif
