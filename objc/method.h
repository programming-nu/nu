/*!
@header method.h
@discussion Declarations for the NuMethod class,
which represents methods in the Objective-C runtime.
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
#import <Foundation/Foundation.h>
#import "objc_runtime.h"

@class NuBlock;

/*!
   @class NuMethod
   @abstract A Nu wrapper for method representations in the Objective-C runtime.
   @discussion NuMethod provides an object wrapper for methods that are represented in the Objective-C runtime.
   NuMethod objects are used in the Nu language to manipulate Objective-C methods.
 */
@interface NuMethod : NSObject
{
#ifdef DARWIN
    Method m;
#else
    Method_t m;
#endif
}

/*! Initialize a NuMethod for a given Objective-C method (used from Objective-C) */
#ifdef DARWIN
- (id) initWithMethod:(Method) method;
#else
- (id) initWithMethod:(Method_t) method;
#endif
/*! Get the name of a method. */
- (NSString *) name;
/*! Get the number of arguments to a method. */
- (int) argumentCount;
/*! Get the Objective-C type encoding of a method.  This includes offset information. */
- (NSString *) typeEncoding;
/*! Get the Objective-C type signature of a method. */
- (NSString *) signature;
/*! Get the type encoding of a specified argument of a method. */
- (NSString *) argumentType:(int) i;
/*! Get the encoded return type of a method. */
- (NSString *) returnType;
/*! If a method is implemented with Nu, get its block. */
- (NuBlock *) block;
/*! Compare a method with another method by name.  This allows arrays of methods to be easily sorted. */
- (NSComparisonResult) compare:(NuMethod *) anotherMethod;
@end
