/*!
 @header Nu.h
 @discussion Nu.
 @copyright Copyright (c) 2007-2011 Radtastical Inc.
 
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
#import <objc/objc.h>
#import <objc/runtime.h>

#pragma mark -
#pragma mark Symbol Table

/*!
 @class NuSymbol
 @abstract The Nu symbol class.
 @discussion Instances of NuSymbol are used to uniquely represent strings in parsed Nu expressions.
 NuSymbol objects are used as keys in local evaluation contexts (typically of type NSMutableDictionary)
 and each NuSymbol may also have a global value bound to it.
 Symbols ending in a colon (':') are considered "labels" which evaluate to themselves without error,
 and when a label is found at the head of the list,
 the list is considered to be a special type of list called a property list (no relation to ObjC plists).
 Each member of a property list is evaluated and the resulting list is returned with no further evaluation.
 */
@interface NuSymbol : NSObject <NSCoding>

/*! Get the global value of a symbol. */
- (id) value;
/*! Set the global value of a symbol. */
- (void) setValue:(id)v;
/*! Get an object of type NSString representing the symbol. */
- (NSString *) stringValue;
/*! Returns true if a symbol is a label. */
- (bool) isLabel;
/*! Returns true if a symbol is to be replaced by a generated symbol (which only occurs during macro evaluation). */
- (bool) isGensym;
/*! If a symbol is a label, get a string representing its name.  This string omits the final colon (':'). */
- (NSString *) labelName;
/*! Evaluate a symbol in a specified context. */
- (id) evalWithContext:(NSMutableDictionary *) context;
/*! Compare a symbol with another symbol by name.  This allows arrays of symbols to be easily sorted. */
- (NSComparisonResult) compare:(NuSymbol *) anotherSymbol;
/*! Get a description of a symbol.  This is equivalent to a call to stringValue. */
- (NSString *) description;

@end

/*!
 @class NuSymbolTable
 @abstract The Nu symbol table class.
 @discussion Instances of NuSymbolTable manage collections of NuSymbol objects.
 By default, one NuSymbolTable object is shared by all NuParser objects and execution contexts in a process.
 */
@interface NuSymbolTable : NSObject

/*! Get the shared NuSymbolTable object. */
+ (NuSymbolTable *) sharedSymbolTable;
/*! Get a symbol with the specified string. */
- (NuSymbol *) symbolWithString:(NSString *)string;
/*! Lookup a symbol in a symbol table. */
- (NuSymbol *) lookup:(NSString *) string;
/*! Get an array containing all of the symbols in a symbol table. */
- (NSArray *) all;
/*! Remove a symbol from the symbol table */
- (void) removeSymbol:(NuSymbol *) symbol;
@end

#pragma mark -
#pragma mark List Representation

/*!
 @class NuCell
 @abstract The building blocks of lists.
 @discussion  NuCells are used to build lists and accept several powerful messages for list manipulation.
 In Lisp, these are called "cons" cells after the function used to create them.
 
 Each NuCell contains pointers to two objects, which for historical reasons are called its "car" and "cdr".
 These pointers can point to objects of any Objective-C class,
 which includes other NuCells.  Typically, the car of a NuCell points to a member of a list and
 its cdr points to another NuCell that is the head of the remainder of the list.
 The cdr of the last element in a list is nil.
 In Nu, nil is represented with the <code>[NSNull null]</code> object.
 */
@interface NuCell : NSObject <NSCoding>

/*! Create a new cell with a specifed car and cdr. */
+ (id) cellWithCar:(id)car cdr:(id)cdr;
/*! Get the car of a NuCell. */
- (id) car;
/*! Get the cdr of a NuCell. */
- (id) cdr;
/*! Set the car of a NuCell. */
- (void) setCar:(id) c;
/*! Set the cdr of a NuCell. */
- (void) setCdr:(id) c;
/*! Get the last object in a list by traversing the list. Use this carefully. */
- (id) lastObject;
/*! Get a string representation of a list. In many cases, this can be parsed to produce the original list. */
- (NSMutableString *) stringValue;
/*! Treat the NuCell as the head of a list of Nu expressions and evaluate those expressions. */
- (id) evalWithContext:(NSMutableDictionary *)context;
/*! Returns false. NuCells are not atoms. Also, nil is not an atom. But everything else is. */
- (bool) atom;
/*! Get any comments that were associated with a NuCell in its Nu source file. */
- (id) comments;
/*! Iterate over each element of the list headed by a NuCell, calling the specified block with the element as an argument. */
- (id) each:(id) block;
/*! Iterate over each pair of elements of the list headed by a NuCell, calling the specified block with the two elements as arguments. */
- (id) eachPair:(id) block;
/*! Iterate over each element of the list headed by a NuCell, calling the specified block with the element and its index as arguments. */
- (id) eachWithIndex:(id) block;
/*! Iterate over each element of the list headed by a NuCell, returning a list containing the elements for which the provided block evaluates non-nil. */
- (id) select:(id) block;
/*! Iterate over each element of the list headed by a NuCell, returning the first element for which the provided block evaluates non-nil. */
- (id) find:(id) block;
/*! Iterate over each element of the list headed by a NuCell, applying the provided block to each element, and returning a list of the results. */
- (id) map:(id) block;
/*! Iterate over each element of the list headed by a NuCell, using the provided block to combine elements into a single return value. */
- (id) reduce:(id) block from:(id) initial;
/*! Get the length of a list beginning at a NuCell. */
- (NSUInteger) length;
/*! Get the number of elements in a list. Synonymous with length. */
- (NSUInteger) count;
/*! Get an array containing the elements of a list. */
- (NSMutableArray *) array;

