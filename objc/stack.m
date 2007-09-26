// stack.m
//  A simple stack class used by the Nu parser.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "stack.h"

@implementation NuStack
- (id) init
{
    [super init];
    storage = [[NSMutableArray alloc] init];
    return self;
}

- (void) dealloc
{
    [storage release];
    [super dealloc];
}

- (void) push:(id) object
{
    [storage addObject:object];
}

- (id) pop
{
    if ([storage count] > 0) {
        id object = [[storage lastObject] retain];
        [storage removeLastObject];
		[object autorelease];
        return object;
    }
    else {
        return nil;
    }
}

- (int) depth
{
    return [storage count];
}

- (id) top
{
    return [storage lastObject];
}

- (id) objectAtIndex:(int) i
{
	return [storage objectAtIndex:i];
}

- (void) dump
{
    int i;
    for (i = [storage count]-1; i >= 0; i--) {
        NSLog(@"stack %d: %@", i, [storage objectAtIndex:i]);
    }
}

@end
