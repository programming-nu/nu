//
//  NuEnumerable.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

@class NuBlock;

/*!
 @class NuEnumerable
 @abstract The NuEnumerable mixin class.
 @discussion This class implements methods that act on enumerated collections of objects.
 It is designed to be mixed into a class using the include method that Nu adds to NSObject.
 The receiving class must have an objectEnumerator method that returns an NSEnumerator.
 Some methods in this class take a callable object as an argument; callable objects are those
 that have evalWithArguments:context: defined.
 */
@interface NuEnumerable : NSObject

/*! Iterate over each member of a collection, evaluating the provided callable item for each member. */
- (id) each:(id) callable;
/*! Iterate over each member of a collection, evaluating the provided block for each member.
 The block is expected to take two arguments: the member and its index. */
- (id) eachWithIndex:(NuBlock *) block;
/*! Iterate over each member of a collection, returning an array containing the elements for which the provided block evaluates non-nil. */
- (NSArray *) select:(NuBlock *) block;
/*! Iterate over each member of a collection, returning the first element for which the provided block evaluates non-nil. */
- (id) find:(NuBlock *) block;
/*! Iterate over each member of a collection, applying the provided block to each member, and returning an array of the results. */
- (NSArray *) map:(id) callable;
/*! Iterate over each member of a collection, using the provided callable to combine members into a single return value.
 */
- (id) reduce:(id) callable from:(id) initial;
/*! Iterate over each member of a collection, applying the provided selector to each member, and returning an array of the results. */
- (NSArray *) mapSelector:(SEL) selector;

@end
