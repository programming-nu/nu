/*!
@header objc_runtime.h
@discussion Nu extensions to the Objective-C runtime.
Includes replacements for Objective-C 2.0 enhancements
that are only available in Apple's OS X 10.5 (Leopard)
plus a few things that aren't in the Objective-C runtime
but should be.
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

#import <objc/objc.h>

#ifdef DARWIN
#ifndef IPHONE
#import <objc/objc-runtime.h>
#import <objc/objc-class.h>
#import <objc/Protocol.h>
#else
#import <objc/runtime.h>
#endif
#else
#import <objc/objc-api.h>
#endif
#import <Foundation/Foundation.h>
#ifdef DARWIN
#import "ffi/ffi.h"

#else

#import "ffi.h"

#define bool char
#define true 1
#define false 0

#define Ivar Ivar_t


Class objc_getClass(const char *name);
void class_addMethods(Class, struct objc_method_list *);
BOOL class_addProtocol(Class cls, Protocol *protocol);
BOOL class_conformsToProtocol(Class cls, Protocol *protocol);
Protocol **class_copyProtocolList(Class cls, unsigned int *outCount);
Method_t class_getInstanceMethod(Class cls, SEL name);
Ivar_t class_getInstanceVariable(Class cls, const char *name);
struct objc_method_list *class_nextMethodList(Class, void **);
const char *ivar_getName(Ivar_t v);
unsigned method_getArgumentInfo(struct objc_method *m, int arg, const char **type, int *offset);
unsigned int method_getNumberOfArguments(Method_t m);
SEL method_getName(Method_t m);
void objc_addClass(Class myClass);
const char **objc_copyClassNamesForImage(const char *image, unsigned int *outCount);
const char **objc_copyImageNames(unsigned int *outCount);
Protocol **objc_copyProtocolList(unsigned int *outCount);
void *objc_getClasses(void);
int objc_getClassList(Class *buffer, int bufferCount);
Protocol *objc_getProtocol(const char *name);
struct objc_method_description *protocol_copyMethodDescriptionList(Protocol *p, BOOL isRequiredMethod, BOOL isInstanceMethod, unsigned int *outCount);
Protocol **protocol_copyProtocolList(Protocol *proto, unsigned int *outCount);
SEL sel_getUid(const char *str);
#endif

#ifndef LEOPARD_OBJC2
#ifndef IPHONE
// These methods are in Leopard but not earlier versions of Mac OS X.
// They aren't rocket science, so I wrote equivalent versions.
#import <stddef.h>
Ivar *class_copyIvarList(Class cls, unsigned int *outCount);
#ifdef DARWIN
Method *class_copyMethodList(Class cls, unsigned int *outCount);
#else
Method_t *class_copyMethodList(Class cls, unsigned int *outCount);
#endif
Class class_getSuperclass(Class cls);
const char *ivar_getName(Ivar v);
ptrdiff_t ivar_getOffset(Ivar v);
const char *ivar_getTypeEncoding(Ivar v);
#ifdef DARWIN
char *method_copyArgumentType(Method m, unsigned int index);
char *method_copyReturnType(Method m);
void method_getArgumentType(Method m, unsigned int index, char *dst, size_t dst_len);
IMP method_getImplementation(Method m);
SEL method_getName(Method m);
void method_getReturnType(Method m, char *dst, size_t dst_len);
const char *method_getTypeEncoding(Method m);
#else
char *method_copyArgumentType(Method_t m, unsigned int index);
char *method_copyReturnType(Method_t m);
void method_getArgumentType(Method_t m, unsigned int index, char *dst, size_t dst_len);
IMP method_getImplementation(Method_t m);
SEL method_getName(Method_t m);
void method_getReturnType(Method_t m, char *dst, size_t dst_len);
const char *method_getTypeEncoding(Method_t m);
#endif

Class objc_allocateClassPair(Class superclass, const char *name, size_t extraBytes);
void objc_registerClassPair(Class cls);
Class object_getClass(id obj);
const char *class_getName(Class c);
#ifdef DARWIN
void method_exchangeImplementations(Method method1, Method method2);
#else
void method_exchangeImplementations(Method_t method1, Method_t method2);
#endif
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

#ifdef LINUX
Method_t class_getClassMethod (MetaClass class, SEL op);
#endif
