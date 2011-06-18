/*
 @file NuObjCRuntime.m
 @description Nu extensions to the Objective-C runtime.
 Includes replacements for Objective-C 2.0 enhancements that are
 only available in Apple's OS X 10.5 (Leopard).
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

// Undefine __OBJC2__ to get access to data structures in the ObjC runtime.
// This triggers deprecation warnings on Leopard.
#ifndef IPHONE
#undef __OBJC2__
#endif

#define LEOPARD_OBJC2

#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#ifndef IPHONE
#include <objc/objc-class.h>
#endif
#include <math.h>
#import <Foundation/Foundation.h> // for NSException

#include "NuObjCRuntime.h"

#ifdef IPHONE

#import "objc/runtime.h"

IMP nu_class_replaceMethod(Class cls, SEL name, IMP imp, const char *types) {
	return class_replaceMethod(cls, name, imp, types);
}
#endif


#ifndef LEOPARD_OBJC2
NEVER COMPILE ME

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
    method_list->method_list[0].method_name = name;
    method_list->method_list[0].method_types = strdup(types);
    method_list->method_list[0].method_imp = imp;
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

Method *class_copyMethodList(Class cls, unsigned int *outCount)
{
    // first count the methods
    int count = 0;
    struct objc_method_list *mlist;
    void *iterator = 0;
    while (( mlist = class_nextMethodList( cls, &iterator ) ))
        count += mlist->method_count;
    // then copy the methods into the list
    Method *list = (Method *) malloc (count * sizeof(Method));
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


const char *ivar_getName(Ivar v)
{
    return v->ivar_name;
}

ptrdiff_t ivar_getOffset(Ivar v)
{
    return (ptrdiff_t) v->ivar_offset;
}

const char *ivar_getTypeEncoding(Ivar v)
{
    return v->ivar_type;
}
#endif

char *method_copyArgumentType(Method m, unsigned int index)
{
    int offset;
    const char *type;
    method_getArgumentInfo(m, index, &type, &offset);
    char *copy = strdup(type);
    nu_markEndOfObjCTypeString(copy, strlen(copy));
    return copy;
}

void method_getArgumentType(Method m, unsigned int index, char *dst, size_t dst_len)
{
    int offset;
    const char *type;
    method_getArgumentInfo(m, index, &type, &offset);
    strncpy(dst, type, dst_len);
    nu_markEndOfObjCTypeString(dst, dst_len);
}

char *method_copyReturnType(Method m)
{
    char *type = strdup(m->method_types);
    nu_markEndOfObjCTypeString(type, strlen(type));
    return type;
}

void method_getReturnType(Method m, char *dst, size_t dst_len)
{
    strncpy(dst, m->method_types, dst_len);
    nu_markEndOfObjCTypeString(dst, dst_len);
}

IMP method_getImplementation(Method m)
{
    return m->method_imp;
}

SEL method_getName(Method m)
{
    return m->method_name;
}

const char *method_getTypeEncoding(Method m)
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
Class objc_allocateClassPair(Class super_class, const char *name, size_t extraBytes)
{thisnevergetscompiled
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
#endif
#ifndef IPHONE
void objc_registerClassPair(Class cls)
{
    objc_addClass(cls);
}

Class object_getClass(id obj)
{
    return obj->isa;
}

const char *class_getName(Class c)
{
    return c->name;
}
#endif

void method_exchangeImplementations(Method method1, Method method2)
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
#ifndef IPHONE
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
    Method m = class_getInstanceMethod(sourceClass, selector);
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
    Class classCursor = object_getClass(object);
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
