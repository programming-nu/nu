/*!
@header operator.h
@discussion Declarations for the NuOperator class.
Subclasses of this class provide Objective-C implementations of Nu operators.
@copyright Copyright (c) 2007 Neon Design Technology, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
#import <Foundation/Foundation.h>
extern id Nu__null; 
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
{
}
/*! Evaluate an operator with a list of arguments and an execution context. 
    This method calls callWithArguments:context: and should not be overridden.
*/
- (id) evalWithArguments:(id) cdr context:(NSMutableDictionary *) context;
/*! Call an operator with a list of arguments and an execution context. 
	This method should be overridden by implementations of new operators.
*/
- (id) callWithArguments:(id) cdr context:(NSMutableDictionary *) context;

@end
