/*!
@header bridge.h
@discussion The Nu bridge to Objective-C.
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
#import "operator.h"
#import "objc_runtime.h"
#import "cell.h"
#import "symbol.h"

id add_method_to_class(Class c, NSString *methodName, NSString *signature, NuBlock *block);
#ifdef DARWIN
id nu_calling_objc_method_handler(id target, Method m, NSMutableArray *args);
#else
id nu_calling_objc_method_handler(id target, Method_t m, NSMutableArray *args);
#endif
id get_nu_value_from_objc_value(void *objc_value, const char *typeString);
int set_objc_value_from_nu_value(void *objc_value, id nu_value, const char *typeString);
void *value_buffer_for_objc_type(const char *typeString);
NSString *signature_for_identifier(NuCell *cell, NuSymbolTable *symbolTable);
id help_add_method_to_class(Class classToExtend, id cdr, NSMutableDictionary *context, BOOL addClassMethod);

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
{
    char *name;
    char *signature;
    void *function;
}

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
