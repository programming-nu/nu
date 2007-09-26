/*!
    @header enumerable.h
  	@copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
  	@discussion Declarations for the NuEnumerable mixin class.
*/
#import <Cocoa/Cocoa.h>
#import "cell.h"
#import "block.h"

/*! 
	@class NuEnumerable
	@abstract The NuEnumerable mixin class.
	@discussion This class implements methods that act on enumerated collections of objects.
	It is designed to be mixed into a class using the include method that Nu adds to NSObject.
	The receiving class must have an objectEnumerator method that returns an NSEnumerator.
 */
@interface NuEnumerable : NSObject
{
}

/*! Iterate over each member of a collection, evaluating the provided block for each member. */
- (id) each:(NuBlock *) block;
/*! Iterate over each member of a collection, evaluating the provided block for each member. 
    The block is expected to take two arguments: the member and its index. */
- (id) eachWithIndex:(NuBlock *) block;
/*! Iterate over each member of a collection, returning a list containing the elements for which the provided block evaluates non-nil. */
- (id) select:(NuBlock *) block;
/*! Iterate over each member of a collection, returning the first element for which the provided block evaluates non-nil. */
- (id) find:(NuBlock *) block;
/*! Iterate over each member of a collection, applying the provided block to each member, and returning a list of the results. */
- (id) map:(NuBlock *) block;
/*! Iterate over each member of a collection, using the provided block to combine members into a single return value. */
- (id) reduce:(NuBlock *) block from:(id) initial;
@end