- (void) setFile:(int) f line:(int) l;
- (int) file;
- (int) line;

- (void)encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *)coder;

@end

/*!
 @class NuCellWithComments
 @abstract A cell with annotated comments.
 @discussion To simplify programmatic analysis of Nu code,
 the Nu parser can optionally attach the comments preceding a list element to an instance of this subclass of NuCell.
 Comments can then be parsed with Nu code, typically to produce documentation.
 */
@interface NuCellWithComments : NuCell

/*! Get a string containing the comments that preceded a list element. */
- (id) comments;
/*! Set the comments string for a list element. */
- (void) setComments:(id) comments;

@end

#pragma mark -
#pragma mark Parsing

/*!
 @class NuStack
 @abstract A stack class.
 @discussion A simple stack class used by the Nu parser.
 */
@interface NuStack : NSObject

/*! Push an object onto the stack. */
- (void) push:(id) object;
/*! Pop an object from the top of the stack. Return nil if the stack is empty. */
- (id) pop;
/*! Return the current stack depth. */
- (NSUInteger) depth;

@end

/*!
 @class NuParser
 @abstract A Nu language parser.
 @discussion Instances of this class are used to parse and evaluate Nu source text.
 */
@interface NuParser : NSObject

/*! Get the symbol table used by a parser. */
- (NuSymbolTable *) symbolTable;
/*! Get the top-level evaluation context that a parser uses for evaluation. */
- (NSMutableDictionary *) context;
/*! Parse Nu source into an expression, returning the NuCell at the top of the resulting expression.
 Since parsing may produce multiple expressions, the top-level NuCell is a Nu <b>progn</b> operator.
 */
- (id) parse:(NSString *)string;
/*! Call -parse: while specifying the name of the source file for the string to be parsed. */
- (id) parse:(NSString *)string asIfFromFilename:(const char *) filename;
/*! Evaluate a parsed Nu expression in the parser's evaluation context. */
- (id) eval: (id) code;
/*! Parse Nu source text and evaluate it in the parser's evalation context. */
- (NSString *) parseEval:(NSString *)string;
/*! Get the value of a name or expression in the parser's context. */
- (id) valueForKey:(NSString *)string;
/*! Set the value of a name in the parser's context. */
- (void) setValue:(id)value forKey:(NSString *)string;
/*! Returns true if the parser is currently parsing an incomplete Nu expression.
 Presumably the rest of the expression will be passed in with a future
 invocation of the parse: method.
 */
- (BOOL) incomplete;
/*! Reset the parse set after an error */
- (void) reset;

#if !TARGET_OS_IPHONE
/*! Run a parser interactively at the console (Terminal.app). */
- (int) interact;
/*! Run the main handler for a console(Terminal.app)-oriented Nu shell. */
+ (int) main;
#endif

@end

#pragma mark -
#pragma mark Callables: Functions, Macros, Operators

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
 
 When used in a class context, the <b>-</b> and <b>+</b> operators 
 use blocks to create new method implementations.
 When a block is called as a method implementation, its context includes the symbols
 <b>self</b> and <b>super</b>. This allows method implementations to send messages to
 the owning object and its superclass.
 */
@interface NuBlock : NSObject

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

#pragma mark -
#pragma mark Bridging C

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

#ifdef __BLOCKS__
/*!
 @class NuBridgedBlock
 @abstract Generates a C block that wraps a nu block
 @discussion This class makes a C block that wraps a nu block using a supplied
 Objective-C-style function signature. This works by copying a dummy c block and
 then writing over its function pointer with a libFFI-generated closure function.
 */
@interface NuBridgedBlock : NSObject

/*! Returns a C block that wraps the supplied nu block using the supplied
 Objective-C-style function signature.
 */
+(id)cBlockWithNuBlock:(NuBlock*)nb signature:(NSString*)sig;

/*! Initializes a NuBridgedBlock object using a NuBlock and an Objective-C-style
 function signature. A C block is generated during the initialization.
 */
-(id)initWithNuBlock:(NuBlock*)nb signature:(NSString*)sig;

/*! Returns the NuBlock associated with the NuBridgedBlock object.
 */
-(NuBlock*)nuBlock;

