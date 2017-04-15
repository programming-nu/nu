//
//  NuMacro.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>


#import "NuSymbol.h"
#import "NuInternals.h"

@class NuCell;

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

