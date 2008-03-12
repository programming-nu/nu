/*!
@header block.h
@discussion Declarations for the NuBlock class. 
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

@class NuCell;

/*!
	@class NuBlock
	@abstract The Nu representation of functions.
	@discussion A Nu Block is an anonymous function with a saved execution context.
	This is commonly referred to as a closure.
	
	In Nu programs, blocks may be directly created using the <b>do</b> operator. 
	Since blocks are objects, they may be passed as method and function arguments and may be assigned to names.   
	When a block is assigned to a name, the block will be called when a list is evaluated that
	contains that name at its head; 
	the remainder of the list will be evaluated and passed to the block as the block's arguments. 
	
	Blocks are implicitly created by several other operators.
	
	The Nu <b>function</b> operator uses blocks to create new named functions.
	
	The Nu <b>macro</b> operator uses blocks to create macros.  
	Since macros evaluate in their callers' contexts, no context information is kept for blocks used to create macros.
	
	The <b>imethod</b> and <b>cmethod</b> operators use blocks to create new method implementations.
	When a block is called as a method implementation, its context includes the symbols
	<b>self</b> and <b>super</b>. This allows method implementations to send messages to
	the owning object and its superclass.  
 */
@interface NuBlock : NSObject
{
	NuCell *parameters;
    NuCell *body;
	NSMutableDictionary *context;
}

/*! Create a block.  Requires a list of parameters, the code to be executed, and an execution context. */
- (id) initWithParameters:(NuCell *)a body:(NuCell *)b context:(NSMutableDictionary *)c;
/*! Get the list of parameters required by the block. */
- (NuCell *) parameters;
/*! Get the body of code that is evaluated during block evaluation. */
- (NuCell *) body;
/*! Get the lexical context of the block.  
	This is a dictionary containing the symbols and associated values at the point 
	where the block was created. */
- (NSMutableDictionary *) context;
/*! Evaluate a block using the specified arguments and calling context. */
- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context;
/*! Evaluate a block using the specified arguments, calling context, and owner.
    This is the mechanism used to evaluate blocks as methods. */
- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context self:(id)object;
/*! Get a string representation of the block. */
- (NSString *) stringValue;

@end
