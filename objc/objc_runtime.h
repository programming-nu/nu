/*!
    @header objc_runtime.h
  	@copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
  	@discussion Nu extensions to the Objective-C runtime.  
	Includes replacements for Objective-C 2.0 enhancements 
	that are only available in Apple's OS X 10.5 (Leopard).
*/

#import <objc/objc.h>
#import <objc/objc-runtime.h>
#import <objc/objc-class.h>
#import <objc/Protocol.h>
#import <Cocoa/Cocoa.h>
#import "ffi/ffi.h"

#ifndef LEOPARD_OBJC2
#import <stddef.h>
IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
Ivar *class_copyIvarList(Class cls, unsigned int *outCount);
Method *class_copyMethodList(Class cls, unsigned int *outCount);
Class class_getSuperclass(Class cls);
const char *ivar_getName(Ivar v);
ptrdiff_t ivar_getOffset(Ivar v);
const char *ivar_getTypeEncoding(Ivar v);
char *method_copyArgumentType(Method m, unsigned int index);
char *method_copyReturnType(Method m);
void method_getArgumentType(Method m, unsigned int index, char *dst, size_t dst_len);
IMP method_getImplementation(Method m);
SEL method_getName(Method m);
void method_getReturnType(Method m, char *dst, size_t dst_len);
const char *method_getTypeEncoding(Method m);
Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes);
void objc_registerClassPair(Class cls);
Class object_getClass(id obj);
#endif

#import "cell.h"
#import "symbol.h"

// helpers
void mark_end_of_type_string(char *type, size_t len);

NSString *signature_for_identifier(NuCell *cell, NuSymbolTable *symbolTable);
id help_add_method_to_class(Class classToExtend, id cdr, NSMutableDictionary *context);

Ivar class_findInstanceVariable(Class c, const char *name);
Ivar object_findInstanceVariable(id object, const char *name);
