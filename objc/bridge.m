// bridge.m
//  The Nu bridge to Objective-C.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import <Cocoa/Cocoa.h>
#import "objc_runtime.h"
#import "class.h"
#import "block.h"
#import "symbol.h"
#import "operator.h"
#import "bridge.h"
#import "extensions.h"
#import "st.h"
#import "reference.h"

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

// This would be helpful
// :NSRect => [:origin , :size]
// :NSPoint => [:x, :y]
//
#define NSRECT_SIGNATURE0 "{_NSRect={_NSPoint=ff}{_NSSize=ff}}"
#define NSRECT_SIGNATURE1 "{_NSRect=\"origin\"{_NSPoint=\"x\"f\"y\"f}\"size\"{_NSSize=\"width\"f\"height\"f}}"
#define NSRECT_SIGNATURE2 "{_NSRect}"

#define CGRECT_SIGNATURE "{CGRect={CGPoint=ff}{CGSize=ff}}"
#define NSRANGE_SIGNATURE "{_NSRange=II}"

#define NSPOINT_SIGNATURE0 "{_NSPoint=ff}"
#define NSPOINT_SIGNATURE1 "{_NSPoint=\"x\"f\"y\"f}"

#define NSSIZE_SIGNATURE "{_NSSize=ff}"

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
    ffi_type_nspoint.elements[0] = &ffi_type_float;
    ffi_type_nspoint.elements[1] = &ffi_type_float;
    ffi_type_nspoint.elements[2] = NULL;

    ffi_type_nssize.size = 0;                     // to be computed automatically
    ffi_type_nssize.alignment = 0;
    ffi_type_nssize.type = FFI_TYPE_STRUCT;
    ffi_type_nssize.elements = malloc(3 * sizeof(ffi_type*));
    ffi_type_nssize.elements[0] = &ffi_type_float;
    ffi_type_nssize.elements[1] = &ffi_type_float;
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
    ffi_type_nsrange.elements[0] = &ffi_type_uint;
    ffi_type_nsrange.elements[1] = &ffi_type_uint;
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
        case 'B': return &ffi_type_uint32;
        case 'C': return &ffi_type_uint32;
        case 'c': return &ffi_type_sint32;
        case 'S': return &ffi_type_uint32;
        case 's': return &ffi_type_sint32;
        case 'I': return &ffi_type_uint32;
        case 'i': return &ffi_type_sint32;
        case 'L': return &ffi_type_uint32;
        case 'l': return &ffi_type_sint32;
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
            !strcmp(typeString, CGRECT_SIGNATURE)) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nsrect;
            }
            else if (!strcmp(typeString, NSRANGE_SIGNATURE)) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nsrange;
            }
            else if (!strcmp(typeString, NSPOINT_SIGNATURE0) ||
            !strcmp(typeString, NSPOINT_SIGNATURE1)) {
                if (!initialized_ffi_types) initialize_ffi_types();
                return &ffi_type_nspoint;
            }
            else if (!strcmp(typeString, NSSIZE_SIGNATURE)) {
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
            !strcmp(typeString, CGRECT_SIGNATURE)) {
                return sizeof(NSRect);
            }
            else if (!strcmp(typeString, NSRANGE_SIGNATURE)) {
                return sizeof(NSRange);
            }
            else if (!strcmp(typeString, NSPOINT_SIGNATURE0) ||
            !strcmp(typeString, NSPOINT_SIGNATURE1)) {
                return sizeof(NSPoint);
            }
            else if (!strcmp(typeString, NSSIZE_SIGNATURE)) {
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
            !strcmp(typeString, CGRECT_SIGNATURE)) {
                return malloc(sizeof(NSRect));
            }
            else if (!strcmp(typeString, NSRANGE_SIGNATURE)) {
                return malloc(sizeof(NSRange));
            }
            else if (!strcmp(typeString, NSPOINT_SIGNATURE0) ||
            !strcmp(typeString, NSPOINT_SIGNATURE1)) {
                return malloc(sizeof(NSPoint));
            }
            else if (!strcmp(typeString, NSSIZE_SIGNATURE)) {
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
            if (nu_value == Nu__zero) {
                *((unsigned int *) objc_value) = 0;
                return NO;
            }
            *((id *) objc_value) = nu_value;
            return NO;
        }
        case 'I':
        case 'S':
        case 'C':
        {
            if (nu_value == Nu__null) {
                *((unsigned int *) objc_value) = 0;
                return NO;
            }
            *((unsigned int *) objc_value) = [nu_value intValue];
            return NO;
        }
        case 'i':
        case 's':
        case 'c':
        {
            if (nu_value == [NSNull null]) {
                *((int *) objc_value) = 0;
                return NO;
            }
            *((int *) objc_value) = [nu_value intValue];
            return NO;
        }
        case 'L':
        {
            if (nu_value == [NSNull null]) {
                *((unsigned long *) objc_value) = 0;
                return NO;
            }
            *((unsigned long *) objc_value) = [nu_value longValue];
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
            *((unsigned long long *) objc_value) = [nu_value longLongValue];
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
            if (!strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
            !strcmp(typeString, CGRECT_SIGNATURE)) {
                NSRect *rect = (NSRect *) objc_value;
                id cursor = nu_value;
                rect->origin.x = (float) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->origin.y = (float) [[cursor car] doubleValue];            cursor = [cursor cdr];
                rect->size.width = (float) [[cursor car] doubleValue];          cursor = [cursor cdr];
                rect->size.height = (float) [[cursor car] doubleValue];
                //NSLog(@"nu->rect: %x %f %f %f %f", (void *) rect, rect->origin.x, rect->origin.y, rect->size.width, rect->size.height);
                return NO;
            }
            else if (!strcmp(typeString, NSRANGE_SIGNATURE)) {
                NSRange *range = (NSRange *) objc_value;
                id cursor = nu_value;
                range->location = [[cursor car] intValue];          cursor = [cursor cdr];;
                range->length = [[cursor car] intValue];
                return NO;
            }
            else if (!strcmp(typeString, NSSIZE_SIGNATURE)) {
                NSSize *size = (NSSize *) objc_value;
                id cursor = nu_value;
                size->width = [[cursor car] doubleValue];           cursor = [cursor cdr];;
                size->height =  [[cursor car] doubleValue];
                return NO;
            }
            else if (!strcmp(typeString, NSPOINT_SIGNATURE0) ||
            !strcmp(typeString, NSPOINT_SIGNATURE1)) {
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
            if (!nu_value || (nu_value == [NSNull null]) || (nu_value == Nu__zero)) {
                *((char ***) objc_value) = NULL;
                return NO;
            }
            // pointers require some work.. and cleanup. This LEAKS.
            if (!strcmp(typeString, "^*")) {
                // array of strings, which requires an NSArray or NSNull (handled above)
                if ([nu_value isKindOfClass:[NSArray class]]) {
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
                    NSLog(@"can't convert value of type %s to a pointer to strings", [nu_value class]->name);
                    *((char ***) objc_value) = NULL;
                    return NO;
                }
            }
            else if (!strcmp(typeString, "^@")) {
                if ([nu_value isKindOfClass:[NuReference class]]) {
                    *((id **) objc_value) = [nu_value pointerToReferencedObject];
                    return YES;
                }
            }
            else {
                // we could probably handle NSString and NSData objects
                NSLog(@"can't convert value of type %s to a pointer of type %s", [nu_value class]->name, typeString);
                return NO;
            }
        }

        case '*':
        {
            *((char **) objc_value) = strdup([[nu_value stringValue] cStringUsingEncoding:NSUTF8StringEncoding]);
            return NO;
        }

        case '#':
        {
            if ([nu_value isKindOfClass:[NuClass class]]) {
                *((Class *)objc_value) = [nu_value wrappedClass];
                return NO;
            }
            else {
                NSLog(@"can't convert value of type %s to CLASS", [nu_value class]->name);
                *((id *) objc_value) = 0;
                return NO;
            }
        }

        #if false
        case 'b':                                 // send bool as int
            switch (TYPE(ruby_value)) {
                case T_FIXNUM:
                case T_BIGNUM:
                case T_FLOAT:
                    *((int *) objc_value) = (int) NUM2INT(ruby_value);
                    return NO;
                case T_TRUE:
                    *((int *) objc_value) = (int) 0x01;
                    return NO;
                case T_FALSE:
                    *((int *) objc_value) = (int) 0x00;
                    return NO;
                default:
                    NSLog(@"can't convert ruby type %x to %c", TYPE(ruby_value), typeChar);
                    *((int *) objc_value) = -1;
                    return NO;
            }
        case 'B':                                 // send bool as int
            switch (TYPE(ruby_value)) {
                case T_FIXNUM:
                case T_BIGNUM:
                case T_FLOAT:
                    *((unsigned int *) objc_value) = (unsigned int) NUM2UINT(ruby_value);
                    return NO;
                case T_TRUE:
                    *((unsigned int *) objc_value) = (unsigned int) 0x01;
                    return NO;
                case T_FALSE:
                    *((unsigned int *) objc_value) = (unsigned int) 0x00;
                    return NO;
                default:
                    NSLog(@"can't convert ruby type %x to %c", TYPE(ruby_value), typeChar);
                    *((int *) objc_value) = -1;
                    return NO;
            }
        #endif
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
            return result ? result : [NSNull null];
        }
        case '#':
        {
            Class c = *((Class *)objc_value);
            return c ? [[NuClass alloc] initWithClass:c] : Nu__null;
        }
        case 'c': case 's': case 'i':
        {
            return [NSNumber numberWithInt:*((int *)objc_value)];
        }
        case 'C': case 'S': case 'I':
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
            if (!strcmp(typeString, NSRECT_SIGNATURE0) ||
                !strcmp(typeString, NSRECT_SIGNATURE1) ||
                !strcmp(typeString, NSRECT_SIGNATURE2) ||
            !strcmp(typeString, CGRECT_SIGNATURE)) {
                NSRect *rect = (NSRect *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithFloat:rect->origin.x]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithFloat:rect->origin.y]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithFloat:rect->size.width]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithFloat:rect->size.height]];
                //NSLog(@"converting rect at %x to list: %@", (void *) rect, [list stringValue]);
                return list;
            }
            else if (!strcmp(typeString, NSRANGE_SIGNATURE)) {
                NSRange *range = (NSRange *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithInt:range->location]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithInt:range->length]];
                return list;
            }
            else if (!strcmp(typeString, NSPOINT_SIGNATURE0) ||
            !strcmp(typeString, NSPOINT_SIGNATURE1)) {
                NSPoint *point = (NSPoint *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithFloat:point->x]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithFloat:point->y]];
                return list;
            }
            else if (!strcmp(typeString, NSSIZE_SIGNATURE)) {
                NSSize *size = (NSSize *)objc_value;
                NuCell *list = [[[NuCell alloc] init] autorelease];
                id cursor = list;
                [cursor setCar:[NSNumber numberWithFloat:size->width]];
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                [cursor setCar:[NSNumber numberWithFloat:size->height]];
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
            // pointers require some work.. and cleanup. This LEAKS.
            if (!strcmp(typeString, "^v")) {
                if (*((unsigned int *)objc_value) != 0)
                    NSLog(@"WARNING: unable to wrap nonzero void * pointer");
                return [NSNull null];
            }
            else {
                NSLog(@"UNIMPLEMENTED: can't wrap pointer of type %s", typeString);
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
            sel_getName(s),
            given,
            count];
    }
}

