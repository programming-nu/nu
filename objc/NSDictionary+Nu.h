//
//  NSDictionary+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>


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

@end