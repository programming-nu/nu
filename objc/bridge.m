/*!
@file bridge.m
@description The Nu bridge to Objective-C.
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
#ifdef LINUX
#define __USE_GNU
#endif
#import <Foundation/Foundation.h>
#ifdef IPHONE
#import <UIKit/UIKit.h>
#define NSRect CGRect
#define NSPoint CGPoint
#define NSSize CGSize
#endif
#import "objc_runtime.h"
#import "class.h"
#import "block.h"
#import "symbol.h"
#import "operator.h"
#import "bridge.h"
#import "extensions.h"
#import "st.h"
#import "reference.h"
#import "pointer.h"
#import "handler.h"
#import <sys/mman.h>

/* 
 * types:
 * c char
 * i int
 * s short
 * l long
 * q long long
 * C unsigned char
 * I unsigned int
 * S unsigned short
 * L unsigned long
 * Q unsigned long long
 * f float
 * d double
 * B bool (c++)
 * v void
 * * char *
 * @ id
 * # Class
 * : SEL
 * ? unknown
 * b4             bit field of 4 bits
 * ^type          pointer to type
 * [type]         array
 * {name=type...} structure
 * (name=type...) union
 *
 * modifiers:
 * r const
 * n in
 * N inout
 * o out
 * O bycopy
 * R byref
 * V oneway
 */

st_table *nu_block_table = NULL;

#ifdef __x86_64__

#define NSRECT_SIGNATURE0 "{_NSRect={_NSPoint=dd}{_NSSize=dd}}"
#define NSRECT_SIGNATURE1 "{_NSRect=\"origin\"{_NSPoint=\"x\"d\"y\"d}\"size\"{_NSSize=\"width\"d\"height\"d}}"
#define NSRECT_SIGNATURE2 "{_NSRect}"

#define CGRECT_SIGNATURE0 "{CGRect={CGPoint=dd}{CGSize=dd}}"
#define CGRECT_SIGNATURE1 "{CGRect=\"origin\"{CGPoint=\"x\"d\"y\"d}\"size\"{CGSize=\"width\"d\"height\"d}}"
#define CGRECT_SIGNATURE2 "{CGRect}"

#define NSRANGE_SIGNATURE "{_NSRange=QQ}"
#define NSRANGE_SIGNATURE1 "{_NSRange}"

#define NSPOINT_SIGNATURE0 "{_NSPoint=dd}"
#define NSPOINT_SIGNATURE1 "{_NSPoint=\"x\"d\"y\"d}"
#define NSPOINT_SIGNATURE2 "{_NSPoint}"

#define CGPOINT_SIGNATURE "{CGPoint=dd}"

#define NSSIZE_SIGNATURE0 "{_NSSize=dd}"
#define NSSIZE_SIGNATURE1 "{_NSSize=\"width\"d\"height\"d}"
#define NSSIZE_SIGNATURE2 "{_NSSize}"

#define CGSIZE_SIGNATURE "{CGSize=dd}"

#else

#define NSRECT_SIGNATURE0 "{_NSRect={_NSPoint=ff}{_NSSize=ff}}"
#define NSRECT_SIGNATURE1 "{_NSRect=\"origin\"{_NSPoint=\"x\"f\"y\"f}\"size\"{_NSSize=\"width\"f\"height\"f}}"
#define NSRECT_SIGNATURE2 "{_NSRect}"

#define CGRECT_SIGNATURE0 "{CGRect={CGPoint=ff}{CGSize=ff}}"
#define CGRECT_SIGNATURE1 "{CGRect=\"origin\"{CGPoint=\"x\"f\"y\"f}\"size\"{CGSize=\"width\"f\"height\"f}}"
#define CGRECT_SIGNATURE2 "{CGRect}"

#define NSRANGE_SIGNATURE "{_NSRange=II}"
#define NSRANGE_SIGNATURE1 "{_NSRange}"

#define NSPOINT_SIGNATURE0 "{_NSPoint=ff}"
#define NSPOINT_SIGNATURE1 "{_NSPoint=\"x\"f\"y\"f}"
#define NSPOINT_SIGNATURE2 "{_NSPoint}"

#define CGPOINT_SIGNATURE "{CGPoint=ff}"

#define NSSIZE_SIGNATURE0 "{_NSSize=ff}"
#define NSSIZE_SIGNATURE1 "{_NSSize=\"width\"f\"height\"f}"
#define NSSIZE_SIGNATURE2 "{_NSSize}"

#define CGSIZE_SIGNATURE "{CGSize=ff}"
#endif

// private ffi types
static int initialized_ffi_types = false;
static ffi_type ffi_type_nspoint;
static ffi_type ffi_type_nssize;
static ffi_type ffi_type_nsrect;
static ffi_type ffi_type_nsrange;

void initialize_ffi_types(void)
{
    if (initialized_ffi_types) return;
    initialized_ffi_types = true;

    // It would be better to do this automatically by parsing the ObjC type signatures
    ffi_type_nspoint.size = 0;                    // to be computed automatically
    ffi_type_nspoint.alignment = 0;
    ffi_type_nspoint.type = FFI_TYPE_STRUCT;
    ffi_type_nspoint.elements = malloc(3 * sizeof(ffi_type*));
    #ifdef __x86_64__
    ffi_type_nspoint.elements[0] = &ffi_type_double;
    ffi_type_nspoint.elements[1] = &ffi_type_double;
    #else
    ffi_type_nspoint.elements[0] = &ffi_type_float;
    ffi_type_nspoint.elements[1] = &ffi_type_float;
    #endif
    ffi_type_nspoint.elements[2] = NULL;

    ffi_type_nssize.size = 0;                     // to be computed automatically
    ffi_type_nssize.alignment = 0;
    ffi_type_nssize.type = FFI_TYPE_STRUCT;
    ffi_type_nssize.elements = malloc(3 * sizeof(ffi_type*));
    #ifdef __x86_64__
    ffi_type_nssize.elements[0] = &ffi_type_double;
    ffi_type_nssize.elements[1] = &ffi_type_double;
    #else
    ffi_type_nssize.elements[0] = &ffi_type_float;
    ffi_type_nssize.elements[1] = &ffi_type_float;
    #endif
    ffi_type_nssize.elements[2] = NULL;

    ffi_type_nsrect.size = 0;                     // to be computed automatically
    ffi_type_nsrect.alignment = 0;
    ffi_type_nsrect.type = FFI_TYPE_STRUCT;
    ffi_type_nsrect.elements = malloc(3 * sizeof(ffi_type*));
    ffi_type_nsrect.elements[0] = &ffi_type_nspoint;
    ffi_type_nsrect.elements[1] = &ffi_type_nssize;
    ffi_type_nsrect.elements[2] = NULL;

    ffi_type_nsrange.size = 0;                    // to be computed automatically
    ffi_type_nsrange.alignment = 0;
    ffi_type_nsrange.type = FFI_TYPE_STRUCT;
    ffi_type_nsrange.elements = malloc(3 * sizeof(ffi_type*));
    #ifdef __x86_64__
    ffi_type_nsrange.elements[0] = &ffi_type_uint64;
    ffi_type_nsrange.elements[1] = &ffi_type_uint64;
    #else
    ffi_type_nsrange.elements[0] = &ffi_type_uint;
    ffi_type_nsrange.elements[1] = &ffi_type_uint;
    #endif
    ffi_type_nsrange.elements[2] = NULL;
}