/*! Returns the C block generated by the NuBridgedBlock object.
 */
-(id)cBlock;

@end
#endif //__BLOCKS__

#pragma mark -
#pragma mark Wrapping access to items and objects in memory

/*!
 @class NuPointer
 @abstract The Nu pointer wrapper.
 @discussion The NuPointer class provides a wrapper for pointers to arbitrary locations in memory.
 */
@interface NuPointer : NSObject

/*! Get the value of the pointer. Don't call this from Nu. */
- (void *) pointer;
/*! Set the pointer.  Used by the bridge to create NuReference objects from pointers.  Don't call this from Nu. */
- (void) setPointer:(void *) pointer;
/*! Set the type of a pointer. This should be an Objective-C type encoding that begins with a "^". */
- (void) setTypeString:(NSString *) typeString;
/*! Get an Objective-C type string describing the pointer target. */
- (NSString *) typeString;
/*! Assume the pointer is a pointer to an Objective-C object. Get the object. You had better be right, or this will crash. */
- (id) object;
/*! Get the value of the pointed-to object, using the typeString to determine the correct type */
- (id) value;
/*! Helper function, used internally to reserve space for data of a specified type. */
- (void) allocateSpaceForTypeString:(NSString *) s;
@end

/*!
 @class NuReference
 @abstract The Nu object wrapper.
 @discussion The NuReference class provides a wrapper for pointers to Objective-C objects.
 NuReference objects are used in the Nu language to capture arguments that are returned by value from Objective-C methods.
 For example, the following Nu method uses a NuReference to capture a returned-by-reference NSError:
 
 <div style="margin-left:2em">
 <code>
 (- (id) save is<br/>
 &nbsp;&nbsp;(set perror ((NuReference alloc) init))<br/>
 &nbsp;&nbsp;(set result ((self managedObjectContext) save:perror))<br/>
 &nbsp;&nbsp;(unless result<br/>
 &nbsp;&nbsp;&nbsp;&nbsp;(NSLog "error: #{((perror value) localizedDescription)}"))<br/>
 &nbsp;&nbsp;result)
 </code>
 </div>
 */
@interface NuReference : NSObject

/*! Get the value of the referenced object. */
- (id) value;
/*! Set the value of the referenced object. */
- (void) setValue:(id) value;
/*! Set the pointer for a reference.  Used by the bridge to create NuReference objects from pointers.  Don't call this from Nu. */
- (void) setPointer:(id *) pointer;
/*! Get a pointer to the referenced object. Used by the bridge to Objective-C to convert NuReference objects to pointers.
 Don't call this from Nu.
 */
- (id *) pointerToReferencedObject;
/*! Retain the referenced object. Used by the bridge to Objective-C to retain values returned by reference. */
- (void) retainReferencedObject;
@end

#pragma mark -
#pragma mark Interacting with the Objective-C Runtime

/*!
 @class NuMethod
 @abstract A Nu wrapper for method representations in the Objective-C runtime.
 @discussion NuMethod provides an object wrapper for methods that are represented in the Objective-C runtime.
 NuMethod objects are used in the Nu language to manipulate Objective-C methods.
 */
@interface NuMethod : NSObject

/*! Initialize a NuMethod for a given Objective-C method (used from Objective-C) */
- (id) initWithMethod:(Method) method;
/*! Get the name of a method. */
- (NSString *) name;
/*! Get the number of arguments to a method. */
- (int) argumentCount;
/*! Get the Objective-C type encoding of a method.  This includes offset information. */
- (NSString *) typeEncoding;
/*! Get the Objective-C type signature of a method. */
- (NSString *) signature;
/*! Get the type encoding of a specified argument of a method. */
- (NSString *) argumentType:(int) i;
/*! Get the encoded return type of a method. */
- (NSString *) returnType;
/*! If a method is implemented with Nu, get its block. */
- (NuBlock *) block;
/*! Compare a method with another method by name.  This allows arrays of methods to be easily sorted. */
- (NSComparisonResult) compare:(NuMethod *) anotherMethod;
@end

/*!
 @class NuClass
 @abstract A Nu wrapper for class representations in the Objective-C runtime.
 @discussion NuClass provides an object wrapper for classes that are represented in the Objective-C runtime.
 NuClass objects are used in the Nu language to manipulate and extend Objective-C classes.
 */
@interface NuClass : NSObject

/*! Create a class wrapper for the specified class (used from Objective-C). */
+ (NuClass *) classWithClass:(Class) class;
/*! Create a class wrapper for the named Objective-C class. */
+ (NuClass *) classWithName:(NSString *)string;
/*! Initialize a class wrapper for the specified class (used from Objective-C). */
- (id) initWithClass:(Class) class;
/*! Initialize a class wrapper for the named Objective-C class. */
- (id) initWithClassNamed:(NSString *) name;
/*! Get the class corresponding to the NuClass wrapper (used from Objective-C). */
- (Class) wrappedClass;
/*! Get an array of all classes known to the Objective-C runtime.
 Beware, some of these classes may be deprecated, undocumented, or otherwise unsafe to use. */
