/*!
@header exception.h
@discussion Declarations for the NuException class. 
@copyright Copyright (c) 2007 Neon Design Technology, Inc.

Original version by Peter Quade <pq@pqua.de>
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
#import <Foundation/Foundation.h>

@class NuCell;


@interface NSException (NuStackTrace)
- (NSString*)dump;
@end


/*!
	@class NuException
	@abstract When something goes wrong in Nu.
	@discussion A Nu Exception is a subclass of NSException, representing
	errors during execution of Nu code. It has the ability to store trace information.
	This information get's added during unwinding the stack by the NuCells.
 */
@interface NuException : NSException
{
    NSMutableArray* stackTrace;
}

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
- (NSString*)dumpExcludingTopLevelCount:(int)count;

@end


/*! FIXME: doc */
@interface NuTraceInfo : NSObject
{
    NSString*   filename;
    int         lineNumber;
    NSString*   function;
}

- (id)initWithFunction:(NSString *)function lineNumber:(int)lineNumber filename:(NSString *)filename;

- (NSString *)filename;
- (int)lineNumber;
- (NSString *)function;

@end
