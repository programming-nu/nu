//
//  NuBridgedConstant.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>


/*!
 @class NuBridgedConstant
 @abstract The Nu wrapper for imported C constants.
 @discussion This class can be used to import constants defined in C code.
 The signature string used to import a constant must be a valid Objective-C type signature.
 */
@interface NuBridgedConstant : NSObject {}
/*! Look up the value of a constant with specified name and type.
 The function is looked up using the <b>dlsym()</b> function.
 The returned value is of the type specified by the signature argument.
 */
+ (id) constantWithName:(NSString *) name signature:(NSString *) signature;

@end
