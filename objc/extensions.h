/*!
@header extensions.h
@discussion Nu extensions to various Objective-C types.
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
@class NuCell;
@class NuBlock;

#ifdef LINUX
#define bool char
#endif

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
/*! count is a synonym for length. */
- (int) count;
@end

/*!
    @category NSArray(Nu)
    @abstract NSArray extensions for Nu programming.
 */
@interface NSArray(Nu)
/*! Creates an array that contains the contents of a specified list. */
+ (NSArray *) arrayWithList:(id) list;

/*! Sort an array using its elements' compare: method. */
- (NSArray *) sort;

/*! Convert an array into a list. */
- (NuCell *) list;

@end

/*!
    @category NSMutableArray(Nu)
    @abstract NSMutableArray extensions for Nu programming.
 */
@interface NSMutableArray(Nu)
/*! Add an object to an array, automatically converting nil into [NSNull null]. */
- (void) addPossiblyNullObject:(id)anObject;
/*! Insert an object into an array, automatically converting nil into [NSNull null]. */
- (void) insertPossiblyNullObject:(id)anObject atIndex:(int)index;
/*! Replace an object in an array, automatically converting nil into [NSNull null]. */
- (void) replaceObjectAtIndex:(int)index withPossiblyNullObject:(id)anObject;
@end

/*!
    @category NSSet(Nu)
    @abstract NSSet extensions for Nu programming.
 */
@interface NSSet(Nu)
/*! Creates a set that contains the contents of a specified list. */
+ (NSSet *) setWithList:(id) list;
@end

/*!
    @category NSSet(Nu)
    @abstract NSSet extensions for Nu programming.
 */
@interface NSMutableSet(Nu)
/*! Add an object to a set, automatically converting nil into [NSNull null]. */
- (void) addPossiblyNullObject:(id)anObject;
@end

/*!
    @category NSDictionary(Nu)
    @abstract NSDictionary extensions for Nu programming.
 */
@interface NSDictionary(Nu)
/*! Creates a dictionary that contains the contents of a specified list.
    The list should be a sequence of interleaved keys and values.  */
+ (NSDictionary *) dictionaryWithList:(id) list;
/*! Look up an object by key, returning the specified default if no object is found. */
- (id) objectForKey:(id)key withDefault:(id)defaultValue;
@end

/*!
    @category NSMutableDictionary(Nu)
    @abstract NSMutableDictionary extensions for Nu programming.
    @discussion In Nu, NSMutableDictionaries are used to represent evaluation contexts.
    Context keys are NuSymbols, and the associated objects are the symbols'
    assigned values.
 */
@interface NSMutableDictionary(Nu)
/*! Looks up the value associated with a key in the current context.
    If no value is found, looks in the context's parent, continuing
    upward until no more parent contexts are found. */
- (id) lookupObjectForKey:(id)key;
/*! Add an object to a dictionary, automatically converting nil into [NSNull null]. */
- (void) setPossiblyNullObject:(id) anObject forKey:(id) aKey;
#ifdef LINUX
- (void) setValue:(id) value forKey:(id) key;
#endif
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

#ifndef IPHONE
/*! Run a shell command and return its results in a string. */
+ (NSString *) stringWithShellCommand:(NSString *) command;
#endif

/*! Create a string from a specified character */
+ (NSString *) stringWithCharacter:(unichar) c;

/*! Convert a string into a symbol. */
- (id) symbolValue;

/*! Get a representation of the string that can be used in Nu source code. */
- (NSString *) escapedStringRepresentation;

/*! Split a string into lines. */
- (NSArray *) lines;

/*! Replace a substring with another. */
- (NSString *) replaceString:(NSString *) target withString:(NSString *) replacement;

/*! Iterate over each character in a string, evaluating the provided block for each character. */
- (id) each:(NuBlock *) block;

#ifdef LINUX
+ (NSString *) stringWithCString:(const char *) cString encoding:(NSStringEncoding) encoding;
- (const char *) cStringUsingEncoding:(NSStringEncoding) encoding;
#endif
@end

/*!
    @category NSMutableString(Nu)
    @abstract NSMutableString extensions for Nu programming.
 */
@interface NSMutableString(Nu)
/*! Append a specified character to a string. */
- (void) appendCharacter:(unichar) c;
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
/*!
    Iterate from the current value up to a specified limit.
    On each iteration, evaluate the given block after passing in the index.
    Indices begin at the receiver's value and end at the specified number.
 */
- (id) upTo:(id) number do:(id) block;
/*!
    Iterate from the current value down to a specified limit.
    On each iteration, evaluate the given block after passing in the index.
    Indices begin at the receiver's value and end at the specified number.
 */
- (id) downTo:(id) number do:(id) block;
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
/*! Get the cubed root of a number. */
+ (double) cbrt: (double) x;
/*! Get the cosine of an angle. */
+ (double) cos: (double) x;
/*! Get the sine of an angle. */
+ (double) sin: (double) x;
/*! Get the largest integral value that is not greater than x.*/
+ (double) floor: (double) x;
/*! Get the smallest integral value that is greater than or equal to x.*/
+ (double) ceil: (double) x;
/*! Get the integral value nearest to x by always rounding half-way cases away from zero. */
+ (double) round: (double) x;
/*! Raise x to the power of y */
+ (double) raiseNumber: (double) x toPower: (double) y;
/*! Get the qouteint of x divided by y as an integer */
+ (int) integerDivide:(int) x by:(int) y;
/*! Get the remainder of x divided by y as an integer */
+ (int) integerMod:(int) x by:(int) y;
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
/*! Get the type string for a method signature. */
- (NSString *) typeString;
@end

#ifdef LINUX
@interface NSObject (morestuff)
- (void)willChangeValueForKey:(NSString *)key;
- (void)didChangeValueForKey:(NSString *)key;
+ (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector;
@end
#endif

/*!
   @class NuAutomaticIvars
   @abstract Include this class to get handleUnknownMessage:withContext: to emulate ivar accessors.
   @discussion This class is used inside Nu to implement the ivars operator.
 */
@interface NuAutomaticIvars : NSObject
{
}

/*! Attempt to treat unknown messages as ivar accessors. */
- (id) handleUnknownMessage:(NuCell *) message withContext:(id) context;
@end