char get_typeChar_from_typeString(const char *typeString)
{
    int i = 0;
    char typeChar = typeString[i];
    while ((typeChar == 'r') || (typeChar == 'R') ||
        (typeChar == 'n') || (typeChar == 'N') ||
        (typeChar == 'o') || (typeChar == 'O') ||
        (typeChar == 'V')
    ) {
        // uncomment the following two lines to complain about unused quantifiers in ObjC type encodings
        // if (typeChar != 'r')                      // don't worry about const
        //     NSLog(@"ignoring qualifier %c in %s", typeChar, typeString);
        typeChar = typeString[++i];
    }
    return typeChar;
}

ffi_type *ffi_type_for_objc_type(const char *typeString)
{
    char typeChar = get_typeChar_from_typeString(typeString);
    switch (typeChar) {
        case 'f': return &ffi_type_float;
        case 'd': return &ffi_type_double;
        case 'v': return &ffi_type_void;
        case 'B': return &ffi_type_uchar;
        case 'C': return &ffi_type_uchar;
        case 'c': return &ffi_type_schar;
        case 'S': return &ffi_type_ushort;
        case 's': return &ffi_type_sshort;
        case 'I': return &ffi_type_uint;
        case 'i': return &ffi_type_sint;
        #ifdef __x86_64__
        case 'L': return &ffi_type_ulong;
        case 'l': return &ffi_type_slong;
        #else
        case 'L': return &ffi_type_uint;
        case 'l': return &ffi_type_sint;
        #endif
        case 'Q': return &ffi_type_uint64;
        case 'q': return &ffi_type_sint64;
        case '@': return &ffi_type_pointer;
        case '#': return &ffi_type_pointer;
        case '*': return &ffi_type_pointer;
        case ':': return &ffi_type_pointer;
        case '^': return &ffi_type_pointer;
        case '{':
        {
            if (!strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
            ) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nsrect;
            }
            else if (
                !strcmp(typeString, NSRANGE_SIGNATURE) ||
                !strcmp(typeString, NSRANGE_SIGNATURE1)
            ) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nsrange;
            }
            else if (
                !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                !strcmp(typeString, CGPOINT_SIGNATURE)
            ) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nspoint;
            }
            else if (
                !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                !strcmp(typeString, CGSIZE_SIGNATURE)
            ) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nssize;
            }
            else {
                NSLog(@"unknown type identifier %s", typeString);
                return &ffi_type_void;
            }
        }
        default:
        {
            NSLog(@"unknown type identifier %s", typeString);
            return &ffi_type_void;                // urfkd
        }
    }
}

size_t size_of_objc_type(const char *typeString)
{
    char typeChar = get_typeChar_from_typeString(typeString);
    switch (typeChar) {
        case 'f': return sizeof(float);
        case 'd': return sizeof(double);
        case 'v': return sizeof(void *);
        case 'B': return sizeof(unsigned int);
        case 'C': return sizeof(unsigned int);
        case 'c': return sizeof(int);
        case 'S': return sizeof(unsigned int);
        case 's': return sizeof(int);
        case 'I': return sizeof(unsigned int);
        case 'i': return sizeof(int);
        case 'L': return sizeof(unsigned long);
        case 'l': return sizeof(long);
        case 'Q': return sizeof(unsigned long long);
        case 'q': return sizeof(long long);
        case '@': return sizeof(void *);
        case '#': return sizeof(void *);
        case '*': return sizeof(void *);
        case ':': return sizeof(void *);
        case '^': return sizeof(void *);
        case '{':
        {
            if (!strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
            ) {
                return sizeof(NSRect);
            }
            else if (
                !strcmp(typeString, NSRANGE_SIGNATURE) ||
                !strcmp(typeString, NSRANGE_SIGNATURE1)
            ) {
                return sizeof(NSRange);
            }
            else if (
                !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                !strcmp(typeString, CGPOINT_SIGNATURE)
            ) {
                return sizeof(NSPoint);
            }
            else if (
                !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                !strcmp(typeString, CGSIZE_SIGNATURE)
            ) {
                return sizeof(NSSize);
            }
            else {
                NSLog(@"unknown type identifier %s", typeString);
                return sizeof (void *);
            }
        }
        default:
        {
            NSLog(@"unknown type identifier %s", typeString);
            return sizeof (void *);
        }
    }
}

void *value_buffer_for_objc_type(const char *typeString)
{
    char typeChar = get_typeChar_from_typeString(typeString);
    switch (typeChar) {
        case 'f': return malloc(sizeof(float));
        case 'd': return malloc(sizeof(double));
        case 'v': return malloc(sizeof(void *));
        case 'B': return malloc(sizeof(unsigned int));
        case 'C': return malloc(sizeof(unsigned int));
        case 'c': return malloc(sizeof(int));
        case 'S': return malloc(sizeof(unsigned int));
        case 's': return malloc(sizeof(int));
        case 'I': return malloc(sizeof(unsigned int));
        case 'i': return malloc(sizeof(int));
        case 'L': return malloc(sizeof(unsigned long));
        case 'l': return malloc(sizeof(long));
        case 'Q': return malloc(sizeof(unsigned long long));
        case 'q': return malloc(sizeof(long long));
        case '@': return malloc(sizeof(void *));
        case '#': return malloc(sizeof(void *));
        case '*': return malloc(sizeof(void *));
        case ':': return malloc(sizeof(void *));
        case '^': return malloc(sizeof(void *));
        case '{':
        {
            if (!strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
            ) {
                return malloc(sizeof(NSRect));
            }
            else if (
                !strcmp(typeString, NSRANGE_SIGNATURE) ||
                !strcmp(typeString, NSRANGE_SIGNATURE1)
            ) {
                return malloc(sizeof(NSRange));
            }
            else if (
                !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                !strcmp(typeString, CGPOINT_SIGNATURE)
            ) {
                return malloc(sizeof(NSPoint));
            }
            else if (
                !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                !strcmp(typeString, CGSIZE_SIGNATURE)
            ) {
                return malloc(sizeof(NSSize));
            }
            else {
                NSLog(@"unknown type identifier %s", typeString);
                return malloc(sizeof (void *));
            }
        }
        default:
        {
            NSLog(@"unknown type identifier %s", typeString);
            return malloc(sizeof (void *));
        }
    }
}

