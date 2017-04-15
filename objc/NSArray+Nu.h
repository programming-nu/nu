//
//  NSArray+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

@class NuBlock;
@class NuCell;

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

/*! Repeatedly apply a function of two arguments to the elements of an array,
 working from right to left and beginning with the specified inital value. */
- (id) reduceLeft:(id)callable from:(id) initial;

/*! Iterate over each member of an array in reverse order and beginning with the lastObject, evaluating the provided block for each member. */
- (id) eachInReverse:(id) callable;

/*! Return a sorted array using the specified block to compare array elements.
 The block should return -1, 0, or 1. */
- (NSArray *) sortedArrayUsingBlock:(NuBlock *) block;

@end

/*!
 @category NSMutableArray(Nu)
 @abstract NSMutableArray extensions for Nu programming.
 */
@interface NSMutableArray(Nu)
/*! Add the objects from the specified list to the array. */
- (void) addObjectsFromList:(id)list;
/*! Add an object to an array, automatically converting nil into [NSNull null]. */
- (void) addPossiblyNullObject:(id)anObject;
/*! Insert an object into an array, automatically converting nil into [NSNull null]. */
- (void) insertPossiblyNullObject:(id)anObject atIndex:(int)index;
/*! Replace an object in an array, automatically converting nil into [NSNull null]. */
- (void) replaceObjectAtIndex:(int)index withPossiblyNullObject:(id)anObject;
@end

