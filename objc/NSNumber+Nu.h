//
//  NSNumber+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

/*!
 @category NSNumber(Nu)
 @abstract NSNumber extensions for Nu programming.
 */
@interface NSNumber(Nu)
/*!
 Iterate a number of times corresponding to the message receiver.
 On each iteration, evaluate the given block after passing in the iteration count.
 Iteration counts begin at zero and end at n-1.
 */
- (id) times:(id) block;
/*!
 Iterate from the current value up to a specified limit.
 On each iteration, evaluate the given block after passing in the index.
 Indices begin at the receiver's value and end at the specified number.
 */
- (id) upTo:(id) number do:(id) block;
/*!
 Iterate from the current value down to a specified limit.
 On each iteration, evaluate the given block after passing in the index.
 Indices begin at the receiver's value and end at the specified number.
 */
- (id) downTo:(id) number do:(id) block;
@end
