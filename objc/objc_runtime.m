/*
@file objc_runtime.m
@description Nu extensions to the Objective-C runtime.  
Includes replacements for Objective-C 2.0 enhancements that are 
only available in Apple's OS X 10.5 (Leopard).
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

// Undefine __OBJC2__ to get access to data structures in the ObjC runtime.
// This triggers deprecation warnings on Leopard.
#undef __OBJC2__

#include <stdlib.h>
#include <string.h>
#ifdef DARWIN
#ifndef IPHONE
#include <objc/objc-class.h>
#endif
#endif
#include <math.h>
#import <Foundation/Foundation.h> // for NSException

#ifndef DARWIN

// it seems that in the GNU runtime, this function is supposed to get the metaclass,
// but in the NeXT runtime, it gets the class.
Method_t class_getClassMethod (MetaClass class, SEL op)
{
    return class_get_class_method(class->class_pointer, op);
}

Class objc_getClass (const char *name)
{
    return objc_lookup_class(name);
}

void class_add_method_list (Class class, MethodList_t list);

void class_addMethods(Class cls, struct objc_method_list *methods)
{
    class_add_method_list(cls, methods);
}

BOOL class_addProtocol(Class cls, Protocol *protocol)
{
    return NO;
}

BOOL class_conformsToProtocol(Class cls, Protocol *protocol)
{
    return NO;
}

Protocol **class_copyProtocolList(Class cls, unsigned int *outCount)
{
    return 0;
}

Method_t class_getInstanceMethod(Class cls, SEL name)
{
    return class_get_instance_method(cls, name);
}

Ivar_t class_getInstanceVariable(Class cls, const char *name)
{
    struct objc_ivar_list *ivar_list = cls->ivars;
    if (!ivar_list) {
        if (cls->super_class)
            return class_getInstanceVariable(cls->super_class, name);
        else
            return NULL;
    }
    int count = ivar_list->ivar_count;
    for (int i = 0; i < count; i++) {
        if (!strcmp(name, ivar_list->ivar_list[i].ivar_name)) {
            return &(ivar_list->ivar_list[i]);
        }
    }
    if (cls->super_class)
        return class_getInstanceVariable(cls->super_class, name);
    else
        return NULL;
}

struct objc_method_list *class_nextMethodList(Class cls, void **methodList)
{
    if (!(*methodList)) {
        *methodList = cls->methods;
    }
    else {
        *methodList = (* (MethodList_t *) methodList)->method_next;
    }
    return *methodList;
}

char *method_get_nth_argument (struct objc_method *m, arglist_t argframe, int arg, const char **type);

unsigned method_getArgumentInfo(struct objc_method *m, int arg, const char **type, int *offset)
{
    union arglist argframe;
    method_get_nth_argument(m, &argframe, arg, type);
    return 0;
}

int method_get_number_of_arguments (struct objc_method *);

unsigned int method_getNumberOfArguments(Method_t m)
{
    //unused
    //const char *methodTypes = m->method_types;
    int count = method_get_number_of_arguments(m);
    return count;
}

extern void __objc_add_class_to_hash(Class);
void objc_addClass(Class myClass)
{
    __objc_add_class_to_hash(myClass);
}

const char **objc_copyClassNamesForImage(const char *image, unsigned int *outCount)
{
    return 0;
}

const char **objc_copyImageNames(unsigned int *outCount)
{
    return 0;
}

Protocol **objc_copyProtocolList(unsigned int *outCount)
{
    return 0;
}

void *objc_getClasses(void)
{
    return 0;
}

int objc_getClassList(Class *buffer, int bufferCount)
{
    return 0;
}

Protocol *objc_getProtocol(const char *name)
{
    return 0;
}

struct objc_method_description *protocol_copyMethodDescriptionList(Protocol *p, BOOL isRequiredMethod, BOOL isInstanceMethod, unsigned int *outCount)
{
    return 0;
}

Protocol **protocol_copyProtocolList(Protocol *proto, unsigned int *outCount)
{
    return 0;
}

SEL sel_getUid(const char *str)
{
    return sel_get_uid(str);
}
#endif

#ifdef IPHONE
#import "objc/runtime.h"
IMP nu_class_replaceMethod(Class cls, SEL name, IMP imp, const char *types) {
	return class_replaceMethod(cls, name, imp, types);	
}
#endif

#ifndef LEOPARD_OBJC2
#include "objc_runtime.h"
#ifndef IPHONE
BOOL class_hasMethod(Class cls, SEL name)
{
    // Method (Method_t on Linux) existing_method = class_getInstanceMethod(cls, name);
    // if (!existing_method) return NO;
    // The above is fine on Leopard, but doesn't work on Tiger.
    // On Tiger, the method returned can be from a class ancestor.
    // Traverse the class' method table to make sure the method belongs to THIS class.
    void *iterator = 0;
    struct objc_method_list *mlist;
    while ((mlist = class_nextMethodList(cls, &iterator))) {
        int count = mlist->method_count;
        int i;
        for (i = 0; i < count; i++) {
            if (mlist->method_list[i].method_name == name)
                return YES;
        }
    }
    return NO;
}

IMP nu_class_replaceMethod(Class cls, SEL name, IMP imp, const char *types)
{
    // replace the method if one with the same name is already present
    if (class_hasMethod(cls, name)) {
        void *iterator = 0;
        struct objc_method_list *mlist;
        while ((mlist = class_nextMethodList(cls, &iterator))) {
            int count = mlist->method_count;
            int i;
            for (i = 0; i < count; i++) {
                if (mlist->method_list[i].method_name == name) {
                    IMP original = mlist->method_list[i].method_imp;
                    mlist->method_list[i].method_types = strdup(types);
                    mlist->method_list[i].method_imp = imp;
                    return original;
                }
            }
        }
    }
    struct objc_method_list *method_list = (struct objc_method_list *) malloc (sizeof (struct objc_method_list));
    method_list->method_count = 1;
#ifdef DARWIN
    method_list->method_list[0].method_name = name;
#else
    method_list->method_list[0].method_name = sel_get_name(name);
#endif
    method_list->method_list[0].method_types = strdup(types);
    method_list->method_list[0].method_imp = imp;
#ifdef LINUX
    method_list->method_next = NULL;
#endif
    class_addMethods(cls, method_list);
    return imp;
}

Ivar *class_copyIvarList(Class cls, unsigned int *outCount)
{
    struct objc_ivar_list *ivar_list = cls->ivars;
    if (!ivar_list) {
        *outCount = 0;
        return NULL;
    }
    int count = ivar_list->ivar_count;
    Ivar *list = (Ivar *) malloc (count * sizeof(Ivar));
    int i;
    for (i = 0; i < count; i++)
        list[i] = &(ivar_list->ivar_list[i]);
    *outCount = count;
    return list;
}


#ifdef DARWIN
Method *class_copyMethodList(Class cls, unsigned int *outCount)
#else
Method_t *class_copyMethodList(Class cls, unsigned int *outCount)
#endif
{
    // first count the methods
    int count = 0;
    struct objc_method_list *mlist;
    void *iterator = 0;
    while (( mlist = class_nextMethodList( cls, &iterator ) ))
        count += mlist->method_count;
    // then copy the methods into the list
#ifdef DARWIN
    Method *list = (Method *) malloc (count * sizeof(Method));
#else
    Method_t *list = (Method_t *) malloc (count * sizeof(Method));
#endif
    int index = 0;
    iterator = 0;
    while (( mlist = class_nextMethodList( cls, &iterator ) )) {
        int i;
        for (i = 0; i < mlist->method_count; i++) {
            list[index++] = &(mlist->method_list[i]);
        }
    }
    *outCount = count;
    return list;
}


Class class_getSuperclass(Class cls)
{
    return cls->super_class;
}


#ifdef DARWIN
const char *ivar_getName(Ivar v)
#else
const char *ivar_getName(Ivar_t v)
#endif
{
    return v->ivar_name;
}

#ifdef DARWIN
ptrdiff_t ivar_getOffset(Ivar v)
#else
ptrdiff_t ivar_getOffset(Ivar_t v)
#endif
{
    return (ptrdiff_t) v->ivar_offset;
}

#ifdef DARWIN
const char *ivar_getTypeEncoding(Ivar v)
#else
const char *ivar_getTypeEncoding(Ivar_t v)
#endif
{
    return v->ivar_type;
}
#endif

#ifdef DARWIN
char *method_copyArgumentType(Method m, unsigned int index)
#else
char *method_copyArgumentType(Method_t m, unsigned int index)
#endif
{
    int offset;
    const char *type;
    method_getArgumentInfo(m, index, &type, &offset);
    char *copy = strdup(type);
    nu_markEndOfObjCTypeString(copy, strlen(copy));
    return copy;
}

#ifdef DARWIN
void method_getArgumentType(Method m, unsigned int index, char *dst, size_t dst_len)
#else
void method_getArgumentType(Method_t m, unsigned int index, char *dst, size_t dst_len)
#endif
{
    int offset;
    const char *type;
    method_getArgumentInfo(m, index, &type, &offset);
    strncpy(dst, type, dst_len);
    nu_markEndOfObjCTypeString(dst, dst_len);
}

#ifdef DARWIN
char *method_copyReturnType(Method m)
#else
char *method_copyReturnType(Method_t m)
#endif
{
    char *type = strdup(m->method_types);
    nu_markEndOfObjCTypeString(type, strlen(type));
    return type;
}

#ifdef DARWIN
void method_getReturnType(Method m, char *dst, size_t dst_len)
#else
void method_getReturnType(Method_t m, char *dst, size_t dst_len)
#endif
{
    strncpy(dst, m->method_types, dst_len);
    nu_markEndOfObjCTypeString(dst, dst_len);
}

#ifdef DARWIN
IMP method_getImplementation(Method m)
#else
IMP method_getImplementation(Method_t m)
#endif
{
    return m->method_imp;
}

#ifdef DARWIN
SEL method_getName(Method m)
#else
SEL method_getName(Method_t m)
#endif
{
    return m->method_name;
}

#ifdef DARWIN
const char *method_getTypeEncoding(Method m)
#else
const char *method_getTypeEncoding(Method_t m)
#endif
{
    return m->method_types;
}

// this function was taken from RubyCocoa
static void* alloc_from_default_zone(unsigned int size)
{
    return NSZoneMalloc(NSDefaultMallocZone(), size);
}

// this function was taken from RubyCocoa
static struct objc_method_list** method_list_alloc(int cnt)
{
    int i;
    struct objc_method_list** mlp;
    mlp = alloc_from_default_zone(cnt * sizeof(void*));
    for (i = 0; i < (cnt-1); i++)
        mlp[i] = NULL;
    mlp[cnt-1] = (struct objc_method_list*)-1;    // END_OF_METHODS_LIST
    return mlp;
}
#ifndef IPHONE
// this function was taken from RubyCocoa
#ifdef DARWIN
Class objc_allocateClassPair(Class super_class, const char *name, size_t extraBytes)
{
    Class c = alloc_from_default_zone(sizeof(struct objc_class));
    Class isa = alloc_from_default_zone(sizeof(struct objc_class));
    struct objc_method_list **mlp0, **mlp1;
    mlp0 = method_list_alloc(16);
    mlp1 = method_list_alloc(4);

    c->isa = isa;
    c->super_class = super_class;
    c->name = strdup(name);
    c->version = 0;
    c->info = CLS_CLASS + CLS_METHOD_ARRAY;
    c->instance_size = super_class ? super_class->instance_size : 0;
    c->ivars = NULL;
    c->methodLists = mlp0;
    c->cache = NULL;
    c->protocols = NULL;

    isa->isa = super_class->isa->isa;
    isa->super_class = super_class ? super_class->isa : 0;
    isa->name = c->name;
    isa->version = 5;
    isa->info = CLS_META + CLS_INITIALIZED + CLS_METHOD_ARRAY;
    isa->instance_size = super_class->isa->instance_size;
    isa->ivars = NULL;
    isa->methodLists = mlp1;
    isa->cache = NULL;
    isa->protocols = NULL;
    return c;
}
#else
Class objc_allocateClassPair(Class super_class, const char *name, size_t extraBytes)
{
    Class c = alloc_from_default_zone(sizeof(struct objc_class));
    Class isa = alloc_from_default_zone(sizeof(struct objc_class));
    struct objc_method_list **mlp0, **mlp1;
    mlp0 = NULL;                                  // method_list_alloc(16);
    mlp1 = NULL;                                  // method_list_alloc(4);

    c->subclass_list = NULL;
    c->class_pointer = isa;
    c->super_class = super_class->name;           // gnu runtime
    c->name = strdup(name);
    c->version = 0;
    c->info = _CLS_CLASS;                         //  + _CLS_METHOD_ARRAY;
    c->instance_size = super_class ? super_class->instance_size : 0;
    c->ivars = NULL;
    c->methods = mlp0;
    //c->cache = NULL;
    c->protocols = NULL;
    void __objc_install_premature_dtable (Class class);
    __objc_install_premature_dtable (c);          // gnu runtime

    isa->subclass_list = NULL;
    isa->class_pointer = super_class->class_pointer->class_pointer;
    isa->super_class = super_class ? super_class->class_pointer : 0;
    isa->name = c->name;
    isa->version = 5;
    isa->info = _CLS_META + _CLS_INITIALIZED;     //  + _CLS_METHOD_ARRAY;
    isa->instance_size = super_class->class_pointer->instance_size;
    isa->ivars = NULL;
    isa->methods = mlp1;
    //isa->cache = NULL;
    isa->protocols = NULL;
    __objc_install_premature_dtable (isa);        // gnu runtime
    return c;
}
#endif
#endif
#ifndef IPHONE
void objc_registerClassPair(Class cls)
{
    objc_addClass(cls);
}

Class object_getClass(id obj)
{
#ifdef DARWIN
    return obj->isa;
#else
    return obj->class_pointer;
#endif
}

const char *class_getName(Class c)
{
    return c->name;
}
#endif

#ifdef DARWIN
void method_exchangeImplementations(Method method1, Method method2)
#else
void method_exchangeImplementations(Method_t method1, Method_t method2)
#endif
{
    char *temp_types = method1->method_types;
    method1->method_types = method2->method_types;
    method2->method_types = temp_types;

    IMP temp_imp = method1->method_imp;
    method1->method_imp = method2->method_imp;
    method2->method_imp = temp_imp;
}

// this seems to be unnecessary now.
Ivar myclass_getInstanceVariable(Class c, const char *name)
{
    if (c->ivars) {
        int i;
        for (i = 0; i < c->ivars->ivar_count; i++) {
            struct objc_ivar *ivar = &(c->ivars->ivar_list[i]);
            //NSLog(@"ivar %d: %s %s %d", i, ivar->ivar_name, ivar->ivar_type, ivar->ivar_offset);
            if (!strcmp(name, ivar->ivar_name))
                return ivar;
        }
    }
    // not found?  Try the superclass
    Class superclass = c->super_class;
    return superclass ? myclass_getInstanceVariable(superclass, name) : (Ivar) 0;
}
#endif

#ifdef LEOPARD_OBJC2
IMP nu_class_replaceMethod(Class cls, SEL name, IMP imp, const char *types)
{
    if (class_addMethod(cls, name, imp, types)) {
        return imp;
    }
    else {
        return class_replaceMethod(cls, name, imp, types);
    }
}
#endif

void class_addInstanceVariable_withSignature(Class thisClass, const char *variableName, const char *signature)
{
    #if defined(__x86_64__) || defined(IPHONE)
    extern size_t size_of_objc_type(const char *typeString);
    size_t size = size_of_objc_type(signature);
    uint8_t alignment = log2(size);
    BOOL result = class_addIvar(thisClass, variableName, size, alignment, signature);
    if (!result) {
        [NSException raise:@"NuAddIvarFailed"
            format:@"failed to add instance variable %s to class %s", variableName, class_getName(thisClass)];
    }
    //NSLog(@"adding ivar named %s to %s, result is %d", variableName, class_getName(thisClass), result);
    #else
    struct objc_ivar_list *ivars = thisClass->ivars;
    if (ivars) {
        int i = 0;
        //for (i = 0; i < ivars->ivar_count; i++) {
        //struct objc_ivar *ivar = &(ivars->ivar_list[i]);
        //NSLog(@"ivar %d: %s %s %d", i, ivar->ivar_name, ivar->ivar_type, ivar->ivar_offset);
        //}
        struct objc_ivar *last_ivar = &(ivars->ivar_list[ivars->ivar_count-1]);
        int offset = last_ivar->ivar_offset  + size_of_objc_type(ivar_getTypeEncoding(last_ivar));
        //NSLog(@"the next ivar goes here: %d", offset);
        struct objc_ivar *new_ivar = (struct objc_ivar *) malloc (sizeof (struct objc_ivar));
        new_ivar->ivar_name = strdup(variableName);
        new_ivar->ivar_type = strdup(signature);
        new_ivar->ivar_offset = offset;
        struct objc_ivar_list *new_ivar_list = (struct objc_ivar_list *) malloc (sizeof (struct objc_ivar_list) + (ivars->ivar_count) * sizeof(struct objc_ivar));
        new_ivar_list->ivar_count = ivars->ivar_count + 1;
        for (i = 0; i < ivars->ivar_count; i++)
            new_ivar_list->ivar_list[i] = ivars->ivar_list[i];
        new_ivar_list->ivar_list[ivars->ivar_count] = *new_ivar;
        thisClass->ivars = new_ivar_list;
        thisClass->instance_size += size_of_objc_type(new_ivar->ivar_type);
    }
    else {
        int offset = thisClass->instance_size;
        //NSLog(@"the next ivar goes here: %d", offset);
        struct objc_ivar *new_ivar = (struct objc_ivar *) malloc (sizeof (struct objc_ivar));
        new_ivar->ivar_name = strdup(variableName);
        new_ivar->ivar_type = strdup(signature);
        new_ivar->ivar_offset = offset;
        struct objc_ivar_list *new_ivar_list = (struct objc_ivar_list *) malloc (sizeof (struct objc_ivar_list));
        new_ivar_list->ivar_count = 1;
        new_ivar_list->ivar_list[0] = *new_ivar;
        thisClass->ivars = new_ivar_list;
        thisClass->instance_size += size_of_objc_type(new_ivar->ivar_type);
    }
    #endif
}

BOOL nu_copyInstanceMethod(Class destinationClass, Class sourceClass, SEL selector)
{
#ifdef DARWIN
    Method m = class_getInstanceMethod(sourceClass, selector);
#else
    Method_t m = class_getInstanceMethod(sourceClass, selector);
#endif
    if (!m) return NO;

    IMP imp = method_getImplementation(m);
    if (!imp) return NO;
    const char *signature = method_getTypeEncoding(m);
    if (!signature) return NO;
    BOOL result = (nu_class_replaceMethod(destinationClass, selector, imp, signature) != 0);
    return result;
}

BOOL nu_objectIsKindOfClass(id object, Class class)
{
    if (object == NULL)
        return NO;
#ifdef DARWIN
    Class classCursor = object->isa;
#else
    Class classCursor = object->class_pointer;
#endif
    while (classCursor) {
        if (classCursor == class) return YES;
        classCursor = class_getSuperclass(classCursor);
    }
    return NO;
}

// This function attempts to recognize the return type from a method signature.
// It scans across the signature until it finds a complete return type string,
// then it inserts a null to mark the end of the string.
void nu_markEndOfObjCTypeString(char *type, size_t len)
{
    size_t i;
    char final_char = 0;
    char start_char = 0;
    int depth = 0;
    for (i = 0; i < len; i++) {
        switch(type[i]) {
            case '[':
            case '{':
            case '(':
                // we want to scan forward to a closing character
                if (!final_char) {
                    start_char = type[i];
                    final_char = (start_char == '[') ? ']' : (start_char == '(') ? ')' : '}';
                    depth = 1;
                }
                else if (type[i] == start_char) {
                    depth++;
                }
                break;
            case ']':
            case '}':
            case ')':
                if (type[i] == final_char) {
                    depth--;
                    if (depth == 0) {
                        if (i+1 < len)
                            type[i+1] = 0;
                        return;
                    }
                }
                break;
            case 'b':                             // bitfields
                if (depth == 0) {
                    // scan forward, reading all subsequent digits
                    i++;
                    while ((i < len) && (type[i] >= '0') && (type[i] <= '9'))
                        i++;
                    if (i+1 < len)
                        type[i+1] = 0;
                    return;
                }
            case '^':                             // pointer
            case 'r':                             // const
            case 'n':                             // in
            case 'N':                             // inout
            case 'o':                             // out
            case 'O':                             // bycopy
            case 'R':                             // byref
            case 'V':                             // oneway
                break;                            // keep going, these are all modifiers.
            case 'c': case 'i': case 's': case 'l': case 'q':
            case 'C': case 'I': case 'S': case 'L': case 'Q':
            case 'f': case 'd': case 'B': case 'v': case '*':
            case '@': case '#': case ':': case '?': default:
                if (depth == 0) {
                    if (i+1 < len)
                        type[i+1] = 0;
                    return;
                }
                break;
        }
    }
}