+ (NSArray *) all;
/*! Get the name of a class. */
- (NSString *) name;
/*! Get an array containing NuMethod representations of the class methods of a class. */
- (NSArray *) classMethods;
/*! Get an array containing NuMethod representations of the instance methods of a class. */
- (NSArray *) instanceMethods;
/*! Get an array containing the names of the class methods of a class. */
- (NSArray *) classMethodNames;
/*! Get an array containing the names of the instance methods of a class. */
- (NSArray *) instanceMethodNames;
/*! Determine whether a class is derived from another class. */
- (BOOL) isDerivedFromClass:(Class) parent;
/*! Compare a class with another class by name.  This allows arrays of classes to be easily sorted. */
- (NSComparisonResult) compare:(NuClass *) anotherClass;
/*! Get a class method by name. */
- (NuMethod *) classMethodWithName:(NSString *) methodName;
/*! Get an instance method by name. */
- (NuMethod *) instanceMethodWithName:(NSString *) methodName;
/*! Compare two classes for equality. */
- (BOOL) isEqual:(NuClass *) anotherClass;
/*! Change the superclass of a class. Be careful with this. */
- (void) setSuperclass:(NuClass *) newSuperclass;
/*! Add an instance method to a class with the specified name, type signature, and body. */
- (id) addInstanceMethod:(NSString *) methodName signature:(NSString *)signature body:(NuBlock *) block;
/*! Add a class method to a class with the specified name, type signature, and body. */
- (id) addClassMethod:(NSString *) methodName signature:(NSString *)signature body:(NuBlock *) block;
/*! Add an instance variable to the receiving class. This will cause problems if there are already instances of the receiving class. */
- (id) addInstanceVariable:(NSString *)variableName signature:(NSString *) signature;

- (BOOL) isRegistered;
- (void) setRegistered:(BOOL) value;
- (void) registerClass;
@end

/*!
 @class NuSuper
 @abstract The Nu superclass proxy, an implementation detail used by Nu methods.
 @discussion Instances of this class in Nu methods act as proxies for object superclasses.
 Each time a Nu implementation of a method is called,
 a NuSuper instance is created and inserted into the method's execution context with the name "super".
 This allows method implementations to send messages to superclass implementations.
 Typically, there is no need to directly interact with this class from Nu.
 */
@interface NuSuper : NSObject

/*! Create a NuSuper proxy for an object with a specified class.
 Note that the object class must be explicitly specified.
 This is necessary to allow proper chaining of message sends
 to super when multilevel methods are used (typically for initialization),
 each calling the superclass version of itself. */
+ (NuSuper *) superWithObject:(id) o ofClass:(Class) c;
/*! Initialize a NuSuper proxy for an object with a specified class. */
- (NuSuper *) initWithObject:(id) o ofClass:(Class) c;
/*! Evalute a list headed by a NuSuper proxy.  If non-null, the remainder
 of the list is treated as a message that is sent to the object,
 but treating the object as if it is an instance of its immediate superclass.
 This is equivalent to sending a message to "super" in Objective-C. */
- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context;

@end

/*!
 @class NuProperty
 @abstract Wrapper for Objective-C properties.
 @discussion Preliminary and incomplete.
 */
@interface NuProperty : NSObject

/*! Create a property wrapper for the specified property (used from Objective-C). */
+ (NuProperty *) propertyWithProperty:(objc_property_t) property;
/*! Initialize a property wrapper for the specified property (used from Objective-C). */
- (id) initWithProperty:(objc_property_t) property;

@end

#if !TARGET_OS_IPHONE
/*!
 @class NuBridgeSupport
 @abstract A reader for Apple's BridgeSupport files.
 @discussion Methods of this class are used to read Apple's BridgeSupport files.
 */
@interface NuBridgeSupport : NSObject 
/*! Import a dynamic library at the specified path. */
+ (void)importLibrary:(NSString *) libraryPath;
/*! Import a BridgeSupport description of a framework from a specified path.  Store the results in the specified dictionary. */
+ (void)importFramework:(NSString *) framework fromPath:(NSString *) path intoDictionary:(NSMutableDictionary *) BridgeSupport;

@end
#endif

#pragma mark -
#pragma mark Error Handling

/*!
 @class NuException
 @abstract When something goes wrong in Nu.
 @discussion A Nu Exception is a subclass of NSException, representing
 errors during execution of Nu code. It has the ability to store trace information.
 This information gets added during unwinding the stack by the NuCells.
 */
@interface NuException : NSException

+ (void)setDefaultExceptionHandler;
+ (void)setVerbose:(BOOL)flag;

/*! Create a NuException. */
- (id)initWithName:(NSString *)name reason:(NSString *)reason userInfo:(NSDictionary *)userInfo;

