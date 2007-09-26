// objc_runtime.m
//  Nu extensions to the Objective-C runtime.  Includes replacements for Objective-C 2.0 enhancements
//  that are only available in Apple's OS X 10.5 (Leopard).
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#include "objc/objc-class.h"

#ifndef LEOPARD_OBJC2

#include "objc_runtime.h"

BOOL class_hasMethod(Class cls, SEL name)
{
    // Method existing_method = class_getInstanceMethod(cls, name);
    // if (!existing_method) return FALSE;
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
                return TRUE;
        }
    }
    return FALSE;
}

IMP class_replaceMethod(Class cls, SEL name, IMP imp, const char *types)
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
    return NULL;
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

char *method_copyArgumentType(Method m, unsigned int index)
{
    int offset;
    const char *type;
    method_getArgumentInfo(m, index, &type, &offset);
    char *copy = strdup(type);
    mark_end_of_type_string(copy, strlen(copy));
    return copy;
}

void method_getArgumentType(Method m, unsigned int index, char *dst, size_t dst_len)
{
    int offset;
    const char *type;
    method_getArgumentInfo(m, index, &type, &offset);
    strncpy(dst, type, dst_len);
    mark_end_of_type_string(dst, dst_len);
}

char *method_copyReturnType(Method m)
{
    char *type = strdup(m->method_types);
    mark_end_of_type_string(type, strlen(type));
    return type;
}

void method_getReturnType(Method m, char *dst, size_t dst_len)
{
    strncpy(dst, m->method_types, dst_len);
    mark_end_of_type_string(dst, dst_len);
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

// this function was taken from RubyCocoa
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

void objc_registerClassPair(Class cls)
{
    objc_addClass(cls);
}

Class object_getClass(id obj)
{
    return obj->isa;
}
#endif

Ivar class_findInstanceVariable(Class c, const char *name)
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
    return superclass ? class_findInstanceVariable(superclass, name) : 0;
}

Ivar object_findInstanceVariable(id object, const char *name)
{
    Class c = [object class];
    return class_findInstanceVariable(c, name);
}

// This function attempts to recognize the return type from a method signature.
// It scans across the signature until it finds a complete return type string,
// then it inserts a null to mark the end of the string.
void mark_end_of_type_string(char *type, size_t len)
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