#define BUFSIZE 500

#define MAXPLACEHOLDERS 100
static int placeholderCount = 0;
static Class placeholderClass[MAXPLACEHOLDERS];

@implementation NuClass (Placeholders)

+ (void) initialize
{
    // I don't like this. How can I automatically recognize placeholders? Or convince Apple to make placeholders ignore releases?
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
}

@end

id nu_calling_objc_method_handler(id target, Method m, NSMutableArray *args)
{
    //NSLog(@"calling ObjC method %s with target of class %@", sel_getName(method_getName(m)), [target class]);

    IMP imp = method_getImplementation(m);

    // if the imp has an associated block, this is a nu-to-nu call.
    // skip going through the ObjC runtime and evaluate the block directly.
    NuBlock *block = nil;
    if (nu_block_table && st_lookup(nu_block_table, (unsigned long)imp, (unsigned long *)&block)) {
        //NSLog(@"nu calling nu method %s of class %@", sel_getName(method_getName(m)), [target class]);
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
        // ensure that methods declared to return void always return void.
        char return_type_buffer[BUFSIZE];
        method_getReturnType(m, return_type_buffer, BUFSIZE);
        return (!strcmp(return_type_buffer, "v")) ? [NSNull null] : result;
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
            //NSLog(@"calling..");
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
                    // NSLog(@"autoreleasing object of class %@", resultClass);
                    if (((s == @selector(alloc)) || (s == @selector(allocWithZone:))) && [result isKindOfClass:[NSView class]]) {
                        //NSLog(@"fake initialization of NSView object");
                        // Sleazy trick. To avoid bogus warnings about views being incorrectly initialized,
                        // call NSView init on freshly allocated NSViews.
                        // Suggestion to Apple: remove those warnings.
                        //IMP initIMP = [NSView instanceMethodForSelector:@selector(init)];
                        //initIMP(result, @selector(init));
                    }
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

@interface NSMethodSignature (UndocumentedInterface)
+ (id) signatureWithObjCTypes:(const char*)types;
@end

static void obj_calling_nu_method_handler(ffi_cif* cif, void* returnvalue, void** args, void* userdata)
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
    set_objc_value_from_nu_value(returnvalue, result, ((char **)userdata)[0]);
    [arguments release];

    [pool release];
}

IMP construct_method_handler(SEL sel, NuBlock *block, const char *signature)
{
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
    const char *return_type_string = [methodSignature methodReturnType];
    ffi_type *result_type = ffi_type_for_objc_type(return_type_string);
    int argument_count = [methodSignature numberOfArguments];
    char **userdata = (char **) malloc ((argument_count+2) * sizeof(char*));
    ffi_type **argument_types = (ffi_type **) malloc (argument_count * sizeof(ffi_type *));
    userdata[0] = strdup(return_type_string);
    userdata[1] = (char *) block;
    [block retain];
    int i;
    for (i = 0; i < argument_count; i++) {
        const char *argument_type_string = [methodSignature getArgumentTypeAtIndex:i];
        if (i > 1) userdata[i] = strdup(argument_type_string);
        argument_types[i] = ffi_type_for_objc_type(argument_type_string);
    }
    ffi_cif *cif = (ffi_cif *)malloc(sizeof(ffi_cif));
    if (cif == NULL) {
        NSLog(@"failed to allocate cif structure");
        return NULL;
    }
    int status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argument_count, result_type, argument_types);
    if (status != FFI_OK) {
        NSLog (@"failed to prepare cif structure");
        return NULL;
    }
    ffi_closure *closure = (ffi_closure *)malloc(sizeof(ffi_closure));
    if (closure == NULL) {
        return NULL;
    }
    if (ffi_prep_closure(closure, cif, obj_calling_nu_method_handler, userdata) != FFI_OK) {
        return NULL;
    }
    return (IMP) closure;
}