/*! Get the stack trace. */
- (NSArray*)stackTrace;
- (NSString*)dump;

/*! Add to the stack trace. */
- (NuException *)addFunction:(NSString *)function lineNumber:(int)line;
- (NuException *)addFunction:(NSString *)function lineNumber:(int)line filename:(NSString*)filename;

/*! Get a string representation of the exception. */
- (NSString *)stringValue;

/*! Dump the exception to stdout. */
- (NSString*)dump;

/*! Dump leaving off some of the toplevel */
- (NSString*)dumpExcludingTopLevelCount:(NSUInteger)count;

@end

@interface NuTraceInfo : NSObject

- (id)initWithFunction:(NSString *)function lineNumber:(int)lineNumber filename:(NSString *)filename;
- (NSString *)filename;
- (int)lineNumber;
- (NSString *)function;

@end

#pragma mark -
#pragma mark Mixins

/*!
 @class NuEnumerable
 @abstract The NuEnumerable mixin class.
 @discussion This class implements methods that act on enumerated collections of objects.
 It is designed to be mixed into a class using the include method that Nu adds to NSObject.
 The receiving class must have an objectEnumerator method that returns an NSEnumerator.
 Some methods in this class take a callable object as an argument; callable objects are those
 that have evalWithArguments:context: defined.
 */
@interface NuEnumerable : NSObject

/*! Iterate over each member of a collection, evaluating the provided callable item for each member. */
- (id) each:(id) callable;
/*! Iterate over each member of a collection, evaluating the provided block for each member.
 The block is expected to take two arguments: the member and its index. */
- (id) eachWithIndex:(NuBlock *) block;
/*! Iterate over each member of a collection, returning an array containing the elements for which the provided block evaluates non-nil. */
- (NSArray *) select:(NuBlock *) block;
/*! Iterate over each member of a collection, returning the first element for which the provided block evaluates non-nil. */
- (id) find:(NuBlock *) block;
/*! Iterate over each member of a collection, applying the provided block to each member, and returning an array of the results. */
- (NSArray *) map:(id) callable;
/*! Iterate over each member of a collection, using the provided callable to combine members into a single return value.
 */
- (id) reduce:(id) callable from:(id) initial;
/*! Iterate over each member of a collection, applying the provided selector to each member, and returning an array of the results. */
- (NSArray *) mapSelector:(SEL) selector;

@end

#pragma mark -
#pragma mark Class Extensions

/*!
 @category NSObject(Nu)
 @abstract NSObject extensions for Nu programming.
 */
@interface NSObject(Nu)
/*! Returns true.  In Nu, virtually all Objective-C classes are considered atoms. */
- (bool) atom;
/*!
 Evaluation operator.  The Nu default is for an Objective-C object to evaluate to itself,
 but certain subclasses (such as NuSymbol and NSString) behave differently.
 */
- (id) evalWithContext:(NSMutableDictionary *) context;
/*! Gets the value of a specified instance variable. */
- (id) valueForIvar:(NSString *) name;
/*! Sets the value of a specified instance variable. */
- (void) setValue:(id) value forIvar:(NSString *) name;
/*! Get an array containing NuMethod representations of the class methods of a class. */
+ (NSArray *) classMethods;
/*! Get an array containing NuMethod representations of the instance methods of a class. */
+ (NSArray *) instanceMethods;
/*! Get an array containing the names of the class methods of a class. */
+ (NSArray *) classMethodNames;
/*! Get an array containing the names of the instance methods of a class. */
+ (NSArray *) instanceMethodNames;
/*! Get an array containing the names of all instance variables of the class. */
+ (NSArray *) instanceVariableNames;

/*! Create a subclass of a class with the specified name. */
+ (id) createSubclassNamed:(NSString *) subclassName;

/*! Copy a named instance method from another class to the receiving class. */
+ (BOOL) copyInstanceMethod:(NSString *) methodName fromClass:(NuClass *) prototypeClass;
/*! Copy all of the instance methods from a specified class to the receiving class. */
+ (BOOL) include:(NuClass *) prototypeClass;

/*! Send a message to an object with an execution context */
- (id) sendMessage:(id)cdr withContext:(NSMutableDictionary *)context;
/*! Evaluate a list with the receiving object at the head. Calls <b>sendMessage:withContext:</b> */
- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context;

/*! Handle an unknown message.  Override this in subclasses to provide dynamic method handling. */
- (id) handleUnknownMessage:(id) cdr withContext:(NSMutableDictionary *) context;

/*! This method is automatically sent to a class whenever Nu code creates a subclass of that class.
 Its default implementation does nothing.  Override it to track subclassing. */
+ (id) inheritedByClass:(NuClass *) newClass;

/*! Get a string providing a helpful description of an object.
 This method should be overridden by subclasses to be more helpful. */
- (NSString *) help;

/*! Swap a pair of instance methods of the underlying class. */
+ (BOOL) exchangeInstanceMethod:(SEL)sel1 withMethod:(SEL)sel2;

