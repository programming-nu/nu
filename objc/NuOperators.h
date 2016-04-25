//
//  NuOperators.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>


/*!
 @class NuOperator
 @abstract An abstract class for Nu operators.
 @discussion Like everything else in Nu, operators are represented with objects.
 Nu operators that are written in Objective-C are implemented with subclasses of this class.
 Each operator is intended to have a singleton instance that is bound to a symbol
 in a Nu symbol table.  An operator is evaluated with a call to
 its evalWithArguments:context: method.
 When they implement functions, operators evaluate their arguments,
 but many special forms exist that evaluate their arguments zero or multiple times.
 */
@interface NuOperator : NSObject

/*! Evaluate an operator with a list of arguments and an execution context.
 This method calls callWithArguments:context: and should not be overridden.
 */
- (id) evalWithArguments:(id) cdr context:(NSMutableDictionary *) context;
/*! Call an operator with a list of arguments and an execution context.
 This method should be overridden by implementations of new operators.
 */
- (id) callWithArguments:(id) cdr context:(NSMutableDictionary *) context;

@end
