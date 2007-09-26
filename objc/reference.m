// reference.m
//  The Nu pointer wrapper.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "reference.h"

@implementation NuReference

- (id) value {return value;}

- (void) setValue:(id) v
{
    [v retain];
    [value release];
    value = v;
}

- (id *) pointerToReferencedObject {return &value;}

- (void) retainReferencedObject
{
    [value retain];
}

@end

@interface PTest :NSObject
{}
@end

@implementation PTest
+ (void) setNumber:(NSNumber **) number
{
    *number = [NSNumber numberWithInt:22];
}

@end
