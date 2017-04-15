//
//  NuBridgedFunction.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

#import "NuOperators.h"

/*!
 @class NuBridgedFunction
 @abstract The Nu wrapper for imported C functions.
 @discussion Instances of this class wrap functions imported from C.
 
 Because NuBridgedFunction is a subclass of NuOperator, Nu expressions that
 begin with NuBridgedFunction instances are treated as operator calls.
 
 In general, operators may or may not evaluate their arguments,
 but for NuBridgedFunctions, all arguments are evaluated.
 The resulting values are then passed to the bridged C function
 using the foreign function interface (libFFI).
 
 The C function's return value is converted into a Nu object and returned.
 
 Here is an example showing the use of this class from Nu.
 The example imports and calls the C function <b>NSApplicationMain</b>.
 
 <div style="margin-left:2em;">
 <code>
 (set NSApplicationMain<br/>
 &nbsp;&nbsp;&nbsp;&nbsp;(NuBridgedFunction<br/>
 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;functionWithName:"NSApplicationMain" <br/>
 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;signature:"ii^*"))<br/><br/>
 (NSApplicationMain 0 nil)
 </code>
 </div>
 
 The signature string used to create a NuBridgedFunction must be a valid Objective-C type signature.
 In the future, convenience methods may be added to make those signatures easier to generate.
 But in practice, this has not been much of a problem.
 */

@interface NuBridgedFunction : NuOperator

/*! Create a wrapper for a C function with the specified name and signature.
 The function is looked up using the <b>dlsym()</b> function and the wrapper is
 constructed using libFFI. If the result of this method is assigned to a
 symbol, that symbol may be used as the name of the bridged function.
 */
+ (NuBridgedFunction *) functionWithName:(NSString *)name signature:(NSString *)signature;
/*! Initialize a wrapper for a C function with the specified name and signature.
 The function is looked up using the <b>dlsym()</b> function and the wrapper is
 constructed using libFFI. If the result of this method is assigned to a
 symbol, that symbol may be used as the name of the bridged function.
 */
- (NuBridgedFunction *) initWithName:(NSString *)name signature:(NSString *)signature;
/*! Evaluate a bridged function with the specified arguments and context.
 Arguments must be in a Nu list.
 */
- (id) evalWithArguments:(id)arguments context:(NSMutableDictionary *)context;
@end