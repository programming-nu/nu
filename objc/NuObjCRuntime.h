/*!
@header NuObjCRuntime.h
@discussion Nu extensions to the Objective-C runtime.
Includes replacements for Objective-C 2.0 enhancements
that are only available in Apple's OS X 10.5 (Leopard)
plus a few things that aren't in the Objective-C runtime
but should be.
@copyright Copyright (c) 2007 Radtastical Inc.

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
#import <objc/objc.h>

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#ifdef IPHONE
#import "ffi.h"
#else
#import "ffi/ffi.h"
#endif

#ifndef LEOPARD_OBJC2
#ifndef IPHONE
// These methods are in Leopard but not earlier versions of Mac OS X.
// They aren't rocket science, so I wrote equivalent versions.
#import <stddef.h>
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
const char *class_getName(Class c);
void method_exchangeImplementations(Method method1, Method method2);
Ivar class_getInstanceVariable(Class c, const char *name);
#endif
#endif

// We'd like for this to be in the ObjC2 API, but it isn't.  Apple thinks it's too dangerous.  It is dangerous.
void class_addInstanceVariable_withSignature(Class thisClass, const char *variableName, const char *signature);

// These are just handy.
IMP nu_class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
BOOL nu_copyInstanceMethod(Class destinationClass, Class sourceClass, SEL selector);
BOOL nu_objectIsKindOfClass(id object, Class class);
void nu_markEndOfObjCTypeString(char *type, size_t len);

// This makes it safe to insert nil into container classes
void nu_swizzleContainerClasses();