int set_objc_value_from_nu_value(void *objc_value, id nu_value, const char *typeString)
{
    //NSLog(@"VALUE => %s", typeString);
    char typeChar = get_typeChar_from_typeString(typeString);
    switch (typeChar) {
        case '@':
        {
            if ((nu_value == Nu__null)) {
                *((id *) objc_value) = nil;
                return NO;
            }
            *((id *) objc_value) = nu_value;
            return NO;
        }
        case 'I':
        #ifndef __ppc__
        case 'S':
        case 'C':
        #endif
            {
                if (nu_value == Nu__null) {
                    *((unsigned int *) objc_value) = 0;
                    return NO;
                }
                *((unsigned int *) objc_value) = [nu_value unsignedIntValue];
                return NO;
            }
        #ifdef __ppc__
        case 'S':
        {
            if (nu_value == Nu__null) {
                *((unsigned short *) objc_value) = 0;
                return NO;
            }
            *((unsigned short *) objc_value) = [nu_value unsignedShortValue];
            return NO;
        }
        case 'C':
        {
            if (nu_value == Nu__null) {
                *((unsigned char *) objc_value) = 0;
                return NO;
            }
            *((unsigned char *) objc_value) = [nu_value unsignedCharValue];
            return NO;
        }
        #endif
        case 'i':
        #ifndef __ppc__
        case 's':
        case 'c':
        #endif
            {
                if (nu_value == [NSNull null]) {
                    *((int *) objc_value) = 0;
                    return NO;
                }
                *((int *) objc_value) = [nu_value intValue];
                return NO;
            }
        #ifdef __ppc__
        case 's':
        {
            if (nu_value == Nu__null) {
                *((short *) objc_value) = 0;
                return NO;
            }
            *((short *) objc_value) = [nu_value shortValue];
            return NO;
        }
        case 'c':
        {
            if (nu_value == Nu__null) {
                *((char *) objc_value) = 0;
                return NO;
            }
            *((char *) objc_value) = [nu_value charValue];
            return NO;
        }
        #endif
        case 'L':
        {
            if (nu_value == [NSNull null]) {
                *((unsigned long *) objc_value) = 0;
                return NO;
            }
            *((unsigned long *) objc_value) = [nu_value unsignedLongValue];
            return NO;
        }
        case 'l':
        {
            if (nu_value == [NSNull null]) {
                *((long *) objc_value) = 0;
                return NO;
            }
            *((long *) objc_value) = [nu_value longValue];
            return NO;
        }
        case 'Q':
        {
            if (nu_value == [NSNull null]) {
                *((unsigned long long *) objc_value) = 0;
                return NO;
            }
            *((unsigned long long *) objc_value) = [nu_value unsignedLongLongValue];
            return NO;
        }
        case 'q':
        {
            if (nu_value == [NSNull null]) {
                *((long long *) objc_value) = 0;
                return NO;
            }
            *((long long *) objc_value) = [nu_value longLongValue];
            return NO;
        }
        case 'd':
        {
            *((double *) objc_value) = [nu_value doubleValue];
            return NO;
        }
        case 'f':
        {
            *((float *) objc_value) = (float) [nu_value doubleValue];
            return NO;
        }
        case 'v':
        {
            return NO;
        }
        case ':':
        {
            // selectors must be strings (symbols could be ok too...)
            if (!nu_value || (nu_value == [NSNull null])) {
                *((SEL *) objc_value) = 0;
                return NO;
            }
            const char *selectorName = [nu_value cStringUsingEncoding:NSUTF8StringEncoding];
            if (selectorName) {
                #ifdef DARWIN
                *((SEL *) objc_value) = sel_registerName(selectorName);
                #else
                *((SEL *) objc_value) = sel_register_name(selectorName);
                #endif
                return NO;
            }
            else {
                NSLog(@"can't convert %@ to a selector", nu_value);
                return NO;
            }
        }
        case '{':
        {
            if (
                !strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
            ) {
                NSRect *rect = (NSRect *) objc_value;
                id cursor = nu_value;
                #ifdef DARWIN
                rect->origin.x = (CGFloat) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->origin.y = (CGFloat) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->size.width = (CGFloat) [[cursor car] doubleValue];          cursor = [cursor cdr];
                rect->size.height = (CGFloat) [[cursor car] doubleValue];
                #else
                rect->origin.x = (double) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->origin.y = (double) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->size.width = (double) [[cursor car] doubleValue];          cursor = [cursor cdr];
                rect->size.height = (double) [[cursor car] doubleValue];
                #endif
                //NSLog(@"nu->rect: %x %f %f %f %f", (void *) rect, rect->origin.x, rect->origin.y, rect->size.width, rect->size.height);
                return NO;
            }
            else if (
                !strcmp(typeString, NSRANGE_SIGNATURE) ||
                !strcmp(typeString, NSRANGE_SIGNATURE1)
            ) {
                NSRange *range = (NSRange *) objc_value;
                id cursor = nu_value;
                range->location = [[cursor car] intValue];          cursor = [cursor cdr];;
                range->length = [[cursor car] intValue];
                return NO;
            }
            else if (
                !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                !strcmp(typeString, CGSIZE_SIGNATURE)
            ) {
                NSSize *size = (NSSize *) objc_value;
                id cursor = nu_value;
                size->width = [[cursor car] doubleValue];           cursor = [cursor cdr];;
                size->height =  [[cursor car] doubleValue];
                return NO;
            }
            else if (
                !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                !strcmp(typeString, CGPOINT_SIGNATURE)
            ) {
                NSPoint *point = (NSPoint *) objc_value;
                id cursor = nu_value;
                point->x = [[cursor car] doubleValue];          cursor = [cursor cdr];;
                point->y =  [[cursor car] doubleValue];
                return NO;
            }
            else {
                NSLog(@"UNIMPLEMENTED: can't wrap structure of type %s", typeString);
                return NO;
            }
        }

        case '^':
        {
            if (!nu_value || (nu_value == [NSNull null])) {
                *((char ***) objc_value) = NULL;
                return NO;
            }
            // pointers require some work.. and cleanup. This LEAKS.
            if (!strcmp(typeString, "^*")) {
                // array of strings, which requires an NSArray or NSNull (handled above)
                if (nu_objectIsKindOfClass(nu_value, [NSArray class])) {
                    int array_size = [nu_value count];
                    char **array = (char **) malloc (array_size * sizeof(char *));
                    int i;
                    for (i = 0; i < array_size; i++) {
                        array[i] = strdup([[nu_value objectAtIndex:i] cStringUsingEncoding:NSUTF8StringEncoding]);
                    }
                    *((char ***) objc_value) = array;
                    return NO;
                }
                else {
                    #ifdef DARWIN
                    NSLog(@"can't convert value of type %s to a pointer to strings", class_getName([nu_value class]));
                    #else
                    NSLog(@"can't convert value of type %s to a pointer to strings", class_get_class_name([nu_value class]));
                    #endif
                    *((char ***) objc_value) = NULL;
                    return NO;
                }
            }
            else if (!strcmp(typeString, "^@")) {
                if (nu_objectIsKindOfClass(nu_value, [NuReference class])) {
                    *((id **) objc_value) = [nu_value pointerToReferencedObject];
                    return YES;
                }
            }
            else if (nu_objectIsKindOfClass(nu_value, [NuPointer class])) {
                if ([nu_value pointer] == 0)
                    [nu_value allocateSpaceForTypeString:[NSString stringWithCString:typeString encoding:NSUTF8StringEncoding]];
                *((void **) objc_value) = [nu_value pointer];
                return NO;                        // don't ask the receiver to retain this, it's just a pointer
            }
            else {
                *((void **) objc_value) = nu_value;
                return NO;                        // don't ask the receiver to retain this, it isn't expecting an object
            }
        }

        case '*':
        {
            *((char **) objc_value) = strdup([[nu_value stringValue] cStringUsingEncoding:NSUTF8StringEncoding]);
            return NO;
        }

        case '#':
        {
            if (nu_objectIsKindOfClass(nu_value, [NuClass class])) {
                *((Class *)objc_value) = [nu_value wrappedClass];
                return NO;
            }
            else {
                #ifdef DARWIN
                NSLog(@"can't convert value of type %s to CLASS", class_getName([nu_value class]));
                #else
                NSLog(@"can't convert value of type %s to CLASS", class_get_class_name([nu_value class]));
                #endif
                *((id *) objc_value) = 0;
                return NO;
            }
        }
        default:
            NSLog(@"can't wrap argument of type %s", typeString);
    }
    return NO;
}

