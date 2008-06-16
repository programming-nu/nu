/*!
@header nuinternals.h
@discussion Internal declarations for Nu.
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

// Execution contexts are NSMutableDictionaries that are keyed by
// symbols.  Here we define two string keys that allow us to store
// some extra information in our contexts.

// Use this key to get the symbol table from an execution context.

#ifdef LINUX
#define bool char
#endif

#define SYMBOLS_KEY @"symbols"

// Use this key to get the parent context of an execution context.
#define PARENT_KEY @"parent"

#import <Foundation/Foundation.h>

/*!
    @class NuBreakException
    @abstract Internal class used to implement the Nu break operator.
 */
@interface NuBreakException : NSException {}
@end

/*!
    @class NuContinueException
    @abstract Internal class used to implement the Nu continue operator.
 */
@interface NuContinueException : NSException {}
@end

/*!
    @class NuReturnException
    @abstract Internal class used to implement the Nu return operator.
 */
@interface NuReturnException : NSException {
    id value;
}

@end

// use this to test a value for "truth"
bool nu_valueIsTrue(id value);

// use this to remember that instance variables created by Nu must be released when their owner is deallocated.
void nu_registerIvarForRelease(Class c, NSString *name);

// use this to get the instance variables that should be released.
NSArray *nu_ivarsToRelease(Class c);
