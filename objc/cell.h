/*!
@header cell.h
@discussion Declarations for Nu cells. In Lisp, these cells are called "cons" cells.
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

#ifdef LINUX
#define bool char
#endif

#import <Foundation/Foundation.h>
@class NuBlock;

/*!
    @class NuCell
    @abstract The building blocks of lists.
    @discussion  NuCells are used to build lists and accept several powerful messages for list manipulation.
    In Lisp, these are called "cons" cells after the function used to create them.

    Each NuCell contains pointers to two objects, which for historical reasons are called its "car" and "cdr".
    These pointers can point to objects of any Objective-C class,
    which includes other NuCells.  Typically, the car of a NuCell points to a member of a list and
    its cdr points to another NuCell that is the head of the remainder of the list.
    The cdr of the last element in a list is nil.
In Nu, nil is represented with the <code>[NSNull null]</code> object.
*/
@interface NuCell : NSObject <NSCoding>
{
    id car;
    id cdr;
    int file;
    int line;
}

/*! Create a new cell with a specifed car and cdr. */
+ (id) cellWithCar:(id)car cdr:(id)cdr;
/*! Get the car of a NuCell. */
- (id) car;
/*! Get the cdr of a NuCell. */
- (id) cdr;
/*! Set the car of a NuCell. */
- (void) setCar:(id) c;
/*! Set the cdr of a NuCell. */
- (void) setCdr:(id) c;
/*! Get the last object in a list by traversing the list. Use this carefully. */
- (id) lastObject;
/*! Get a string representation of a list. In many cases, this can be parsed to produce the original list. */
- (NSMutableString *) stringValue;
/*! Treat the NuCell as the head of a list of Nu expressions and evaluate those expressions. */
- (id) evalWithContext:(NSMutableDictionary *)context;
/*! Returns false. NuCells are not atoms. Also, nil is not an atom. But everything else is. */
- (bool) atom;
/*! Get any comments that were associated with a NuCell in its Nu source file. */
- (id) comments;
/*! Iterate over each element of the list headed by a NuCell, calling the specified block with the element as an argument. */
- (id) each:(NuBlock *) block;
/*! Iterate over each pair of elements of the list headed by a NuCell, calling the specified block with the two elements as arguments. */
- (id) eachPair:(NuBlock *) block;
/*! Iterate over each element of the list headed by a NuCell, calling the specified block with the element and its index as arguments. */
- (id) eachWithIndex:(NuBlock *) block;
/*! Iterate over each element of the list headed by a NuCell, returning a list containing the elements for which the provided block evaluates non-nil. */
- (id) select:(NuBlock *) block;
/*! Iterate over each element of the list headed by a NuCell, returning the first element for which the provided block evaluates non-nil. */
- (id) find:(NuBlock *) block;
/*! Iterate over each element of the list headed by a NuCell, applying the provided block to each element, and returning a list of the results. */
- (id) map:(NuBlock *) block;
/*! Iterate over each element of the list headed by a NuCell, using the provided block to combine elements into a single return value. */
- (id) reduce:(NuBlock *) block from:(id) initial;
/*! Get the length of a list beginning at a NuCell. */
- (int) length;
/*! Get the number of elements in a list. Synonymous with length. */
- (int) count;

- (void) setFile:(int) f line:(int) l;
- (int) file;
- (int) line;

- (void)encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *)coder;

@end

/*!
    @class NuCellWithComments
    @abstract A cell with annotated comments.
    @discussion To simplify programmatic analysis of Nu code,
    the Nu parser can optionally attach the comments preceding a list element to an instance of this subclass of NuCell.
    Comments can then be parsed with Nu code, typically to produce documentation.
 */
@interface NuCellWithComments : NuCell
{
    id comments;
}

/*! Get a string containing the comments that preceded a list element. */
- (id) comments;
/*! Set the comments string for a list element. */
- (void) setComments:(id) comments;
@end

extern id Nu__null;
#define IS_NOT_NULL(xyz) ((xyz) && (((id) (xyz)) != Nu__null))