id get_nu_value_from_objc_value(void *objc_value, const char *typeString)
{
    //NSLog(@"%s => VALUE", typeString);
    char typeChar = get_typeChar_from_typeString(typeString);
    switch(typeChar) {
        case 'v':
        {
            return [NSNull null];
        }
        case '@':
        {
            id result = *((id *)objc_value);
            return result ? result : (id)[NSNull null];
        }
        case '#':
        {
            Class c = *((Class *)objc_value);
            return c ? [[NuClass alloc] initWithClass:c] : Nu__null;
        }
        #ifndef __ppc__
        case 'c':
        {
            return [NSNumber numberWithChar:*((char *)objc_value)];
        }
        case 's':
        {
            return [NSNumber numberWithShort:*((short *)objc_value)];
        }
        #else
        case 'c':
        case 's':
        #endif
        case 'i':
        {
            return [NSNumber numberWithInt:*((int *)objc_value)];
        }
        #ifndef __ppc__
        case 'C':
        {
            return [NSNumber numberWithUnsignedChar:*((unsigned char *)objc_value)];
        }
        case 'S':
        {
            return [NSNumber numberWithUnsignedShort:*((unsigned short *)objc_value)];
        }
        #else
        case 'C':
        case 'S':
        #endif
        case 'I':
        {
            return [NSNumber numberWithUnsignedInt:*((unsigned int *)objc_value)];
        }
        case 'l':
        {
            return [NSNumber numberWithLong:*((long *)objc_value)];
        }
        case 'L':
        {
            return [NSNumber numberWithUnsignedLong:*((unsigned long *)objc_value)];
        }
        case 'q':
        {
            return [NSNumber numberWithLongLong:*((long long *)objc_value)];
        }
        case 'Q':
        {
            return [NSNumber numberWithUnsignedLongLong:*((unsigned long long *)objc_value)];
        }
        case 'f':
        {
            return [NSNumber numberWithFloat:*((float *)objc_value)];
        }
        case 'd':
        {
            return [NSNumber numberWithDouble:*((double *)objc_value)];
        }
        case ':':
        {
            SEL sel = *((SEL *)objc_value);
            #ifdef DARWIN
            return [[NSString stringWithCString:sel_getName(sel) encoding:NSUTF8StringEncoding] retain];
            #else
            return [[NSString stringWithCString:sel_get_name(sel) encoding:NSUTF8StringEncoding] retain];
            #endif
        }
        case '{':
        {
            if (
                !strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
                !strcmp(typeString, CGRECT_SIGNATURE0) ||
                !strcmp(typeString, CGRECT_SIGNATURE1) ||
                !strcmp(typeString, CGRECT_SIGNATURE2)
            ) {
                NSRect *rect = (NSRect *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithDouble:rect->origin.x]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:rect->origin.y]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:rect->size.width]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:rect->size.height]];
                //NSLog(@"converting rect at %x to list: %@", (void *) rect, [list stringValue]);
                return list;
            }
            else if (
                !strcmp(typeString, NSRANGE_SIGNATURE) ||
                !strcmp(typeString, NSRANGE_SIGNATURE1)
            ) {
                NSRange *range = (NSRange *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithInt:range->location]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithInt:range->length]];
                return list;
            }
            else if (
                !strcmp(typeString, NSPOINT_SIGNATURE0) ||
                !strcmp(typeString, NSPOINT_SIGNATURE1) ||
                !strcmp(typeString, NSPOINT_SIGNATURE2) ||
                !strcmp(typeString, CGPOINT_SIGNATURE)
            ) {
                NSPoint *point = (NSPoint *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithDouble:point->x]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:point->y]];
                return list;
            }
            else if (
                !strcmp(typeString, NSSIZE_SIGNATURE0) ||
                !strcmp(typeString, NSSIZE_SIGNATURE1) ||
                !strcmp(typeString, NSSIZE_SIGNATURE2) ||
                !strcmp(typeString, CGSIZE_SIGNATURE)
            ) {
                NSSize *size = (NSSize *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithDouble:size->width]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithDouble:size->height]];
                return list;
            }
            else {
                NSLog(@"UNIMPLEMENTED: can't wrap structure of type %s", typeString);
            }
        }
        case '*':
        {
            return [NSString stringWithCString:*((char **)objc_value) encoding:NSUTF8StringEncoding];
        }
        case 'B':
        {
            if (*((unsigned int *)objc_value) == 0)
                return [NSNull null];
            else
                return [NSNumber numberWithInt:1];
        }
        case '^':
        {
            if (!strcmp(typeString, "^v")) {
                if (*((unsigned long *)objc_value) == 0)
                    return [NSNull null];
                else {
                    id nupointer = [[[NuPointer alloc] init] autorelease];
                    [nupointer setPointer:*((void **)objc_value)];
                    [nupointer setTypeString:[NSString stringWithCString:typeString encoding:NSUTF8StringEncoding]];
                    return nupointer;
                }
            }
            else if (!strcmp(typeString, "^@")) {
                id reference = [[[NuReference alloc] init] autorelease];
                [reference setPointer:*((id**)objc_value)];
                return reference;
            }
            else {
                if (*((unsigned long *)objc_value) == 0)
                    return [NSNull null];
                else {
                    id nupointer = [[[NuPointer alloc] init] autorelease];
                    [nupointer setPointer:*((void **)objc_value)];
                    [nupointer setTypeString:[NSString stringWithCString:typeString encoding:NSUTF8StringEncoding]];
                    return nupointer;
                }
            }
            return [NSNull null];
        }
        default:
            NSLog (@"UNIMPLEMENTED: unable to wrap object of type %s", typeString);
            return [NSNull null];
    }

}

static void raise_argc_exception(SEL s, int count, int given)
{
    if (given != count) {
        [NSException raise:@"NuIncorrectNumberOfArguments"
            format:@"Incorrect number of arguments to selector %s. Received %d but expected %d",
            #ifdef DARWIN
            sel_getName(s),
            #else
            sel_get_name(s),
            #endif
            given,
            count];
    }
}

#define BUFSIZE 500

#define MAXPLACEHOLDERS 100
static int placeholderCount = 0;
static Class placeholderClass[MAXPLACEHOLDERS];

void nu_note_placeholders()
{
    // I don't like this. How can I automatically recognize placeholders?
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderMutableArray");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderArray");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderMutableDictionary");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderDictionary");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderString");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderValue");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderNumber");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderSet");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderMutableSet");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSPlaceholderMutableString");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSManagedObjectModel");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSXMLDocument");
    placeholderClass[placeholderCount++] = NSClassFromString(@"NSBitmapImageRep");
    #ifdef IPHONE
    placeholderClass[placeholderCount++] = NSClassFromString(@"UINavigationController");
    placeholderClass[placeholderCount++] = NSClassFromString(@"UIWindow");
    #endif
}

