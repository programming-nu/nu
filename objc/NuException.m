//
//  NuException.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuException.h"


#pragma mark - NuException.m

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
        NSUInteger count = [callStackSymbols count];
        for (int i = 0; i < count; i++)
        {
            [dump appendString:[callStackSymbols objectAtIndex:i]];
            [dump appendString:@"\n"];
        }
    }
    
    return dump;
}

@end


static void Nu_defaultExceptionHandler(NSException* e)
{
    [e dump];
}

static BOOL NuException_verboseExceptionReporting = NO;

@interface NuException ()
{
    NSMutableArray* stackTrace;
}
@end

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
    NuTraceInfo* traceInfo = [[[NuTraceInfo alloc] initWithFunction:function
                                                         lineNumber:line
                                                           filename:filename]
                              autorelease];
    [stackTrace addObject:traceInfo];
    
    return self;
}

- (NSString *)stringValue
{
    return [self reason];
}


- (NSString*)dumpExcludingTopLevelCount:(NSUInteger)topLevelCount
{
    NSMutableString* dump = [NSMutableString stringWithString:@"Nu uncaught exception: "];
    
    [dump appendString:[NSString stringWithFormat:@"%@: %@\n", [self name], [self reason]]];
    
    NSUInteger count = [stackTrace count] - topLevelCount;
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

@interface NuTraceInfo ()
{
    NSString*   filename;
    int         lineNumber;
    NSString*   function;
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