/*! Swap a pair of class methods of the underlying class. */
+ (BOOL) exchangeClassMethod:(SEL)sel1 withMethod:(SEL)sel2;

/*! Concisely set key-value pairs from a property list. */
- (id) set:(NuCell *) propertyList;

/*! Set a retained associated object. */
- (void) setRetainedAssociatedObject:(id) object forKey:(id) key;

/*! Set an assigned associated object. */
- (void) setAssignedAssociatedObject:(id) object forKey:(id) key;

/*! Set a copied associated object. */
- (void) setCopiedAssociatedObject:(id) object forKey:(id) key;

/*! Get the value of an associated object. */
- (id) associatedObjectForKey:(id) key;

/*! Remove all associated objects. */
- (void) removeAssociatedObjects;

/*! Return true if object has a value for the named instance variable. */
- (BOOL) hasValueForIvar:(NSString *) name;

/*! Property list helper. Return the XML property list representation of the object. */
- (NSData *) XMLPropertyListRepresentation;

/*! Property list helper. Return the binary property list representation of the object. */
- (NSData *) binaryPropertyListRepresentation;

@end

/*!
 @category NSNull(Nu)
 @abstract NSNull extensions for Nu programming.
 @discussion In Nu, nil is represented by <code>[NSNull null]</code>.
 */
@interface NSNull(Nu)
/*! Returns false.  In Nu, nil is not an atom. */
- (bool) atom;
/*! The length of nil is zero. */
- (NSUInteger) length;
/*! count is a synonym for length. */
- (NSUInteger) count;
/*! nil converts to an empty array. */
- (NSMutableArray *) array;
@end

/*!
 @category NSArray(Nu)
 @abstract NSArray extensions for Nu programming.
 */
@interface NSArray(Nu)
/*! Creates an array that contains the contents of a specified list. */
+ (NSArray *) arrayWithList:(id) list;

/*! Sort an array using its elements' compare: method. */
- (NSArray *) sort;

/*! Convert an array into a list. */
- (NuCell *) list;

/*! Repeatedly apply a function of two arguments to the elements of an array,
 working from right to left and beginning with the specified inital value. */
- (id) reduceLeft:(id)callable from:(id) initial;

/*! Iterate over each member of an array in reverse order and beginning with the lastObject, evaluating the provided block for each member. */
- (id) eachInReverse:(id) callable;

/*! Return a sorted array using the specified block to compare array elements.
 The block should return -1, 0, or 1. */
- (NSArray *) sortedArrayUsingBlock:(NuBlock *) block;

@end

/*!
 @category NSMutableArray(Nu)
 @abstract NSMutableArray extensions for Nu programming.
 */
@interface NSMutableArray(Nu)
/*! Add the objects from the specified list to the array. */
- (void) addObjectsFromList:(id)list;
/*! Add an object to an array, automatically converting nil into [NSNull null]. */
- (void) addPossiblyNullObject:(id)anObject;
/*! Insert an object into an array, automatically converting nil into [NSNull null]. */
- (void) insertPossiblyNullObject:(id)anObject atIndex:(int)index;
/*! Replace an object in an array, automatically converting nil into [NSNull null]. */
- (void) replaceObjectAtIndex:(int)index withPossiblyNullObject:(id)anObject;
@end

/*!
 @category NSDictionary(Nu)
 @abstract NSDictionary extensions for Nu programming.
 */
@interface NSDictionary(Nu)
/*! Creates a dictionary that contains the contents of a specified list.
 The list should be a sequence of interleaved keys and values.  */
+ (NSDictionary *) dictionaryWithList:(id) list;
/*! Look up an object by key, returning the specified default if no object is found. */
- (id) objectForKey:(id)key withDefault:(id)defaultValue;
@end

/*!
 @category NSMutableDictionary(Nu)
 @abstract NSMutableDictionary extensions for Nu programming.
 @discussion In Nu, NSMutableDictionaries are used to represent evaluation contexts.
 Context keys are NuSymbols, and the associated objects are the symbols'
 assigned values.
 */
@interface NSMutableDictionary(Nu)
/*! Looks up the value associated with a key in the current context.
 If no value is found, looks in the context's parent, continuing
 upward until no more parent contexts are found. */
- (id) lookupObjectForKey:(id)key;
/*! Add an object to a dictionary, automatically converting nil into [NSNull null]. */
- (void) setPossiblyNullObject:(id) anObject forKey:(id) aKey;

@end

/*!
 @category NSSet(Nu)
 @abstract NSSet extensions for Nu programming.
 */
@interface NSSet(Nu)
/*! Creates a set that contains the contents of a specified list. */
+ (NSSet *) setWithList:(id) list;
/*! Convert a set into a list. */
- (NuCell *) list;
@end

/*!
 @category NSMutableSet(Nu)
 @abstract NSSet extensions for Nu programming.
 */