#ifdef DARWIN
id nu_calling_objc_method_handler(id target, Method m, NSMutableArray *args)
#else
id nu_calling_objc_method_handler(id target, Method_t m, NSMutableArray *args)
#endif
{
    // this call seems to force the class's +initialize method to be called.
    [target class];

    #ifdef DARWIN
    //NSLog(@"calling ObjC method %s with target of class %@", sel_getName(method_getName(m)), [target class]);
    #else
    //SEL sel = method_getName(m);
    //const char *name = sel_get_name(sel);
    //Class targetClass = [target class];
    //NSLog(@"calling ObjC method %s with target of class %@", sel_get_name(method_getName(m)), [target class]);
    #endif

    IMP imp = method_getImplementation(m);

    // if the imp has an associated block, this is a nu-to-nu call.
    // skip going through the ObjC runtime and evaluate the block directly.
    NuBlock *block = nil;
    if (nu_block_table && st_lookup(nu_block_table, (unsigned long)imp, (unsigned long *)&block)) {
        #ifdef DARWIN
        //NSLog(@"nu calling nu method %s of class %@", sel_getName(method_getName(m)), [target class]);
        #else
        //NSLog(@"nu calling nu method %s of class %@", sel_get_name(method_getName(m)), [target class]);
        #endif
        id arguments = [[NuCell alloc] init];
        id cursor = arguments;
        int argc = [args count];
        int i;
        for (i = 0; i < argc; i++) {
            [cursor setCdr:[[[NuCell alloc] init] autorelease]];
            cursor = [cursor cdr];
            [cursor setCar:[args objectAtIndex:i]];
        }
        id result = [block evalWithArguments:[arguments cdr] context:nil self:target];
        [arguments release];
        // ensure that methods declared to return void always return void.
        char return_type_buffer[BUFSIZE];
        method_getReturnType(m, return_type_buffer, BUFSIZE);
        return (!strcmp(return_type_buffer, "v")) ? (id)[NSNull null] : result;
    }

    // if we get here, we're going through the ObjC runtime to make the call.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    SEL s = method_getName(m);
    id result = [NSNull null];

    // dynamically construct the method call
    int argument_count = method_getNumberOfArguments(m);
    if ( [args count] != argument_count-2) {
        raise_argc_exception(s, argument_count-2, [args count]);
    }
    else {
        bool success = false;

        char return_type_buffer[BUFSIZE], arg_type_buffer[BUFSIZE];
        method_getReturnType(m, return_type_buffer, BUFSIZE);
        ffi_type *result_type = ffi_type_for_objc_type(&return_type_buffer[0]);
        void *result_value = value_buffer_for_objc_type(&return_type_buffer[0]);
        ffi_type **argument_types = (ffi_type **) malloc (argument_count * sizeof(ffi_type *));
        void **argument_values = (void **) malloc (argument_count * sizeof(void *));
        int *argument_needs_retained = (int *) malloc (argument_count * sizeof(int));
        int i;
        for (i = 0; i < argument_count; i++) {
            method_getArgumentType(m, i, &arg_type_buffer[0], BUFSIZE);
            argument_types[i] = ffi_type_for_objc_type(&arg_type_buffer[0]);
            argument_values[i] = value_buffer_for_objc_type(&arg_type_buffer[0]);
            if (i == 0)
                *((id *) argument_values[i]) = target;
            else if (i == 1)
                *((SEL *) argument_values[i]) = method_getName(m);
            else
                argument_needs_retained[i-2] = set_objc_value_from_nu_value(argument_values[i], [args objectAtIndex:(i-2)], &arg_type_buffer[0]);
        }
        ffi_cif cif2;
        int status = ffi_prep_cif(&cif2, FFI_DEFAULT_ABI, argument_count, result_type, argument_types);
        if (status != FFI_OK) {
            NSLog (@"failed to prepare cif structure");
        }
        else {
            ffi_call(&cif2, FFI_FN(imp), result_value, argument_values);
            success = true;
        }
        if (success) {
            result = get_nu_value_from_objc_value(result_value, &return_type_buffer[0]);
            // Return values should not require a release.
            // Either they are owned by an existing object or are autoreleased.
            // Since these methods create new objects that aren't autoreleased, we autorelease them.
            // But we must never release placeholders.
            bool already_retained =               // see Anguish/Buck/Yacktman, p. 104
                (s == @selector(alloc)) || (s == @selector(allocWithZone:))
                || (s == @selector(copy)) || (s == @selector(copyWithZone:))
                || (s == @selector(mutableCopy)) || (s == @selector(mutableCopyWithZone:))
                || (s == @selector(new));
            if (already_retained) {
                // Make sure this isn't an instance of a placeholder class.
                // We should never release instances of placeholder classes;
                // If you release one, you can never use it again (obviously!).
                // Suggestion to Apple: install no-op versions of release methods on all placeholder classes.
                // Here we protect ourselves against the ones we know about.
                Class resultClass = [result class];
                bool found = false;
                for (i = 0; i < placeholderCount; i++) {
                    if (resultClass == placeholderClass[i]) {
                        //NSLog(@"preserving object of class %@", resultClass);
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    [result autorelease];
                }
            }
            for (i = 0; i < [args count]; i++) {
                if (argument_needs_retained[i])
                    [[args objectAtIndex:i] retainReferencedObject];
            }

            // free the value structures
            for (i = 0; i < argument_count; i++) {
                free(argument_values[i]);
            }
            free(argument_values);
            free(result_value);
            free(argument_types);
            free(argument_needs_retained);
        }
    }
    [result retain];
    [pool release];
    [result autorelease];
    return result;
}

@interface NSAutoreleasePool (UndocumentedInterface)
+ (BOOL) autoreleasePoolExists;
@end

#ifdef LINUX
@implementation NSAutoreleasePool (UndocumentedInterface)
+ (BOOL) autoreleasePoolExists
{
    return true;                                  // this is wrong. Fix it later.
}

@end
#endif

@interface NSMethodSignature (UndocumentedInterface)
+ (id) signatureWithObjCTypes:(const char*)types;
@end

static void objc_calling_nu_method_handler(ffi_cif* cif, void* returnvalue, void** args, void* userdata)
{
    int argc = cif->nargs - 2;
    id rcv = *((id*)args[0]);                     // this is the object getting the message
    // unused: SEL sel = *((SEL*)args[1]);

    // we might need an autorelease pool (added for detachNewThreadSelector:toTarget:withObject:)
    NSAutoreleasePool *pool = [NSAutoreleasePool autoreleasePoolExists] ? 0 : [[NSAutoreleasePool alloc] init];

    NuBlock *block = ((NuBlock **)userdata)[1];
    //NSLog(@"----------------------------------------");
    //NSLog(@"calling block %@", [block stringValue]);
    id arguments = [[NuCell alloc] init];
    id cursor = arguments;
    int i;
    for (i = 0; i < argc; i++) {
        [cursor setCdr:[[[NuCell alloc] init] autorelease]];
        cursor = [cursor cdr];
        id value = get_nu_value_from_objc_value(args[i+2], ((char **)userdata)[i+2]);
        [cursor setCar:value];
    }
    id result = [block evalWithArguments:[arguments cdr] context:nil self:rcv];
    //NSLog(@"in nu method handler, putting result %@ in %x with type %s", [result stringValue], (int) returnvalue, ((char **)userdata)[0]);
    char *resultType = (((char **)userdata)[0])+1;// skip the first character, it's a flag
    set_objc_value_from_nu_value(returnvalue, result, resultType);
    #ifdef __ppc__
	// It appears that at least on PowerPC architectures, small values (short, char, ushort, uchar) passed in via 
	// the ObjC runtime use their actual type while function return values are coerced up to integers. 
	// I suppose this is because values are passed as arguments in memory and returned in registers.  
	// This may also be the case on x86 but is unobserved because x86 is little endian.
    switch (resultType[0]) {
        case 'C':
        {
            *((unsigned int *) returnvalue) = *((unsigned char *) returnvalue);
            break;
        }
        case 'c':
        {
            *((int *) returnvalue) = *((char *) returnvalue);
            break;
        }
        case 'S':
        {
            *((unsigned int *) returnvalue) = *((unsigned short *) returnvalue);
            break;
        }
        case 's':
        {
            *((int *) returnvalue) = *((short *) returnvalue);
            break;
        }
    }
    #endif
    if (((char **)userdata)[0][0] == '!') {
        //NSLog(@"retaining result for object %@, count = %d", *(id *)returnvalue, [*(id *)returnvalue retainCount]);
        [*((id *)returnvalue) retain];
    }
    [arguments release];
    [pool release];
}

char **generate_userdata(SEL sel, NuBlock *block, const char *signature)
{
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
    const char *return_type_string = [methodSignature methodReturnType];
    int argument_count = [methodSignature numberOfArguments];
    char **userdata = (char **) malloc ((argument_count+3) * sizeof(char*));
    userdata[0] = (char *) malloc (2 + strlen(return_type_string));
    #ifdef DARWIN
    const char *methodName = sel_getName(sel);
    #else
    const char *methodName = sel_get_name(sel);
    #endif
    BOOL returnsRetainedResult = NO;
    if ((!strcmp(methodName, "alloc")) ||
        (!strcmp(methodName, "allocWithZone:")) ||
        (!strcmp(methodName, "copy")) ||
        (!strcmp(methodName, "copyWithZone:")) ||
        (!strcmp(methodName, "mutableCopy")) ||
        (!strcmp(methodName, "mutableCopyWithZone:")) ||
        (!strcmp(methodName, "new")))
        returnsRetainedResult = YES;
    if (returnsRetainedResult)
        sprintf(userdata[0], "!%s", return_type_string);
    else
        sprintf(userdata[0], " %s", return_type_string);
    //NSLog(@"constructing handler for method %s with %d arguments and returnType %s", methodName, argument_count, userdata[0]);
    userdata[1] = (char *) block;
    [block retain];
    int i;
    for (i = 0; i < argument_count; i++) {
        const char *argument_type_string = [methodSignature getArgumentTypeAtIndex:i];
        if (i > 1) userdata[i] = strdup(argument_type_string);
    }
    userdata[argument_count] = NULL;
    return userdata;
}

IMP construct_method_handler(SEL sel, NuBlock *block, const char *signature)
{
    char **userdata = generate_userdata(sel, block, signature);
    IMP imp = [NuHandlerWarehouse handlerWithSelector:sel block:block signature:signature userdata:userdata];
    if (imp) {
        return imp;
    }
    int argument_count = 0;
    while (userdata[argument_count] != 0) argument_count++;
    #if 0
    #ifdef DARWIN
    const char *methodName = sel_getName(sel);
    #else
    const char *methodName = sel_get_name(sel);
    #endif
    NSLog(@"using libffi to construct handler for method %s with %d arguments and signature %s", methodName, argument_count, signature);
    #endif
    ffi_type **argument_types = (ffi_type **) malloc ((argument_count+1) * sizeof(ffi_type *));
    ffi_type *result_type = ffi_type_for_objc_type(userdata[0]+1);
    argument_types[0] = ffi_type_for_objc_type("@");
    argument_types[1] = ffi_type_for_objc_type(":");
    for (int i = 2; i < argument_count; i++)
        argument_types[i] = ffi_type_for_objc_type(userdata[i]);
    argument_types[argument_count] = NULL;
    ffi_cif *cif = (ffi_cif *)malloc(sizeof(ffi_cif));
    if (cif == NULL) {
        NSLog(@"unable to prepare closure for signature %s (could not allocate memory for cif structure)", signature);
        return NULL;
    }
    int status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argument_count, result_type, argument_types);
    if (status != FFI_OK) {
        NSLog(@"unable to prepare closure for signature %s (ffi_prep_cif failed)", signature);
        return NULL;
    }
    ffi_closure *closure = (ffi_closure *)mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if (closure == (ffi_closure *) -1) {
        NSLog(@"unable to prepare closure for signature %s (mmap failed with error %d)", signature, errno);
        return NULL;
    }
    if (closure == NULL) {
        NSLog(@"unable to prepare closure for signature %s (could not allocate memory for closure)", signature);
        return NULL;
    }
    if (ffi_prep_closure(closure, cif, objc_calling_nu_method_handler, userdata) != FFI_OK) {
        NSLog(@"unable to prepare closure for signature %s (ffi_prep_closure failed)", signature);
        return NULL;
    }
    if (mprotect(closure, sizeof(closure), PROT_READ | PROT_EXEC) == -1) {
        NSLog(@"unable to prepare closure for signature %s (mprotect failed with error %d)", signature, errno);
        return NULL;
    }
    return (IMP) closure;
}

