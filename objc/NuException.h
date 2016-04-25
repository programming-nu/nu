//
//  NuException.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

#pragma mark -
#pragma mark Error Handling

/*!
 @class NuException
 @abstract When something goes wrong in Nu.
 @discussion A Nu Exception is a subclass of NSException, representing
 errors during execution of Nu code. It has the ability to store trace information.
 This information gets added during unwinding the stack by the NuCells.
 */
@interface NuException : NSException

+ (void)setDefaultExceptionHandler;
+ (void)setVerbose:(BOOL)flag;

/*! Create a NuException. */
- (id)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo;

/*! Get the stack trace. */
- (NSArray*)stackTrace;

/*! Add to the stack trace. */
- (NuException *)addFunction:(NSString *)function lineNumber:(int)line;
- (NuException *)addFunction:(NSString *)function lineNumber:(int)line filename:(NSString*)filename;

/*! Get a string representation of the exception. */
- (NSString *)stringValue;

/*! Dump the exception to stdout. */
- (NSString*)dump;

/*! Dump leaving off some of the toplevel */
- (NSString*)dumpExcludingTopLevelCount:(NSUInteger)count;

@end

@interface NuTraceInfo : NSObject

- (id)initWithFunction:(NSString *)function lineNumber:(int)lineNumber filename:(NSString *)filename;
- (NSString *)filename;
- (int)lineNumber;
- (NSString *)function;

@end