@interface NSMutableSet(Nu)
/*! Add an object to a set, automatically converting nil into [NSNull null]. */
- (void) addPossiblyNullObject:(id)anObject;
@end

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

/*!
 @category NSData(Nu)
 @abstract NSData extensions for Nu programming.
 @discussion NSData extensions for Nu programming.
 */
@interface NSData(Nu)

#if !TARGET_OS_IPHONE
/*! Run a shell command and return the results as data. */
+ (NSData *) dataWithShellCommand:(NSString *) command;

/*! Run a shell command with the specified data or string as standard input and return the results as data. */
+ (NSData *) dataWithShellCommand:(NSString *) command standardInput:(id) input;
#endif

/*! Return data read from standard input. */
+ (NSData *) dataWithStandardInput;

/*! Property list helper. Return the (immutable) property list value of the associated data. */
- (id) propertyListValue;

@end

/*!
 @category NSString(Nu)
 @abstract NSString extensions for Nu programming.
 @discussion NSString extensions for Nu programming.
 */
@interface NSString(Nu)
/*! Get string consisting of a single carriage return character. */
+ (id) carriageReturn;
/*!
 Evaluation operator.  In Nu, strings may contain embedded Nu expressions that are evaluated when this method is called.
 Expressions are wrapped in #{...} where the ellipses correspond to a Nu expression.
 */
- (id) evalWithContext:(NSMutableDictionary *) context;

#if !TARGET_OS_IPHONE
/*! Run a shell command and return its results in a string. */
+ (NSString *) stringWithShellCommand:(NSString *) command;

/*! Run a shell command with the specified data or string as standard input and return the results in a string. */
+ (NSString *) stringWithShellCommand:(NSString *) command standardInput:(id) input;
#endif

/*! Return a string read from standard input. */
+ (NSString *) stringWithStandardInput;

/*! If the last character is a newline, return a new string without it. */
- (NSString *) chomp;

/*! Create a string from a specified character */
+ (NSString *) stringWithCharacter:(unichar) c;

/*! Convert a string into a symbol. */
- (id) symbolValue;

/*! Get a representation of the string that can be used in Nu source code. */
- (NSString *) escapedStringRepresentation;

/*! Split a string into lines. */
- (NSArray *) lines;

/*! Replace a substring with another. */
- (NSString *) replaceString:(NSString *) target withString:(NSString *) replacement;

/*! Iterate over each character in a string, evaluating the provided block for each character. */
- (id) each:(id) block;

@end

/*!
 @category NSMutableString(Nu)
 @abstract NSMutableString extensions for Nu programming.
 */
@interface NSMutableString(Nu)
/*! Append a specified character to a string. */
- (void) appendCharacter:(unichar) c;
@end

/*!
 @category NSMethodSignature(Nu)
 @abstract NSMethodSignature extensions for Nu programming.
 */
@interface NSMethodSignature (Nu)
/*! Get the type string for a method signature. */
- (NSString *) typeString;
@end

/*!
 @category NSBundle(Nu)
 @abstract NSBundle extensions for Nu programming.
 */
@interface NSBundle (Nu)
/*! Get or load a framework by name. */
+ (NSBundle *) frameworkWithName:(NSString *) frameworkName;
/*! Load a Nu source file from the framework's resource directory. */
- (id) loadNuFile:(NSString *) nuFileName withContext:(NSMutableDictionary *) context;
@end

/*!
 @category NSFileManager(Nu)
 @abstract NSFileManager extensions for Nu programming.
 */
@interface NSFileManager (Nu)
/*! Get the creation time for a file. */
+ (id) creationTimeForFileNamed:(NSString *) filename;
/*! Get the latest modification time for a file. */
+ (id) modificationTimeForFileNamed:(NSString *) filename;
/*! Test for the existence of a directory. */
+ (int) directoryExistsNamed:(NSString *) filename;
/*! Test for the existence of a file. */
+ (int) fileExistsNamed:(NSString *) filename;
@end

#pragma mark -
#pragma mark Regular Expressions

// Let's make NSRegularExpression and NSTextCheckingResult look like our previous classes, NuRegex and NuRegexMatch

@interface NSTextCheckingResult (NuRegexMatch) 
/*!
 @method regex
 The regular expression used to make this match. */
- (NSRegularExpression *)regex;

/*!
 @method count
 The number of capturing subpatterns, including the pattern itself. */
- (NSUInteger)count;

/*!
 @method group
 Returns the part of the target string that matched the pattern. */
- (NSString *)group;

/*!
 @method groupAtIndex:
 Returns the part of the target string that matched the subpattern at the given index or nil if it wasn't matched. The subpatterns are indexed in order of their opening parentheses, 0 is the entire pattern, 1 is the first capturing subpattern, and so on. */
- (NSString *)groupAtIndex:(int)idx;

/*!
 @method string
 Returns the target string. */
- (NSString *)string;

@end

@interface NSRegularExpression (NuRegex) 

