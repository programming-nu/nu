//
//  NuBridge.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuBridge.h"
#import "NuInternals.h"

#import <sys/stat.h>
#import <sys/mman.h>

#import <Foundation/Foundation.h>
#import <unistd.h>

#if TARGET_OS_IPHONE
#import <CoreGraphics/CoreGraphics.h>
#define NSRect CGRect
#define NSPoint CGPoint
#define NSSize CGSize
#endif

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#if TARGET_OS_IPHONE
#import "ffi.h"
#else
#ifdef DARWIN
#import <ffi/ffi.h>
#else
#import <x86_64-linux-gnu/ffi.h>
#endif
#endif

#import <dlfcn.h>

#pragma mark - NuBridge.m

#import "NuHandler.h"
#import "NuReference.h"
#import "NuPointer.h"
#import "NuClass.h"
#import "NSMethodSignature+Nu.h"
#import "NSDictionary+Nu.h"

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

NSMutableDictionary *nu_block_table = nil;

#if defined(__x86_64__) || defined(__arm64__)

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

static void initialize_ffi_types(void)
{
    if (initialized_ffi_types) return;
    initialized_ffi_types = true;
    
    // It would be better to do this automatically by parsing the ObjC type signatures
    ffi_type_nspoint.size = 0;                    // to be computed automatically
    ffi_type_nspoint.alignment = 0;
    ffi_type_nspoint.type = FFI_TYPE_STRUCT;
    ffi_type_nspoint.elements = malloc(3 * sizeof(ffi_type*));
#if defined(__x86_64__) || defined(__arm64__)
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
#if defined(__x86_64__) || defined(__arm64__)
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
#if defined(__x86_64__) || defined(__arm64__)
	ffi_type_nsrange.elements[0] = &ffi_type_uint64;
    ffi_type_nsrange.elements[1] = &ffi_type_uint64;
#else
    ffi_type_nsrange.elements[0] = &ffi_type_uint;
    ffi_type_nsrange.elements[1] = &ffi_type_uint;
#endif
    ffi_type_nsrange.elements[2] = NULL;
}