id add_method_to_class(Class c, NSString *methodName, NSString *signature, NuBlock *block)
{
    const char *method_name_str = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
    const char *signature_str = [signature cStringUsingEncoding:NSUTF8StringEncoding];
    #ifdef DARWIN
    SEL selector = sel_registerName(method_name_str);
    #else
    SEL selector = sel_register_name(method_name_str);
    #endif

    //NuSymbolTable *symbolTable = [[block context] objectForKey:SYMBOLS_KEY];
    //[[block context] setPossiblyNullObject:[[NuClass alloc] initWithClass:c] forKey:[symbolTable symbolWithCString:"_class"]];

    IMP imp = construct_method_handler(selector, block, signature_str);
    if (imp == NULL) {
        NSLog(@"failed to construct handler for %s(%s)", method_name_str, signature_str);
        return [NSNull null];
    }

    // save the block in a hash table keyed by the imp.
    // this will let us introspect methods and optimize nu-to-nu method calls
    if (!nu_block_table) nu_block_table = st_init_numtable();
    // watch for problems caused by these ugly casts...
    st_insert(nu_block_table, (long) imp, (long) block);

    // insert the method handler in the class method table
    nu_class_replaceMethod(c, selector, imp, signature_str);
    #ifdef DARWIN
    //NSLog(@"setting handler for %s(%s) in class %s", method_name_str, signature_str, class_getName(c));
    #else
    //NSLog(@"setting handler for %s(%s) in class %s", method_name_str, signature_str, class_get_class_name(c));
    #endif
    return [NSNull null];
}

#ifdef LINUX
#define __USE_GNU
#endif
#include <dlfcn.h>

@implementation NuBridgedFunction

- (NuBridgedFunction *) initWithName:(NSString *)n signature:(NSString *)s
{
    name = strdup([n cStringUsingEncoding:NSUTF8StringEncoding]);
    signature = strdup([s cStringUsingEncoding:NSUTF8StringEncoding]);
    function = dlsym(RTLD_DEFAULT, name);
    if (!function) {
        [NSException raise:@"NuCantFindBridgedFunction"
            format:@"%s\n%s\n%s\n", dlerror(),
            "If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.",
            "In Xcode, check the 'Preserve Private External Symbols' checkbox."];
    }
    return self;
}

+ (NuBridgedFunction *) functionWithName:(NSString *)name signature:(NSString *)signature
{
    const char *function_name = [name cStringUsingEncoding:NSUTF8StringEncoding];
    void *function = dlsym(RTLD_DEFAULT, function_name);
    if (!function) {
        [NSException raise:@"NuCantFindBridgedFunction"
            format:@"%s\n%s\n%s\n", dlerror(),
            "If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.",
            "In Xcode, check the 'Preserve Private External Symbols' checkbox."];
    }
    NuBridgedFunction *wrapper = [[NuBridgedFunction alloc] initWithName:name signature:signature];
    return wrapper;
}

