/*!
@header defmacro.h
@discussion Declarations for the NuDefmacro class.
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

@class NuMacro;
@class NuCell;

/*!
    @class NuDefmacro
    @abstract The Nu implementation of a Lisp-like defmacro operator.
    @discussion Macros allow Nu programmers to arbitrarily extend the Nu language.

	The <b>defmacro</b> operator works similarly to the Nu <b>macro</b>
	operator, but differs in the following ways:

	<b>defmacro</b> accepts a parameter list much like a Nu function.
	Nu's <b>macro</b> operator puts all of the parameter list into an
	implicit variable named <b>margs</b>, which the body of the macro
	must destructure manually.  <b>defmacro</b> internally uses 
	<b>dbind</b> (like Lisp's destructuring-bind) to do this.

	<b>defmacro</b> does not implicitly "quote" the body of the macro.
	Instead the <b>backquote</b> (abbreviated as '`') 
	and <b>bq-comma</b> (abbreviated as ',') operators can be
	used to write a macro body that more closely resembles the 
	generated code.

	For example, the following two macros are equivalent:
	
	(macro inc! (set (unquote (car margs)) (+ (unquote (car margs)) 1)))
	
	(defmacro inc! (n) `(set ,n (+ ,n 1)))
 */
@interface NuDefmacro : NuMacro
{
//    NSString *name;
//    NuCell *body;
//	NSMutableSet *gensyms;
}
/*! Construct a macro. */
+ (id) macroWithName:(NSString *)name body:(NuCell *)body;
/*! Initialize a macro. */
- (id) initWithName:(NSString *)name body:(NuCell *)body;
/*! Get a string representation of a macro. */
- (NSString *) stringValue;
/*! Evaluate a macro. */
- (id) evalWithArguments:(id)margs context:(NSMutableDictionary *)calling_context;
/*! Expand a macro in its context. */
- (id) expand1:(id)margs context:(NSMutableDictionary *)calling_context;
@end
