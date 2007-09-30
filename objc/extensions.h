/*!
   @header extensions.h
   @copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
   @discussion Nu extensions to various Objective-C types.
*/

#import <Cocoa/Cocoa.h>

/*!
    @class NuZero
    @abstract Singleton class for representing zero-valued pointers.
    @discussion An instance of the NuZero class is bridged as a zero-valued (null) pointer.
    Pass it as a method argument in Nu when a call from Objective-C would send nil.
    Don't use it for anything else.
 */
@interface NuZero : NSObject
{}
/*! Get the singleton instance of NuZero. */
+ (id) zero;
@end

/*!
    @category NSNull(Nu)
    @abstract NSNull extensions for Nu programming.
    @discussion In Nu, nil is represented by <code>[NSNull null]</code>.
 */
@interface NSNull(Nu)
/*! Returns false.  In Nu, nil is not an atom. */
- (bool) atom;
/*! The length of nil is zero. */
- (int) length;
@end

/*!
    @category NSString(Nu)
    @abstract NSString extensions for Nu programming.
    @discussion NSString extensions for Nu programming.
 */
@interface NSString(Nu)
/*! Get string consisting of a single carriage return character. */
+ (id) carriageReturn;
/*!
    Evaluation operator.  In Nu, strings may contain embedded Nu expressions that are evaluated when this method is called.
    Expressions are wrapped in #{...} where the ellipses correspond to a Nu expression.
 */
- (id) evalWithContext:(NSMutableDictionary *) context;
/*! Run a shell command and return its results in a string. */
+ (NSString *) stringWithShellCommand:(NSString *) command;
@end

/*!
    @category NSNumber(Nu)
    @abstract NSNumber extensions for Nu programming.
 */
@interface NSNumber(Nu)
/*!
    Iterate a number of times corresponding to the message receiver.
    On each iteration, evaluate the given block after passing in the iteration count.
    Iteration counts begin at zero and end at n-1.
 */
- (id) times:(id) block;
@end

/*!
    @class NuMath
    @abstract A utility class that provides Nu access to common mathematical functions.
    @discussion The NuMath class provides a few common mathematical functions as class methods.
 */
@interface NuMath : NSObject {}
/*! Get the square root of a number. */
+ (double) sqrt: (double) x;
/*! Get the square of a number. */
+ (double) square: (double) x;
/*! Get the cosine of an angle. */
+ (double) cos: (double) x;
/*! Get the sine of an angle. */
+ (double) sin: (double) x;
/*! Get a random integer. */
+ (long) random;
/*! Seed the random number generator. */
+ (void) srandom:(unsigned long) seed;
@end

/*!
    @category NSBundle(Nu)
    @abstract NSBundle extensions for Nu programming.
 */
@interface NSBundle (Nu)
/*! Get or load a framework by name. */
+ (NSBundle *) frameworkWithName:(NSString *) frameworkName;
/*! Load a Nu source file from the framework's resource directory. */
- (id) loadNuFile:(NSString *) nuFileName withContext:(NSMutableDictionary *) context;
@end

/*!
    @category NSFileManager(Nu)
    @abstract NSFileManager extensions for Nu programming.
 */
@interface NSFileManager (Nu)
/*! Get the creation time for a file. */
+ (id) creationTimeForFileNamed:(NSString *) filename;
/*! Get the latest modification time for a file. */
+ (id) modificationTimeForFileNamed:(NSString *) filename;
/*! Test for the existence of a directory. */
+ (int) directoryExistsNamed:(NSString *) filename;
/*! Test for the existence of a file. */
+ (int) fileExistsNamed:(NSString *) filename;
@end

/*!
    @category NSMethodSignature(Nu)
    @abstract NSMethodSignature extensions for Nu programming.
 */
@interface NSMethodSignature (Nu)
/*! Get the type string for a method signature */
- (NSString *) typeString;
@end
