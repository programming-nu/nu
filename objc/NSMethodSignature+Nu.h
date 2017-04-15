//
//  NSMethodSignature+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

/*!
 @category NSMethodSignature(Nu)
 @abstract NSMethodSignature extensions for Nu programming.
 */
@interface NSMethodSignature (Nu)
/*! Get the type string for a method signature. */
- (NSString *) typeString;
@end

