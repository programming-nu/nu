//
//  NSSet+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

@class NuCell;

/*!
 @category NSSet(Nu)
 @abstract NSSet extensions for Nu programming.
 */
@interface NSSet(Nu)
/*! Creates a set that contains the contents of a specified list. */
+ (NSSet *) setWithList:(id) list;
/*! Convert a set into a list. */
- (NuCell *) list;
@end

/*!
 @category NSMutableSet(Nu)
 @abstract NSSet extensions for Nu programming.
 */
@interface NSMutableSet(Nu)
/*! Add an object to a set, automatically converting nil into [NSNull null]. */
- (void) addPossiblyNullObject:(id)anObject;
@end