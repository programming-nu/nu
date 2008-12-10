/*!
@header macro_0.h
@discussion Declarations for the NuMacro_0 class.
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
@class NuSymbolTable;

/*!
    @class NuMacro_0
    @abstract The Nu implementation of macros.
    @discussion Macros allow Nu programmers to arbitrarily extend the Nu language.

    In Nu programs, macros are defined with the <b>macro</b> operator.

    Macros are like functions, but with two important differences:

    First, macro arguments are not evaluated before the macro is called. 
    It is up to the macro implementation to decide whether and how 
    many times to evaluate each argument. When a Nu macro is evaluated,
    the <b>margs</b> name is defined and is bound to a list of
    the arguments of the macro.

	Second, macro evaluation occurs in the context of the caller. 
	This means that a macro has access to all names defined in the
	code that calls it, and that any name assignments made in a macro will
	affect the names in the calling code. To avoid unintentional
	name conflicts, any names in a macro body that begin with a double
	underscore ("__") are replaced with automatically-generated symbols
	that are guaranteed to be unique. In Lisp terminology, these generated
	symbols are called "gensyms".   
 */
@interface NuMacro_0 : NSObject
{
    NSString *name;
    NuCell *body;
	NSMutableSet *gensyms;
}
/*! Construct a macro. */
+ (id) macroWithName:(NSString *)name body:(NuCell *)body;
/*! Get the name of a macro. */
- (NSString *) name;
/*! Get the body of a macro. */
- (NuCell *) body;
/*! Get any gensyms in a macro. */
- (NSSet *) gensyms;
/*! Initialize a macro. */
- (id) initWithName:(NSString *)name body:(NuCell *)body;
/*! Get a string representation of a macro. */
- (NSString *) stringValue;
/*! Evaluate a macro. */
- (id) evalWithArguments:(id)margs context:(NSMutableDictionary *)calling_context;
/*! Expand a macro in its context. */
- (id) expand1:(id)margs context:(NSMutableDictionary *)calling_context;
/*! Insert unique gensym'd variables. */
- (id) body:(NuCell *) oldBody withGensymPrefix:(NSString *) prefix symbolTable:(NuSymbolTable *) symbolTable;
/*! Expand unquotes in macro body. */
- (id) expandUnquotes:(id) oldBody withContext:(NSMutableDictionary *) context;

@end