/*!
 @method regexWithPattern:
 Creates a new regex using the given pattern string. Returns nil if the pattern string is invalid. */
+ (id)regexWithPattern:(NSString *)pattern;

/*!
 @method regexWithPattern:options:
 Creates a new regex using the given pattern string and option flags. Returns nil if the pattern string is invalid. */
+ (id)regexWithPattern:(NSString *)pattern options:(int)options;

/*!
 @method initWithPattern:
 Initializes the regex using the given pattern string. Returns nil if the pattern string is invalid. */
- (id)initWithPattern:(NSString *)pattern;

/*!
 @method initWithPattern:options:
 Initializes the regex using the given pattern string and option flags. Returns nil if the pattern string is invalid. */
- (id)initWithPattern:(NSString *)pattern options:(int)options;

/*!
 @method findInString:
 Calls findInString:range: using the full range of the target string. */
- (NSTextCheckingResult *)findInString:(NSString *)string;

/*!
 @method findInString:range:
 Returns an NuRegexMatch for the first occurrence of the regex in the given range of the target string or nil if none is found. */
- (NSTextCheckingResult *)findInString:(NSString *)string range:(NSRange)range;

/*!
 @method findAllInString:
 Calls findAllInString:range: using the full range of the target string. */
- (NSArray *)findAllInString:(NSString *)string;

/*!
 @method findAllInString:range:
 Returns an array of all non-overlapping occurrences of the regex in the given range of the target string. The members of the array are NuRegexMatches. */
- (NSArray *)findAllInString:(NSString *)string range:(NSRange)range;

/*!
 @method replaceWithString:inString:
 Calls replaceWithString:inString:limit: with no limit. */
- (NSString *)replaceWithString:(NSString *)rep inString:(NSString *)str;

@end

#pragma mark -
#pragma mark Profiler (Experimental)

@interface NuProfiler : NSObject

+ (NuProfiler *) defaultProfiler;

@end

#pragma mark -
#pragma mark Utilities (Optional, may disappear)

/*!
 @class NuMath
 @abstract A utility class that provides Nu access to common mathematical functions.
 @discussion The NuMath class provides a few common mathematical functions as class methods.
 */
@interface NuMath : NSObject
/*! Get the square root of a number. */
+ (double) sqrt: (double) x;
/*! Get the square of a number. */
+ (double) square: (double) x;
/*! Get the cubed root of a number. */
+ (double) cbrt: (double) x;
/*! Get the cosine of an angle. */
+ (double) cos: (double) x;
/*! Get the sine of an angle. */
+ (double) sin: (double) x;
/*! Get the largest integral value that is not greater than x.*/
+ (double) floor: (double) x;
/*! Get the smallest integral value that is greater than or equal to x.*/
+ (double) ceil: (double) x;
/*! Get the integral value nearest to x by always rounding half-way cases away from zero. */
+ (double) round: (double) x;
/*! Raise x to the power of y */
+ (double) raiseNumber: (double) x toPower: (double) y;
/*! Get the qouteint of x divided by y as an integer */
+ (int) integerDivide:(int) x by:(int) y;
/*! Get the remainder of x divided by y as an integer */
+ (int) integerMod:(int) x by:(int) y;
/*! Get a random integer. */
+ (long) random;
/*! Seed the random number generator. */
+ (void) srandom:(unsigned long) seed;
@end

#pragma mark -
#pragma mark Top Level Interface

// call this from main() to run the Nu shell.
int NuMain(int argc, const char *argv[]);

// call this to initialize the Nu environment.
void NuInit(void);

/*!
 @class Nu
 @abstract An Objective-C class that provides access to a Nu parser.
 @discussion This class provides a simple interface that allows Objective-C code to run code written in Nu.
 It is intended for use in Objective-C programs that include Nu as a framework.
 */
@interface Nu : NSObject
/*!
 Get a Nu parser with its own context.
 */
+ (NuParser *) parser;
/*!
 Get a common parser. This allows a context to be shared throughout an app.
 */
+ (NuParser *) sharedParser;
/*!
 Load a Nu source file from a bundle with the specified identifier.
 Used by bundle (aka framework) initializers.
 */
+ (BOOL) loadNuFile:(NSString *) fileName fromBundleWithIdentifier:(NSString *) bundleIdentifier withContext:(NSMutableDictionary *) context;
@end

// Helpers for programmatic construction of Nu code. Used by nubake.
// Experimental. They may change or disappear in future releases.
id _nunull(void);
id _nustring(const unsigned char *string);
id _nustring_with_length(const unsigned char *string, int length);
id _nusymbol(const unsigned char *string);
id _nusymbol_with_length(const unsigned char *string, int length);
id _nunumberd(double d);
id _nucell(id car, id cdr);
id _nuregex(const unsigned char *pattern, int options);
id _nuregex_with_length(const unsigned char *pattern, int length, int options);
id _nulist(id firstObject,...);
id _nudata(const void *bytes, int length);
