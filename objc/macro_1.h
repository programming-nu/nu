/*!
@header macro_1.h
@discussion Declarations for the NuMacro_1 class.
@copyright Copyright (c) 2008 Jeff Buck

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

@class NuMacro_0;
@class NuCell;

/*!
    @class NuMacro_1
    @abstract The Nu implementation of a Lisp-like macro operator.
    @discussion Macros allow Nu programmers to arbitrarily extend the Nu language.

	The <b>macro</b> operator works similarly to the Nu <b>macro-0</b>
	operator, but differs in the following ways:

	<b>macro</b> accepts a parameter list much like a Nu function.
	Nu's <b>macro</b> operator puts all of the parameter list into an
	implicit variable named <b>margs</b>, which the body of the macro
	must destructure manually.

	<b>macro</b> does not implicitly "quote" the body of the macro.
	Instead the <b>backquote</b> (abbreviated as '`') 
	and <b>bq-comma</b> (abbreviated as ',') operators can be
	used to write a macro body that more closely resembles the 
	generated code.

	For example, the following two macros are equivalent:
	
	(macro-0 inc! (set (unquote (car margs)) (+ (unquote (car margs)) 1)))
	
	(macro inc! (n) `(set ,n (+ ,n 1)))
 */
@interface NuMacro_1 : NuMacro_0
{
	NuCell *parameters;
}

/*! Construct a macro. */
+ (id) macroWithName:(NSString *)name parameters:(NuCell*)args body:(NuCell *)body;
/*! Initialize a macro. */
- (id) initWithName:(NSString *)name parameters:(NuCell *)args body:(NuCell *)body;
/*! Get a string representation of a macro. */
- (NSString *) stringValue;
/*! Evaluate a macro. */
- (id) evalWithArguments:(id)margs context:(NSMutableDictionary *)calling_context;
/*! Expand a macro in its context. */
- (id) expand1:(id)margs context:(NSMutableDictionary *)calling_context;
@end
