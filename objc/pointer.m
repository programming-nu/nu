// pointer.m
//  The Nu pointer wrapper.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "pointer.h"

@implementation NuPointer

- (id) init
{
    [super init];
    pointer = 0;
    typeString = nil;
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

- (void) dealloc
{
    [typeString release];
    [super dealloc];
}

@end
