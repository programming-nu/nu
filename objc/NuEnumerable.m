//
//  NuEnumerable.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuEnumerable.h"
#import "NuInternals.h"
#import "NuCell.h"
#import "NuBlock.h"

#pragma mark - NuEnumerable.m

@interface NuEnumerable(Unimplemented)
- (id) objectEnumerator;
@end

@implementation NuEnumerable

- (id) each:(id) callable
{
    id args = [[NuCell alloc] init];
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            @try
            {
                [args setCar:object];
                [callable evalWithArguments:args context:nil];
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
                [args release];
                @throw(exception);
            }
        }
    }
    [args release];
    return self;
}

- (id) eachWithIndex:(NuBlock *) block
{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        int i = 0;
        while ((object = [enumerator nextObject])) {
            @try
            {
                [args setCar:object];
                [[args cdr] setCar:@(i)];
                [block evalWithArguments:args context:nil];
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
                [args release];
                @throw(exception);
            }
            i++;
        }
    }
    [args release];
    return self;
}

- (NSArray *) select
{
    NSMutableArray *selected = [NSMutableArray array];
    NSEnumerator *enumerator = [self objectEnumerator];
    id object;
    while ((object = [enumerator nextObject])) {
        if (nu_valueIsTrue(object)) {
            [selected addObject:object];
        }
    }
    return selected;
}

- (NSArray *) select:(NuBlock *) block
{
    NSMutableArray *selected = [NSMutableArray array];
    id args = [[NuCell alloc] init];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            id result = [block evalWithArguments:args context:Nu__null];
            if (nu_valueIsTrue(result)) {
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
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            id result = [block evalWithArguments:args context:Nu__null];
            if (nu_valueIsTrue(result)) {
                [args release];
                return object;
            }
        }
    }
    [args release];
    return Nu__null;
}

- (NSArray *) map:(id) callable
{
    NSMutableArray *results = [NSMutableArray array];
    id args = [[NuCell alloc] init];
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            [results addObject:[callable evalWithArguments:args context:nil]];
        }
    }
    [args release];
    return results;
}

- (NSArray *) mapWithIndex:(id) callable
{
    NSMutableArray *results = [NSMutableArray array];
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        int i = 0;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            [[args cdr] setCar:@(i)];
            [results addObject:[callable evalWithArguments:args context:nil]];
            i++;
        }
    }
    [args release];
    return results;
}

- (NSArray *) mapSelector:(SEL) sel
{
    NSMutableArray *results = [NSMutableArray array];
    NSEnumerator *enumerator = [self objectEnumerator];
    id object;
    while ((object = [enumerator nextObject])) {
        // this will fail (crash!) if the selector returns any type other than an object.
        [results addObject:[object performSelector:sel]];
    }
    return results;
}

- (id) reduce:(id) callable from:(id) initial
{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    id result = initial;
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:result];
            [[args cdr] setCar: object];
            result = [callable evalWithArguments:args context:nil];
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
    
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
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