id add_method_to_class(Class c, NSString *methodName, NSString *signature, NuBlock *block)
{
    const char *method_name_str = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
    const char *signature_str = [signature cStringUsingEncoding:NSUTF8StringEncoding];
    SEL selector = sel_registerName(method_name_str);

    NuSymbolTable *symbolTable = [[block context] objectForKey:SYMBOLS_KEY];
    [[block context] setObject:[[NuClass alloc] initWithClass:c] forKey:[symbolTable symbolWithCString:"_class"]];

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
    IMP oldMethod = class_replaceMethod(c, selector, imp, signature_str);
    if (oldMethod) {
        // NSLog(@"replacing handler for %s(%s) in class %s", method_name_str, signature_str, c->name);
        return [NSNull null];
    }

    return [NSNull null];
}

#include <dlfcn.h>

@implementation NuBridgedFunction

- (NuBridgedFunction *) initWithName:(NSString *)n signature:(NSString *)s
{
    name = strdup([n cStringUsingEncoding:NSUTF8StringEncoding]);
    signature = strdup([s cStringUsingEncoding:NSUTF8StringEncoding]);
    function = dlsym(RTLD_DEFAULT, name);
    if (!function) {
        NSLog(@"%s", dlerror());
        NSLog(@"If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.");
        NSLog(@"In Xcode, check the 'Preserve Private External Symbols' checkbox.");
    }
    return self;
}

