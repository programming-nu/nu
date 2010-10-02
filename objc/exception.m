/*!
@file exception.m
@discussion  NuException
@copyright Copyright (c) 2007 Neon Design Technology, Inc.

Added by Peter Quade <pq@pqua.de>
System stack trace support and other enhancements by Jeff Buck.

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

//#define IMPORT_EXCEPTION_HANDLING_FRAMEWORK

#ifdef IMPORT_EXCEPTION_HANDLING_FRAMEWORK
#import <ExceptionHandling/NSExceptionHandler.h>
#endif

#import "nuinternals.h"
#import "exception.h"
#import "cell.h"

#define kFilenameTopLevel @"<TopLevel>"

@implementation NSException (NuStackTrace)

- (NSString*)dump
{
    NSMutableString* dump = [NSMutableString stringWithString:@""];

    // Print the system stack trace (10.6 only)
    if ([self respondsToSelector:@selector(callStackSymbols)])
    {
        [dump appendString:@"\nSystem stack trace:\n"];

        NSArray* callStackSymbols = [self callStackSymbols];
        int count = [callStackSymbols count];
        for (int i = 0; i < count; i++)
        {
            [dump appendString:[callStackSymbols objectAtIndex:i]];
            [dump appendString:@"\n"];
        }
    }

    return dump;
}

@end


void Nu_defaultExceptionHandler(NSException* e)
{
    [e dump];
}

static BOOL NuException_verboseExceptionReporting = NO;

@implementation NuException

+ (void)setDefaultExceptionHandler
{
    NSSetUncaughtExceptionHandler(*Nu_defaultExceptionHandler);

#ifdef IMPORT_EXCEPTION_HANDLING_FRAMEWORK
    [[NSExceptionHandler defaultExceptionHandler] 
        setExceptionHandlingMask:(NSHandleUncaughtExceptionMask 
                                    | NSHandleUncaughtSystemExceptionMask 
                                    | NSHandleUncaughtRuntimeErrorMask 
                                    | NSHandleTopLevelExceptionMask 
                                    | NSHandleOtherExceptionMask)];
#endif
}

+ (void)setVerbose:(BOOL)flag
{
    NuException_verboseExceptionReporting = flag;
}


- (void) dealloc
{
    if (stackTrace)
    {
        [stackTrace removeAllObjects];
        [stackTrace release];
    }
    [super dealloc];
}

- (id)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo
{
    self = [super initWithName:name reason:reason userInfo:userInfo];
    stackTrace = [[NSMutableArray alloc] init];
    return self;
}

- (NSArray*)stackTrace
{
    return stackTrace;
}

- (NuException *)addFunction:(NSString *)function lineNumber:(int)line
{
    return [self addFunction:function lineNumber:line filename:kFilenameTopLevel];
}

- (NuException *)addFunction:(NSString *)function lineNumber:(int)line filename:(NSString *)filename
{
    NuTraceInfo* traceInfo = [[NuTraceInfo alloc] initWithFunction:function 
                                                        lineNumber:line 
                                                          filename:filename];
    [stackTrace addObject:traceInfo];

    return self;
}

- (NSString *)stringValue
{
    return [self reason];
}


- (NSString*)dumpExcludingTopLevelCount:(int)topLevelCount
{
    NSMutableString* dump = [NSMutableString stringWithString:@"Nu uncaught exception: "];
    
    [dump appendString:[NSString stringWithFormat:@"%@: %@\n", [self name], [self reason]]];

    int count = [stackTrace count] - topLevelCount;
    for (int i = 0; i < count; i++)
    {
        NuTraceInfo* trace = [stackTrace objectAtIndex:i];

        NSString* traceString = [NSString stringWithFormat:@"  from %@:%d: in %@\n",
                                    [trace filename],
                                    [trace lineNumber],
                                    [trace function]];

        [dump appendString:traceString];
    }

    if (NuException_verboseExceptionReporting)
    {
        [dump appendString:[super dump]];
    }

    return dump;
}

- (NSString*)dump
{
    return [self dumpExcludingTopLevelCount:0];
}

@end

@implementation NuTraceInfo


- (id)initWithFunction:(NSString *)aFunction lineNumber:(int)aLine filename:(NSString *)aFilename
{
    self = [super init];
    
    if (self)
    {
        filename = [aFilename retain];
        lineNumber = aLine;
        function = [aFunction retain];
    }
    return self;
}

- (void)dealloc
{
    [filename release];
    [function release];

    [super dealloc];
}

- (NSString *)filename
{
    return filename;
}

- (int)lineNumber
{
    return lineNumber;
}

- (NSString *)function
{
    return function;
}

@end