static char get_typeChar_from_typeString(const char *typeString)
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
#if defined(__x86_64__) || defined(__arm64__)
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
                !strcmp(typeString, CGRECT_SIGNATURE2)) {
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
    // NSLog(@"VALUE => %s", typeString);
    char typeChar = get_typeChar_from_typeString(typeString);
    switch (typeChar) {
        case '@':
        {
            if (nu_value == Nu__null) {
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
            if (nu_value == Nu__null) {
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
            if (nu_value == Nu__null) {
                *((unsigned long *) objc_value) = 0;
                return NO;
            }
            *((unsigned long *) objc_value) = [nu_value unsignedLongValue];
            return NO;
        }
        case 'l':
        {
            if (nu_value == Nu__null) {
                *((long *) objc_value) = 0;
                return NO;
            }
            *((long *) objc_value) = [nu_value longValue];
            return NO;
        }
        case 'Q':
        {
            if (nu_value == Nu__null) {
                *((unsigned long long *) objc_value) = 0;
                return NO;
            }
            *((unsigned long long *) objc_value) = [nu_value unsignedLongLongValue];
            return NO;
        }
        case 'q':
        {
            if (nu_value == Nu__null) {
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
		case 'B':
		{
      // if (nu_value == Nu__null) {
      // 	*((BOOL *) objc_value) = (BOOL) 0;
      // } else {
				*((BOOL *) objc_value) = (BOOL) [nu_value boolValue];
      //}
			return NO;
		}
        case 'v':
        {
            return NO;
        }
        case ':':
        {
            // selectors must be strings (symbols could be ok too...)
            if (!nu_value || (nu_value == Nu__null)) {
                *((SEL *) objc_value) = 0;
                return NO;
            }
            const char *selectorName = [nu_value UTF8String];
            if (selectorName) {
                *((SEL *) objc_value) = sel_registerName(selectorName);
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
                rect->origin.x = (CGFloat) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->origin.y = (CGFloat) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->size.width = (CGFloat) [[cursor car] doubleValue];          cursor = [cursor cdr];
                rect->size.height = (CGFloat) [[cursor car] doubleValue];
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
            if (!nu_value || (nu_value == Nu__null)) {
                *((char ***) objc_value) = NULL;
                return NO;
            }
            // pointers require some work.. and cleanup. This LEAKS.
            if (!strcmp(typeString, "^*")) {
                // array of strings, which requires an NSArray or NSNull (handled above)
                if (nu_objectIsKindOfClass(nu_value, [NSArray class])) {
                    NSUInteger array_size = [nu_value count];
                    char **array = (char **) malloc (array_size * sizeof(char *));
                    int i;
                    for (i = 0; i < array_size; i++) {
                        array[i] = strdup([[nu_value objectAtIndex:i] UTF8String]);
                    }
                    *((char ***) objc_value) = array;
                    return NO;
                }
                else {
                    NSLog(@"can't convert value of type %s to a pointer to strings", class_getName([nu_value class]));
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
            *((char **) objc_value) = (char*)[[nu_value stringValue] UTF8String];
            return NO;
        }
            
        case '#':
        {
            if (nu_objectIsKindOfClass(nu_value, [NuClass class])) {
                *((Class *)objc_value) = [nu_value wrappedClass];
                return NO;
            }
            else {
                NSLog(@"can't convert value of type %s to CLASS", class_getName([nu_value class]));
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
            return Nu__null;
        }
        case '@':
        {
            id result = *((id *)objc_value);
            return result ? result : Nu__null;
        }
        case '#':
        {
            Class c = *((Class *)objc_value);
            return c ? [[[NuClass alloc] initWithClass:c] autorelease] : Nu__null;
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
            return @(*((int *)objc_value));
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
            return [[NSString stringWithCString:sel_getName(sel) encoding:NSUTF8StringEncoding] retain];
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
                [cursor setCar:@(range->location)];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:@(range->length)];
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
                return @0;
            else
                return @1;
        }
        case '^':
        {
            if (!strcmp(typeString, "^v")) {
                if (*((unsigned long *)objc_value) == 0)
                    return Nu__null;
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
            // Certain pointer types are essentially just ids.
            // CGImageRef is one. As we find others, we can add them here.
            else if (!strcmp(typeString, "^{CGImage=}")) {
                id result = *((id *)objc_value);
                return result ? result : Nu__null;
            }
            else if (!strcmp(typeString, "^{CGColor=}")) {
                id result = *((id *)objc_value);
                return result ? result : Nu__null;
            }
            else {
                if (*((unsigned long *)objc_value) == 0)
                    return Nu__null;
                else {
                    id nupointer = [[[NuPointer alloc] init] autorelease];
                    [nupointer setPointer:*((void **)objc_value)];
                    [nupointer setTypeString:[NSString stringWithCString:typeString encoding:NSUTF8StringEncoding]];
                    return nupointer;
                }
            }
            return Nu__null;
        }
        default:
            NSLog (@"UNIMPLEMENTED: unable to wrap object of type %s", typeString);
            return Nu__null;
    }
    
}

static void raise_argc_exception(SEL s, NSUInteger count, NSUInteger given)
{
    if (given != count) {
        [NSException raise:@"NuIncorrectNumberOfArguments"
                    format:@"Incorrect number of arguments to selector %s. Received %ld but expected %ld",
         sel_getName(s),
         (unsigned long) given,
         (unsigned long) count];
    }
}

#define BUFSIZE 500

id nu_calling_objc_method_handler(id target, Method m, NSMutableArray *args)
{
    // this call seems to force the class's +initialize method to be called.
    [target class];
    
    // NSLog(@"calling ObjC method %s with target of class %@", sel_getName(method_getName(m)), [target class]);
    
    IMP imp = method_getImplementation(m);
    
    // if the imp has an associated block, this is a nu-to-nu call.
    // skip going through the ObjC runtime and evaluate the block directly.
    NuBlock *block = nil;
    if (nu_block_table &&
        ((block = [nu_block_table objectForKey:[NSNumber numberWithUnsignedLong:(unsigned long)imp]]))) {
        // NSLog(@"nu calling nu method %s of class %@", sel_getName(method_getName(m)), [target class]);
        id arguments = [[NuCell alloc] init];
        id cursor = arguments;
        NSUInteger argc = [args count];
        int i;
        for (i = 0; i < argc; i++) {
            NuCell *nextCell = [[NuCell alloc] init];
            [cursor setCdr:nextCell];
            [nextCell release];
            cursor = [cursor cdr];
            [cursor setCar:[args objectAtIndex:i]];
        }
        id result = [block evalWithArguments:[arguments cdr] context:nil self:target];
        [arguments release];
        // ensure that methods declared to return void always return void.
        char return_type_buffer[BUFSIZE];
        method_getReturnType(m, return_type_buffer, BUFSIZE);
        return (!strcmp(return_type_buffer, "v")) ? Nu__null : result;
    }
    
    id result;
    // if we get here, we're going through the ObjC runtime to make the call.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    SEL s = method_getName(m);
    result = Nu__null;
    
    // dynamically construct the method call
    
    
    int argument_count = method_getNumberOfArguments(m);
    
    if ( [args count] != argument_count-2) {
        
        raise_argc_exception(s, argument_count-2, [args count]);
    }
    else {
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
        int status = ffi_prep_cif(&cif2, FFI_DEFAULT_ABI, (unsigned int) argument_count, result_type, argument_types);
        if (status != FFI_OK) {
            NSLog (@"failed to prepare cif structure");
        }
        else {
            const char *method_name = sel_getName(method_getName(m));
            BOOL callingInitializer = !strncmp("init", method_name, 4);
            if (callingInitializer) {
                [target retain]; // in case an init method releases its target (to return something else), we preemptively retain it
            }
            // call the method handler
            ffi_call(&cif2, FFI_FN(imp), result_value, argument_values);
            // extract the return value
            result = get_nu_value_from_objc_value(result_value, &return_type_buffer[0]);
            // NSLog(@"result is %@", result);
            // NSLog(@"retain count %d", [result retainCount]);
            
            // Return values should not require a release.
            // Either they are owned by an existing object or are autoreleased.
            // Exceptions to this rule are handled below.
            // Since these methods create new objects that aren't autoreleased, we autorelease them.
#ifdef LINUX
            const char *methodName = sel_getName(s);
            bool already_retained = !strcmp(methodName,"alloc") ||
            !strcmp(methodName,"allocWithZone:") ||
            !strcmp(methodName,"copy") ||
            !strcmp(methodName,"copyWithZone:") ||
            !strcmp(methodName,"mutableCopy:") ||
            !strcmp(methodName,"mutableCopyWithZone:") ||
            !strcmp(methodName,"new");
#else
            bool already_retained =               // see Anguish/Buck/Yacktman, p. 104
            (s == @selector(alloc)) || (s == @selector(allocWithZone:))
            || (s == @selector(copy)) || (s == @selector(copyWithZone:))
            || (s == @selector(mutableCopy)) || (s == @selector(mutableCopyWithZone:))
            || (s == @selector(new));
#endif
            // NSLog(@"already retained? %d", already_retained);
            if (already_retained) {
                [result autorelease];
            }
            
            if (callingInitializer) {
                if (result == target) {
                    // NSLog(@"undoing preemptive retain of init target %@", [target className]);
                    [target release]; // undo our preemptive retain
                } else {
                    // NSLog(@"keeping preemptive retain of init target %@", [target className]);
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
    [pool drain];
    [result autorelease];
    return result;
}

@interface NSMethodSignature (UndocumentedInterface)
+ (id) signatureWithObjCTypes:(const char*)types;
@end

static void objc_calling_nu_method_handler(ffi_cif* cif, void* returnvalue, void** args, void* userdata)
{
    int argc = cif->nargs - 2;
    id rcv = *((id*)args[0]);                     // this is the object getting the message
    // unused: SEL sel = *((SEL*)args[1]);
    
    // in rare cases, we need an autorelease pool (specifically detachNewThreadSelector:toTarget:withObject:)
    // previously we used a private api to verify that one existed before creating a new one. Now we just make one.
    NSAutoreleasePool *pool = nil; // [[NSAutoreleasePool alloc] init];
    
    NuBlock *block = ((NuBlock **)userdata)[1];
    //NSLog(@"----------------------------------------");
    //NSLog(@"calling block %@", [block stringValue]);
    id arguments = [[NuCell alloc] init];
    id cursor = arguments;
    int i;
    for (i = 0; i < argc; i++) {
        NuCell *nextCell = [[NuCell alloc] init];
        [cursor setCdr:nextCell];
        [nextCell release];
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
    if (pool) {
        if (resultType[0] == '@')
            [*((id *)returnvalue) retain];
        [pool drain];
        if (resultType[0] == '@')
            [*((id *)returnvalue) autorelease];
    }
}

static char **generate_userdata(SEL sel, NuBlock *block, const char *signature)
{
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
    const char *return_type_string = [methodSignature methodReturnType];
    NSUInteger argument_count = [methodSignature numberOfArguments];
    char **userdata = (char **) malloc ((argument_count+3) * sizeof(char*));
    userdata[0] = (char *) malloc (2 + strlen(return_type_string));
    const char *methodName = sel_getName(sel);
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

static IMP construct_method_handler(SEL sel, NuBlock *block, const char *signature)
{
    char **userdata = generate_userdata(sel, block, signature);
#if !TARGET_OS_IPHONE
	IMP imp = [NuHandlerWarehouse handlerWithSelector:sel block:block signature:signature userdata:userdata];
    if (imp) {
        return imp;
    }
#endif
    int argument_count = 0;
    while (userdata[argument_count] != 0) argument_count++;
#if 0
    const char *methodName = sel_getName(sel);
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
#if TARGET_OS_IPHONE
	void* funcPtr;
	ffi_closure *closure = ffi_closure_alloc(sizeof(ffi_closure), &funcPtr);
#else
	ffi_closure *closure = (ffi_closure *)mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
#endif
	if (closure == (ffi_closure *) -1) {
        NSLog(@"unable to prepare closure for signature %s (mmap failed with error %d)", signature, errno);
        return NULL;
    }
    if (closure == NULL) {
        NSLog(@"unable to prepare closure for signature %s (could not allocate memory for closure)", signature);
        return NULL;
    }
#if TARGET_OS_IPHONE
	if (ffi_prep_closure_loc(closure, cif, objc_calling_nu_method_handler, userdata, funcPtr) != FFI_OK) {
#else
	if (ffi_prep_closure(closure, cif, objc_calling_nu_method_handler, userdata) != FFI_OK) {
#endif
		NSLog(@"unable to prepare closure for signature %s (ffi_prep_closure failed)", signature);
		return NULL;
	}
#if TARGET_OS_IPHONE
	return funcPtr;
#else
	if (mprotect(closure, sizeof(closure), PROT_READ | PROT_EXEC) == -1) {
		NSLog(@"unable to prepare closure for signature %s (mprotect failed with error %d)", signature, errno);
		return NULL;
	}
	return (void*)closure;
#endif
}

id add_method_to_class(Class c, NSString *methodName, NSString *signature, NuBlock *block)
{
    const char *method_name_str = [methodName UTF8String];
    const char *signature_str = [signature UTF8String];
    SEL selector = sel_registerName(method_name_str);
    
    //NuSymbolTable *symbolTable = [[block context] objectForKey:SYMBOLS_KEY];
    //[[block context] setPossiblyNullObject:[[NuClass alloc] initWithClass:c] forKey:[symbolTable symbolWithString:@"_class"]];
    
    IMP imp = construct_method_handler(selector, block, signature_str);
    if (imp == NULL) {
        NSLog(@"failed to construct handler for %s(%s)", method_name_str, signature_str);
        return Nu__null;
    }
    
    // save the block in a hash table keyed by the imp.
    // this will let us introspect methods and optimize nu-to-nu method calls
    if (!nu_block_table) nu_block_table = [[NSMutableDictionary alloc] init];
    // watch for problems caused by these ugly casts...
    [nu_block_table setObject:block forKey:[NSNumber numberWithUnsignedLong:(unsigned long) imp]];
    // insert the method handler in the class method table
    nu_class_replaceMethod(c, selector, imp, signature_str);
    //NSLog(@"setting handler for %s(%s) in class %s", method_name_str, signature_str, class_getName(c));
    return Nu__null;
}



static NuSymbol *oneway_symbol, *in_symbol, *out_symbol, *inout_symbol, *bycopy_symbol, *byref_symbol, *const_symbol,
*void_symbol, *star_symbol, *id_symbol, *voidstar_symbol, *idstar_symbol, *int_symbol, *long_symbol, *NSComparisonResult_symbol,
*BOOL_symbol, *double_symbol, *float_symbol, *NSRect_symbol, *NSPoint_symbol, *NSSize_symbol, *NSRange_symbol,
*CGRect_symbol, *CGPoint_symbol, *CGSize_symbol,
*SEL_symbol, *Class_symbol;


static void prepare_symbols(NuSymbolTable *symbolTable)
{
    oneway_symbol = [symbolTable symbolWithString:@"oneway"];
    in_symbol = [symbolTable symbolWithString:@"in"];
    out_symbol = [symbolTable symbolWithString:@"out"];
    inout_symbol = [symbolTable symbolWithString:@"inout"];
    bycopy_symbol = [symbolTable symbolWithString:@"bycopy"];
    byref_symbol = [symbolTable symbolWithString:@"byref"];
    const_symbol = [symbolTable symbolWithString:@"const"];
    void_symbol = [symbolTable symbolWithString:@"void"];
    star_symbol = [symbolTable symbolWithString:@"*"];
    id_symbol = [symbolTable symbolWithString:@"id"];
    voidstar_symbol = [symbolTable symbolWithString:@"void*"];
    idstar_symbol = [symbolTable symbolWithString:@"id*"];
    int_symbol = [symbolTable symbolWithString:@"int"];
    long_symbol = [symbolTable symbolWithString:@"long"];
    NSComparisonResult_symbol = [symbolTable symbolWithString:@"NSComparisonResult"];
    BOOL_symbol = [symbolTable symbolWithString:@"BOOL"];
    double_symbol = [symbolTable symbolWithString:@"double"];
    float_symbol = [symbolTable symbolWithString:@"float"];
    NSRect_symbol = [symbolTable symbolWithString:@"NSRect"];
    NSPoint_symbol = [symbolTable symbolWithString:@"NSPoint"];
    NSSize_symbol = [symbolTable symbolWithString:@"NSSize"];
    NSRange_symbol = [symbolTable symbolWithString:@"NSRange"];
    CGRect_symbol = [symbolTable symbolWithString:@"CGRect"];
    CGPoint_symbol = [symbolTable symbolWithString:@"CGPoint"];
    CGSize_symbol = [symbolTable symbolWithString:@"CGSize"];
    SEL_symbol = [symbolTable symbolWithString:@"SEL"];
    Class_symbol = [symbolTable symbolWithString:@"Class"];
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
            if (![cursor cdr] || ([cursor cdr] == Nu__null)) {
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
            if (![cursor cdr] || ([cursor cdr] == Nu__null)) {
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
        else if (cursor_car == voidstar_symbol) {
            [signature appendString:@"^v"];
            finished = YES;
        }
        else if (cursor_car == idstar_symbol) {
            [signature appendString:@"^@"];
            finished = YES;
        }
        else if (cursor_car == int_symbol) {
            [signature appendString:@"i"];
            finished = YES;
        }
        else if (cursor_car == long_symbol) {
            [signature appendString:@"l"];
            finished = YES;
        }
        else if (cursor_car == NSComparisonResult_symbol) {
            if (sizeof(NSComparisonResult) == 4)
                [signature appendString:@"i"];
            else
                [signature appendString:@"q"];
            finished = YES;
        }
        else if (cursor_car == BOOL_symbol) {
            [signature appendString:@"C"];
            finished = YES;
        }
        else if (cursor_car == double_symbol) {
            [signature appendString:@"d"];
            finished = YES;
        }
        else if (cursor_car == float_symbol) {
            [signature appendString:@"f"];
            finished = YES;
        }
        else if (cursor_car == NSRect_symbol) {
            [signature appendString:@NSRECT_SIGNATURE0];
            finished = YES;
        }
        else if (cursor_car == NSPoint_symbol) {
            [signature appendString:@NSPOINT_SIGNATURE0];
            finished = YES;
        }
        else if (cursor_car == NSSize_symbol) {
            [signature appendString:@NSSIZE_SIGNATURE0];
            finished = YES;
        }
        else if (cursor_car == NSRange_symbol) {
            [signature appendString:@NSRANGE_SIGNATURE];
            finished = YES;
        }
        else if (cursor_car == CGRect_symbol) {
            [signature appendString:@CGRECT_SIGNATURE0];
            finished = YES;
        }
        else if (cursor_car == CGPoint_symbol) {
            [signature appendString:@CGPOINT_SIGNATURE];
            finished = YES;
        }
        else if (cursor_car == CGSize_symbol) {
            [signature appendString:@CGSIZE_SIGNATURE];
            finished = YES;
        }
        else if (cursor_car == SEL_symbol) {
            [signature appendString:@":"];
            finished = YES;
        }
        else if (cursor_car == Class_symbol) {
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
    
    id returnType = Nu__null;
    id selector = [[[NuCell alloc] init] autorelease];
    id argumentTypes = Nu__null;
    id argumentNames = Nu__null;
    id isSymbol = [symbolTable symbolWithString:@"is"];
    id cursor = cdr;
    id selector_cursor = nil;
    id argumentTypes_cursor = nil;
    id argumentNames_cursor = nil;
    
    if (cursor && (cursor != Nu__null) && ([cursor car] != isSymbol)) {
        // scan the return type
        if (![[cursor car] atom]) {
            returnType = [cursor car] ;
            cursor = [cursor cdr];
        }
        else {
            // The return type specifier must be a list (in parens).  If it is missing, leave it as null.
            returnType = Nu__null;
        }
        if (cursor && (cursor != Nu__null)) {
            [selector setCar:[cursor car]];       // scan a part of the selector
            cursor = [cursor cdr];
            if (cursor && (cursor != Nu__null)) {
                if ([cursor car] != isSymbol) {
                    argumentTypes = [[[NuCell alloc] init] autorelease];
                    argumentNames = [[[NuCell alloc] init] autorelease];
                    if (![[cursor car] atom]) {
                        // the argument type specifier must be a list. If it is missing, we'll use a default.
                        [argumentTypes setCar:[cursor car]];
                        cursor = [cursor cdr];
                    }
                    if (cursor && (cursor != Nu__null)) {
                        [argumentNames setCar:[cursor car]];
                        cursor = [cursor cdr];
                        if (cursor && (cursor != Nu__null)) {
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
    while (cursor && (cursor != Nu__null) && ([cursor car] != isSymbol)) {
        [selector_cursor setCdr:[[[NuCell alloc] init] autorelease]];
        [argumentTypes_cursor setCdr:[[[NuCell alloc] init] autorelease]];
        [argumentNames_cursor setCdr:[[[NuCell alloc] init] autorelease]];
        selector_cursor = [selector_cursor cdr];
        argumentTypes_cursor = [argumentTypes_cursor cdr];
        argumentNames_cursor = [argumentNames_cursor cdr];
        
        [selector_cursor setCar:[cursor car]];
        cursor = [cursor cdr];
        if (cursor && (cursor != Nu__null)) {
            if (![[cursor car] atom]) {
                // the argument type specifier must be a list.  If it is missing, we'll use a default.
                [argumentTypes_cursor setCar:[cursor car]];
                cursor = [cursor cdr];
            }
            if (cursor && (cursor != Nu__null)) {
                [argumentNames_cursor setCar:[cursor car]];
                cursor = [cursor cdr];
            }
        }
    }
    
    if (cursor && (cursor != Nu__null)) {
        //NSLog(@"selector: %@", [selector stringValue]);
        //NSLog(@"argument names: %@", [argumentNames stringValue]);
        //NSLog(@"argument types:%@", [argumentTypes stringValue]);
        //NSLog(@"returns: %@", [returnType stringValue]);
        
        // skip the is
        cursor = [cursor cdr];
        
        // combine the selectors into the method name
        NSMutableString *methodName = [[[NSMutableString alloc] init] autorelease];
        selector_cursor = selector;
        while (selector_cursor && (selector_cursor != Nu__null)) {
            [methodName appendString:[[selector_cursor car] stringValue]];
            selector_cursor = [selector_cursor cdr];
        }
        
        NSMutableString *signature = nil;
        
        if ((returnType == Nu__null) || ([argumentTypes length] < [argumentNames length])) {
            // look up the signature
            SEL selector = sel_registerName([methodName UTF8String]);
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
            signature = [NSMutableString string];
            [signature appendString:signature_for_identifier(returnType, symbolTable)];
            
            // then add the common stuff
            [signature appendString:@"@:"];
            
            // then describe the arguments
            argumentTypes_cursor = argumentTypes;
            while (argumentTypes_cursor && (argumentTypes_cursor != Nu__null)) {
                id typeIdentifier = [argumentTypes_cursor car];
                [signature appendString:signature_for_identifier(typeIdentifier, symbolTable)];
                argumentTypes_cursor = [argumentTypes_cursor cdr];
            }
        }
        id body = cursor;
        NuBlock *block = [[[NuBlock alloc] initWithParameters:argumentNames body:body context:context] autorelease];
        [[block context]
         setPossiblyNullObject:methodName
         forKey:[symbolTable symbolWithString:@"_method"]];
        return add_method_to_class(
                                   addClassMethod ? object_getClass(classToExtend) : classToExtend,
                                   methodName, signature, block);
    }
    else {
        // not good. you probably forgot the "is" in your method declaration.
        [NSException raise:@"NuBadMethodDeclaration"
                    format:@"invalid method declaration: %@",
         [cdr stringValue]];
        return nil;
    }
}
