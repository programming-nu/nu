/*!
@file enumerable.m
@description The NuEnumerable mixin.
This class implements methods that enumerate over collections of objects.
The receiving class must have an objectEnumerator method that returns an NSEnumerator.
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

#import "enumerable.h"
#import "objc_runtime.h"
#import "nuinternals.h"

@interface NuEnumerable(Unimplemented)
- (id) objectEnumerator;
@end

@implementation NuEnumerable

- (id) each:(NuBlock *) block
{
    id args = [[NuCell alloc] init];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        NSEnumerator *enumerator = [self objectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            @try
            {
                [args setCar:object];
                [block evalWithArguments:args context:Nu__null];
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
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
                [[args cdr] setCar:[NSNumber numberWithInt:i]];
                [block evalWithArguments:args context:Nu__null];
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
                @throw(exception);
            }
            i++;
        }
    }
    [args release];
    return self;
}

- (NSArray *) select:(NuBlock *) block
{
    NSMutableArray *selected = [[NSMutableArray alloc] init];
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

- (NSArray *) map:(NuBlock *) block
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    id args = [[NuCell alloc] init];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
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

- (NSArray *) mapSelector:(SEL) sel
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSEnumerator *enumerator = [self objectEnumerator];
    id object;
    while ((object = [enumerator nextObject])) {
        // this will fail (crash!) if the selector returns any type other than an object.
        [results addObject:[object performSelector:sel]];
    }
    return results;
}

- (id) reduce:(NuBlock *) block from:(id) initial
{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    id result = initial;
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
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

@implementation NSArray (Enumeration)

- (id) reduceLeft:(NuBlock *) block from:(id) initial
{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    id result = initial;
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
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
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        NSEnumerator *enumerator = [self reverseObjectEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            @try
            {
                [args setCar:object];
                [block evalWithArguments:args context:Nu__null];
            }
            @catch (NuBreakException *exception) {
                break;
            }
            @catch (NuContinueException *exception) {
                // do nothing, just continue with the next loop iteration
            }
            @catch (id exception) {
                @throw(exception);
            }
        }
    }
    [args release];
    return self;
}

static NSComparisonResult sortedArrayUsingBlockHelper(id a, id b, void *context)
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

- (NSArray *) sortedArrayUsingBlock:(NuBlock *) block
{
    return [self sortedArrayUsingFunction:sortedArrayUsingBlockHelper context:block];
}

@end