- (id) evalWithArguments:(id) cdr context:(NSMutableDictionary *) context
{
    //NSLog(@"----------------------------------------");
    //NSLog(@"calling C function %s with signature %s", name, signature);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    char *return_type_identifier = strdup(signature);
    nu_markEndOfObjCTypeString(return_type_identifier, strlen(return_type_identifier));

    int argument_count = 0;
    char *argument_type_identifiers[100];
    char *cursor = &signature[strlen(return_type_identifier)];
    while (*cursor != 0) {
        argument_type_identifiers[argument_count] = strdup(cursor);
        nu_markEndOfObjCTypeString(argument_type_identifiers[argument_count], strlen(cursor));
        cursor = &cursor[strlen(argument_type_identifiers[argument_count])];
        argument_count++;
    }
    //NSLog(@"calling return type is %s", return_type_identifier);
    int i;
    for (i = 0; i < argument_count; i++) {
        //    NSLog(@"argument %d type is %s", i, argument_type_identifiers[i]);
    }
    id result = [NSNull null];

    ffi_cif *cif = (ffi_cif *)malloc(sizeof(ffi_cif));

    // unused
    //char **argument_userdata = (argument_count == 0) ? NULL : (char **) malloc (argument_count * sizeof(char *));

    ffi_type *result_type = ffi_type_for_objc_type(return_type_identifier);
    ffi_type **argument_types = (argument_count == 0) ? NULL : (ffi_type **) malloc (argument_count * sizeof(ffi_type *));
    for (i = 0; i < argument_count; i++)
        argument_types[i] = ffi_type_for_objc_type(argument_type_identifiers[i]);

    int status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argument_count, result_type, argument_types);
    if (status != FFI_OK) {
        NSLog (@"failed to prepare cif structure");
        return [NSNull null];
    }

    id arg_cursor = cdr;
    void *result_value = value_buffer_for_objc_type(return_type_identifier);
    void **argument_values = (void **) malloc (argument_count * sizeof(void *));

    for (i = 0; i < argument_count; i++) {
        argument_values[i] = value_buffer_for_objc_type( argument_type_identifiers[i]);
        id arg_value = [[arg_cursor car] evalWithContext:context];
        set_objc_value_from_nu_value(argument_values[i], arg_value, argument_type_identifiers[i]);
        arg_cursor = [arg_cursor cdr];
    }
    ffi_call(cif, FFI_FN(function), result_value, argument_values);
    result = get_nu_value_from_objc_value(result_value, return_type_identifier);

    // free the value structures
    for (i = 0; i < argument_count; i++) {
        free(argument_values[i]);
        free(argument_type_identifiers[i]);
    }
    free(argument_values);
    free(result_value);

    [result retain];
    [pool release];
    [result autorelease];
    return result;
}

@end

@implementation NuBridgedConstant

+ (id) constantWithName:(NSString *) name signature:(NSString *) signature
{
    const char *constant_name = [name cStringUsingEncoding:NSUTF8StringEncoding];
    void *constant = dlsym(RTLD_DEFAULT, constant_name);
    if (!constant) {
        NSLog(@"%s", dlerror());
        NSLog(@"If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.");
        NSLog(@"In Xcode, check the 'Preserve Private External Symbols' checkbox.");
        return nil;
    }
    return get_nu_value_from_objc_value(constant, [signature cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end

static NuSymbol *oneway_symbol, *in_symbol, *out_symbol, *inout_symbol, *bycopy_symbol, *byref_symbol, *const_symbol, *void_symbol, *star_symbol, *id_symbol, *voidstar_symbol, *idstar_symbol, *int_symbol, *BOOL_symbol, *double_symbol, *float_symbol, *NSRect_symbol, *NSPoint_symbol, *NSSize_symbol, *NSRange_symbol, *SEL_symbol, *Class_symbol;

static void prepare_symbols(NuSymbolTable *symbolTable)
{
    oneway_symbol = [symbolTable symbolWithCString:"oneway"];
    in_symbol = [symbolTable symbolWithCString:"in"];
    out_symbol = [symbolTable symbolWithCString:"out"];
    inout_symbol = [symbolTable symbolWithCString:"inout"];
    bycopy_symbol = [symbolTable symbolWithCString:"bycopy"];
    byref_symbol = [symbolTable symbolWithCString:"byref"];
    const_symbol = [symbolTable symbolWithCString:"const"];
    void_symbol = [symbolTable symbolWithCString:"void"];
    star_symbol = [symbolTable symbolWithCString:"*"];
    id_symbol = [symbolTable symbolWithCString:"id"];
    voidstar_symbol = [symbolTable symbolWithCString:"void*"];
    idstar_symbol = [symbolTable symbolWithCString:"id*"];
    int_symbol = [symbolTable symbolWithCString:"int"];
    BOOL_symbol = [symbolTable symbolWithCString:"BOOL"];
    double_symbol = [symbolTable symbolWithCString:"double"];
    float_symbol = [symbolTable symbolWithCString:"float"];
    NSRect_symbol = [symbolTable symbolWithCString:"NSRect"];
    NSPoint_symbol = [symbolTable symbolWithCString:"NSPoint"];
    NSSize_symbol = [symbolTable symbolWithCString:"NSSize"];
    NSRange_symbol = [symbolTable symbolWithCString:"NSRange"];
    SEL_symbol = [symbolTable symbolWithCString:"SEL"];
    Class_symbol = [symbolTable symbolWithCString:"Class"];
}

NSString *signature_for_identifier(NuCell *cell, NuSymbolTable *symbolTable)
{
    static NuSymbolTable *currentSymbolTable = nil;
    if (currentSymbolTable != symbolTable) {
        prepare_symbols(symbolTable);
        currentSymbolTable = symbolTable;
    }
    NSMutableArray *modifiers = nil;
    NSMutableString *signature = [NSMutableString string];
    id cursor = cell;
    BOOL finished = NO;
    while (cursor && cursor != Nu__null) {
        if (finished) {
            // ERROR!
            NSLog(@"I can't bridge this return type yet: %@ (%@)", [cell stringValue], signature);
            return @"?";
        }
        id cursor_car = [cursor car];
        if (cursor_car == oneway_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"V"];
        }
        else if (cursor_car == in_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"n"];
        }
        else if (cursor_car == out_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"o"];
        }
        else if (cursor_car == inout_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"N"];
        }
        else if (cursor_car == bycopy_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"O"];
        }
        else if (cursor_car == byref_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"R"];
        }
        else if (cursor_car == const_symbol) {
            if (!modifiers) modifiers = [NSMutableArray array];
            [modifiers addObject:@"r"];
        }
        else if (cursor_car == void_symbol) {
            if (![cursor cdr] || ([cursor cdr] == [NSNull null])) {
                if (modifiers)
                    [signature appendString:[[modifiers sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@""]];
                [signature appendString:@"v"];
                finished = YES;
            }
            else if ([[cursor cdr] car] == star_symbol) {
                [signature appendString:@"^v"];
                cursor = [cursor cdr];
                finished = YES;
            }
        }
        else if (cursor_car == id_symbol) {
            if (![cursor cdr] || ([cursor cdr] == [NSNull null])) {
                if (modifiers)
                    [signature appendString:[[modifiers sortedArrayUsingSelector:@selector(compare:)] componentsJoinedByString:@""]];
                [signature appendString:@"@"];
                finished = YES;
            }
            else if ([[cursor cdr] car] == star_symbol) {
                [signature appendString:@"^@"];
                cursor = [cursor cdr];
                finished = YES;
            }
        }
        else if ([cursor car] == voidstar_symbol) {
            [signature appendString:@"^v"];
            finished = YES;
        }
        else if ([cursor car] == idstar_symbol) {
            [signature appendString:@"^@"];
            finished = YES;
        }
        else if ([cursor car] == int_symbol) {
            [signature appendString:@"i"];
            finished = YES;
        }
        else if ([cursor car] == BOOL_symbol) {
            [signature appendString:@"C"];
            finished = YES;
        }
        else if ([cursor car] == double_symbol) {
            [signature appendString:@"d"];
            finished = YES;
        }
        else if ([cursor car] == float_symbol) {
            [signature appendString:@"f"];
            finished = YES;
        }
        else if ([cursor car] == NSRect_symbol) {
            [signature appendString:@NSRECT_SIGNATURE0];
            finished = YES;
        }
        else if ([cursor car] == NSPoint_symbol) {
            [signature appendString:@NSPOINT_SIGNATURE0];
            finished = YES;
        }
        else if ([cursor car] == NSSize_symbol) {
            [signature appendString:@NSSIZE_SIGNATURE0];
            finished = YES;
        }
        else if ([cursor car] == NSRange_symbol) {
            [signature appendString:@NSRANGE_SIGNATURE];
            finished = YES;
        }
        else if ([cursor car] == SEL_symbol) {
            [signature appendString:@":"];
            finished = YES;
        }
        else if ([cursor car] == Class_symbol) {
            [signature appendString:@"#"];
            finished = YES;
        }
        cursor = [cursor cdr];
    }
    if (finished)
        return signature;
    else {
        NSLog(@"I can't bridge this return type yet: %@ (%@)", [cell stringValue], signature);
        return @"?";
    }
}

