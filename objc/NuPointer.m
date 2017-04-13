//
//  NuPointer.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuPointer.h"
#import "NuInternals.h"

#pragma mark - NuPointer.m

@interface NuPointer ()
{
    void *pointer;
    NSString *typeString;
    bool thePointerIsMine;
}
@end

@implementation NuPointer

- (id) init
{
    if ((self = [super init])) {
        pointer = 0;
        typeString = nil;
        thePointerIsMine = NO;
    }
    return self;
}

- (void *) pointer {return pointer;}

- (void) setPointer:(void *) p
{
    pointer = p;
}

- (NSString *) typeString {return typeString;}

- (id) object
{
    return pointer;
}

- (void) setTypeString:(NSString *) s
{
    [s retain];
    [typeString release];
    typeString = s;
}

- (void) allocateSpaceForTypeString:(NSString *) s
{
    if (thePointerIsMine)
        free(pointer);
    [self setTypeString:s];
    const char *type = [s UTF8String];
    while (*type && (*type != '^'))
        type++;
    if (*type)
        type++;
    //NSLog(@"allocating space for type %s", type);
    pointer = value_buffer_for_objc_type(type);
    thePointerIsMine = YES;
}

- (void) dealloc
{
    [typeString release];
    if (thePointerIsMine)
        free(pointer);
    [super dealloc];
}

- (id) value
{
    const char *type = [typeString UTF8String];
    while (*type && (*type != '^'))
        type++;
    if (*type)
        type++;
    //NSLog(@"getting value for type %s", type);
    return get_nu_value_from_objc_value(pointer, type);
}

@end

