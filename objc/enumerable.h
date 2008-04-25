/*!
@header enumerable.h
@discussion Declarations for the NuEnumerable mixin class.
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
/*! Iterate over each member of a collection, returning an array containing the elements for which the provided block evaluates non-nil. */
- (NSArray *) select:(NuBlock *) block;
/*! Iterate over each member of a collection, returning the first element for which the provided block evaluates non-nil. */
- (id) find:(NuBlock *) block;
/*! Iterate over each member of a collection, applying the provided block to each member, and returning an array of the results. */
- (NSArray *) map:(NuBlock *) block;
/*! Iterate over each member of a collection, using the provided block to combine members into a single return value. 
    The block is expected to take two arguments: the accumulated return value followed by the collection member.
*/
- (id) reduce:(NuBlock *) block from:(id) initial;
/*! Iterate over each member of a collection, applying the provided selector to each member, and returning an array of the results. */
- (NSArray *) mapSelector:(SEL) selector;
@end

@interface NSArray (Enumeration)
/*! Repeatedly apply a function of two arguments to the elements of an array,
working from right to left and beginning with the specified inital value. */
- (id) reduceLeft:(NuBlock *) block from:(id) initial;
/*! Iterate over each member of an array in reverse order and beginning with the lastObject, evaluating the provided block for each member. */
- (id) eachInReverse:(NuBlock *) block;
/*! Return a sorted array using the specified block to compare array elements.
The block should return -1, 0, or 1. */
- (NSArray *) sortedArrayUsingBlock:(NuBlock *) block;
@end
