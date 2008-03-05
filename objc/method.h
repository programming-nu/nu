/*!
    @header method.h
    @copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
    @discussion Declarations for the NuMethod class,
    which represents methods in the Objective-C runtime.
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