+ (NuBridgedFunction *) functionWithName:(NSString *)name signature:(NSString *)signature
{
    const char *function_name = [name cStringUsingEncoding:NSUTF8StringEncoding];
    void *function = dlsym(RTLD_DEFAULT, function_name);
    if (!function) {
        NSLog(@"%s", dlerror());
        NSLog(@"If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.");
        NSLog(@"In Xcode, check the 'Preserve Private External Symbols' checkbox.");
        return nil;
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
    mark_end_of_type_string(return_type_identifier, strlen(return_type_identifier));

    int argument_count = 0;
    char *argument_type_identifiers[100];
    char *cursor = &signature[strlen(return_type_identifier)];
    while (*cursor != 0) {
        argument_type_identifiers[argument_count] = strdup(cursor);
        mark_end_of_type_string(argument_type_identifiers[argument_count], strlen(cursor));
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

NSString *signature_for_identifier(NuCell *cell, NuSymbolTable *symbolTable)
{
    //NSLog(@"getting signature for type identifier %@", [cell stringValue]);
    if ([cell cdr] == [NSNull null]) {
        if ([cell car] == [symbolTable symbolWithCString:"void"])
            return @"v";
        else if ([cell car] == [symbolTable symbolWithCString:"id"])
            return @"@";
        else if ([cell car] == [symbolTable symbolWithCString:"int"])
            return @"i";
        else if ([cell car] == [symbolTable symbolWithCString:"BOOL"])
            return @"i";
        else if ([cell car] == [symbolTable symbolWithCString:"double"])
            return @"d";
        else if ([cell car] == [symbolTable symbolWithCString:"float"])
            return @"f";
        else if ([cell car] == [symbolTable symbolWithCString:"NSRect"])
            return @NSRECT_SIGNATURE0;
        else if ([cell car] == [symbolTable symbolWithCString:"NSPoint"])
            return @NSPOINT_SIGNATURE0;
        else if ([cell car] == [symbolTable symbolWithCString:"NSSize"])
            return @NSSIZE_SIGNATURE;
        else if ([cell car] == [symbolTable symbolWithCString:"NSRange"])
            return @NSRANGE_SIGNATURE;
        else if ([cell car] == [symbolTable symbolWithCString:"SEL"])
            return @":";
        else if ([cell car] == [symbolTable symbolWithCString:"Class"])
            return @"#";

    }
    else if ([[cell cdr] car] == [symbolTable symbolWithCString:"*"]) {
        if ([cell car] == [symbolTable symbolWithCString:"void"])
            return @"^v";
    }

    NSLog(@"I can't bridge this return type yet: %@", [cell stringValue]);
    return @"?";
}

id help_add_method_to_class(Class classToExtend, id cdr, NSMutableDictionary *context)
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
            SEL selector = sel_registerName([methodName cStringUsingEncoding:NSUTF8StringEncoding]);
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
            setObject:methodName
            forKey:[symbolTable symbolWithCString:"_method"]];

        return add_method_to_class(classToExtend, methodName, signature, block);
    }
    else {
        // not good. you probably forgot the "is" in your method declaration.
        [NSException raise:@"NuBadMethodDeclaration"
            format:@"invalid method declaration: %@",
            [cdr stringValue]];
        return nil;
    }
}