id help_add_method_to_class(Class classToExtend, id cdr, NSMutableDictionary *context, BOOL addClassMethod)
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];

    id returnType = [NSNull null];
    id selector = [[NuCell alloc] init];
    id argumentTypes = [NSNull null];
    id argumentNames = [NSNull null];
    id isSymbol = [symbolTable symbolWithCString:"is"];
    id cursor = cdr;
    id selector_cursor = nil;
    id argumentTypes_cursor = nil;
    id argumentNames_cursor = nil;

    if (cursor && (cursor != [NSNull null]) && ([cursor car] != isSymbol)) {
        // scan the return type
        if (![[cursor car] atom]) {
            returnType = [cursor car] ;
            cursor = [cursor cdr];
        }
        else {
            // The return type specifier must be a list (in parens).  If it is missing, leave it as null.
            returnType = Nu__null;
        }
        if (cursor && (cursor != [NSNull null])) {
            [selector setCar:[cursor car]];       // scan a part of the selector
            cursor = [cursor cdr];
            if (cursor && (cursor != [NSNull null])) {
                if ([cursor car] != isSymbol) {
                    argumentTypes = [[[NuCell alloc] init] autorelease];
                    argumentNames = [[[NuCell alloc] init] autorelease];
                    if (![[cursor car] atom]) {
                        // the argument type specifier must be a list. If it is missing, we'll use a default.
                        [argumentTypes setCar:[cursor car]];
                        cursor = [cursor cdr];
                    }
                    if (cursor && (cursor != [NSNull null])) {
                        [argumentNames setCar:[cursor car]];
                        cursor = [cursor cdr];
                        if (cursor && (cursor != [NSNull null])) {
                            selector_cursor = selector;
                            argumentTypes_cursor = argumentTypes;
                            argumentNames_cursor = argumentNames;
                        }
                    }
                }
            }
        }
    }
    // scan each remaining part of the selector
    while (cursor && (cursor != [NSNull null]) && ([cursor car] != isSymbol)) {
        [selector_cursor setCdr:[[[NuCell alloc] init] autorelease]];
        [argumentTypes_cursor setCdr:[[[NuCell alloc] init] autorelease]];
        [argumentNames_cursor setCdr:[[[NuCell alloc] init] autorelease]];
        selector_cursor = [selector_cursor cdr];
        argumentTypes_cursor = [argumentTypes_cursor cdr];
        argumentNames_cursor = [argumentNames_cursor cdr];

        [selector_cursor setCar:[cursor car]];
        cursor = [cursor cdr];
        if (cursor && (cursor != [NSNull null])) {
            if (![[cursor car] atom]) {
                // the argument type specifier must be a list.  If it is missing, we'll use a default.
                [argumentTypes_cursor setCar:[cursor car]];
                cursor = [cursor cdr];
            }
            if (cursor && (cursor != [NSNull null])) {
                [argumentNames_cursor setCar:[cursor car]];
                cursor = [cursor cdr];
            }
        }
    }

    if (cursor && (cursor != [NSNull null])) {
        //NSLog(@"selector: %@", [selector stringValue]);
        //NSLog(@"argument names: %@", [argumentNames stringValue]);
        //NSLog(@"argument types:%@", [argumentTypes stringValue]);
        //NSLog(@"returns: %@", [returnType stringValue]);

        // skip the is
        cursor = [cursor cdr];

        // combine the selectors into the method name
        NSMutableString *methodName = [[[NSMutableString alloc] init] autorelease];
        selector_cursor = selector;
        while (selector_cursor && (selector_cursor != [NSNull null])) {
            [methodName appendString:[[selector_cursor car] stringValue]];
            selector_cursor = [selector_cursor cdr];
        }

        NSMutableString *signature = nil;

        if ((returnType == Nu__null) || ([argumentTypes length] < [argumentNames length])) {
            // look up the signature
            #ifdef DARWIN
            SEL selector = sel_registerName([methodName cStringUsingEncoding:NSUTF8StringEncoding]);
            #else
            SEL selector = sel_register_name([methodName cStringUsingEncoding:NSUTF8StringEncoding]);
            #endif
            NSMethodSignature *methodSignature = [classToExtend instanceMethodSignatureForSelector:selector];

            if (!methodSignature)
                methodSignature = [classToExtend methodSignatureForSelector:selector];
            if (methodSignature)
                signature = [NSMutableString stringWithString:[methodSignature typeString]];
            // if we can't find a signature, use a default
            if (!signature) {
                // NSLog(@"no signature found.  treating all arguments and the return type as (id)");
                signature = [NSMutableString stringWithString:@"@@:"];
                int i;
                for (i = 0; i < [argumentNames length]; i++) {
                    [signature appendString:@"@"];
                }
            }
        }
        else {
            // build the signature, first get the return type
            signature = [[NSMutableString alloc] init];
            [signature appendString:signature_for_identifier(returnType, symbolTable)];

            // then add the common stuff
            [signature appendString:@"@:"];

            // then describe the arguments
            argumentTypes_cursor = argumentTypes;
            while (argumentTypes_cursor && (argumentTypes_cursor != [NSNull null])) {
                id typeIdentifier = [argumentTypes_cursor car];
                [signature appendString:signature_for_identifier(typeIdentifier, symbolTable)];
                argumentTypes_cursor = [argumentTypes_cursor cdr];
            }
        }
        id body = cursor;
        NuBlock *block = [[[NuBlock alloc] initWithParameters:argumentNames body:body context:context] autorelease];
        [[block context]
            setPossiblyNullObject:methodName
            forKey:[symbolTable symbolWithCString:"_method"]];
        #ifdef DARWIN
        return add_method_to_class(
            addClassMethod ? classToExtend->isa : classToExtend,
            methodName, signature, block);
        #else
        return add_method_to_class(
            addClassMethod ? classToExtend->class_pointer : classToExtend,
            methodName, signature, block);
        #endif
    }
    else {
        // not good. you probably forgot the "is" in your method declaration.
        [NSException raise:@"NuBadMethodDeclaration"
            format:@"invalid method declaration: %@",
            [cdr stringValue]];
        return nil;
    }
}
