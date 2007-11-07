// enumerable.m
//  The NuEnumerable mixin.  This class implements methods that enumerate over collections of objects.
//  The receiving class must have an objectEnumerator method that returns an NSEnumerator.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "enumerable.h"

@interface NuEnumerable(Unimplemented)
- (id) objectEnumerator;
@end

@implementation NuEnumerable

- (id) each:(NuBlock *) block
{
    id args = [[NuCell alloc] init];
    if ([block isKindOfClass:[NuBlock class]]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            [block evalWithArguments:args context:Nu__null];
        }
    }
    [args release];
    return self;
}

- (id) eachWithIndex:(NuBlock *) block
{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    if ([block isKindOfClass:[NuBlock class]]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        int i = 0;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            [[args cdr] setCar:[NSNumber numberWithInt:i]];
            [block evalWithArguments:args context:Nu__null];
            i++;
        }
    }
    [args release];
    return self;
}

- (id) select:(NuBlock *) block
{
    NSMutableArray *selected = [[NSMutableArray alloc] init];
    id args = [[NuCell alloc] init];
    if ([block isKindOfClass:[NuBlock class]]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            id result = [block evalWithArguments:args context:Nu__null];
            if (result && (result != Nu__null)) {
                [selected addObject:object];
            }
        }
    }
    [args release];
    return selected;
}

- (id) find:(NuBlock *) block
{
    id args = [[NuCell alloc] init];
    if ([block isKindOfClass:[NuBlock class]]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            id result = [block evalWithArguments:args context:Nu__null];
            if (result && (result != Nu__null)) {
                return object;
            }
        }
    }
    [args release];
    return Nu__null;
}

- (id) map:(NuBlock *) block
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    id args = [[NuCell alloc] init];
    if ([block isKindOfClass:[NuBlock class]]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            [results addObject:[block evalWithArguments:args context:Nu__null]];
        }
    }
    [args release];
    return results;
}

- (id) reduce:(NuBlock *) block from:(id) initial
{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    id result = initial;
    if ([block isKindOfClass:[NuBlock class]]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:result];
            [[args cdr] setCar: object];
            result = [block evalWithArguments:args context:Nu__null];
        }
    }
    [args release];
    return result;
}

- (id) maximum:(NuBlock *) block
{
    id bestObject = nil;

    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];

    if ([block isKindOfClass:[NuBlock class]]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            if (!bestObject) {
                bestObject = object;
            }
            else {
                [args setCar:object];
                [[args cdr] setCar:bestObject];
                id result = [block evalWithArguments:args context:Nu__null];
                if (result && (result != Nu__null)) {
                    if ([result intValue] > 0) {
                        bestObject = object;
                    }
                }
            }
        }
    }
    [args release];
    return bestObject;
}

@end

@implementation NSArray (Enumeration)

- (id) reduceLeft:(NuBlock *) block from:(id) initial
{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    id result = initial;
    if ([block isKindOfClass:[NuBlock class]]) {
        int i;
        for (i = [self count] - 1; i >= 0; i--) {
            id object = [self objectAtIndex:i];
            [args setCar:result];
            [[args cdr] setCar: object];
            result = [block evalWithArguments:args context:Nu__null];
        }
    }
    [args release];
    return result;
}

- (id) eachInReverse:(NuBlock *) block
{
    id args = [[NuCell alloc] init];
    if ([block isKindOfClass:[NuBlock class]]) {
        NSEnumerator *enumerator = [self reverseObjectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            [block evalWithArguments:args context:Nu__null];
        }
    }
    [args release];
    return self;
}


static int sortedArrayUsingBlockHelper(id a, id b, void *context)
{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    [args setCar:a];
    [[args cdr] setCar:b];

    // cast context as a block
    NuBlock *block = (NuBlock *)context;
    id result = [block evalWithArguments:args context:nil];

    [args release];
    return [result intValue];
}

- (id) sortedArrayUsingBlock:(NuBlock *) block
{
    return [self sortedArrayUsingFunction:sortedArrayUsingBlockHelper context:block];
}

@end
