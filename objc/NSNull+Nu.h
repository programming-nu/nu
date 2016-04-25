//
//  NSNull+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

/*!
 @category NSNull(Nu)
 @abstract NSNull extensions for Nu programming.
 @discussion In Nu, nil is represented by <code>[NSNull null]</code>.
 */
@interface NSNull(Nu)
/*! Returns false.  In Nu, nil is not an atom. */
- (bool) atom;
/*! The length of nil is zero. */
- (NSUInteger) length;
/*! count is a synonym for length. */
- (NSUInteger) count;
/*! nil converts to an empty array. */
- (NSMutableArray *) array;
@end