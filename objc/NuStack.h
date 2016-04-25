//
//  NuStack.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

/*!
 @class NuStack
 @abstract A stack class.
 @discussion A simple stack class used by the Nu parser.
 */
@interface NuStack : NSObject

/*! Push an object onto the stack. */
- (void) push:(id) object;
/*! Pop an object from the top of the stack. Return nil if the stack is empty. */
- (id) pop;
/*! Return the current stack depth. */
- (NSUInteger) depth;

@end