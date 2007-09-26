/*!
   @header stack.h
   @discussion Declarations for a simple stack class.
   @copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
*/

#import <Foundation/Foundation.h>
/*!
    @class NuStack
	@abstract A stack class.
	@discussion A simple stack class used by the Nu parser.
 */
@interface NuStack : NSObject
{
    NSMutableArray *storage;
}
/*! Push an object onto the stack. */
- (void) push:(id) object;
/*! Pop an object from the top of the stack. Return nil if the stack is empty. */
- (id) pop;
/*! Return the current stack depth. */
- (int) depth;
@end
