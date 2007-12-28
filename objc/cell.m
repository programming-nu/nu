// cell.m
//  Nu cells.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "cell.h"
#import "symbol.h"
#import "extensions.h"
#import "operator.h"
#import "block.h"

@implementation NuCell

+ (id) cellWithCar:(id)car cdr:(id)cdr
{
    NuCell *cell = [[self alloc] init];
    [cell setCar:car];
    [cell setCdr:cdr];
    return [cell autorelease];
}

- (id) init
{
    [super init];
    car = Nu__null;
    cdr = Nu__null;
    return self;
}

- (void) dealloc
{
    [car release];
    [cdr release];
    [super dealloc];
}

- (bool) atom {return false;}

- (id) car {return car;}

- (id) cdr {return cdr;}

- (void) setCar:(id) c
{
    [c retain];
    [car release];
    car = c;
}

- (void) setCdr:(id) c
{
    [c retain];
    [cdr release];
    cdr = c;
}

- (id) first
{
    return car;
}

- (id) second
{
    return [cdr car];
}

- (id) third
{
    return [[cdr cdr] car];
}

- (id) fourth
{
    return [[[cdr cdr]  cdr] car];
}

- (id) fifth
{
    return [[[[cdr cdr]  cdr]  cdr] car];
}

- (id) nth:(int) n
{
    if (n == 1)
        return car;
    id cursor = cdr;
    int i;
    for (i = 2; i < n; i++) {
        cursor = [cursor cdr];
        if (cursor == Nu__null) return nil;
    }
    return [cursor car];
}

- (id) objectAtIndex:(int) n
{
    if (n < 0)
        return nil;
    else if (n == 0)
        return car;
    id cursor = cdr;
    for (int i = 1; i < n; i++) {
        cursor = [cursor cdr];
        if (cursor == Nu__null) return nil;
    }
    return [cursor car];
}

- (id) lastObject
{
    id cursor = self;
    while ([cursor cdr] != Nu__null) {
        cursor = [cursor cdr];
    }
    return [cursor car];
}

- (NSMutableString *) stringValue
{
    NuCell *cell = self;
    NSMutableString *result = [NSMutableString stringWithString:@"("];
    bool first = true;
    while (IS_NOT_NULL(cell)) {
        if (first)
            first = false;
        else
            [result appendString:@" "];
        id mycar = [cell car];
        if (nu_objectIsKindOfClass(mycar, [NuCell class])) {
            [result appendString:[mycar stringValue]];
        }
        else if (mycar && (mycar != Nu__null)) {
            [result appendString:[mycar description]];
        }
        else {
            [result appendString:@"()"];
        }
        cell = [cell cdr];
        // check for dotted pairs
        if (IS_NOT_NULL(cell) && !nu_objectIsKindOfClass(cell, [NuCell class])) {
            [result appendString:@" . "];
            [result appendString:[cell description]];
            break;
        }
    }
    [result appendString:@")"];
    return result;
}

- (id) evalWithContext:(NSMutableDictionary *)context
{
    id value = [car evalWithContext:context];
    id result = [value evalWithArguments:cdr context:context];
    return result;
}

- (id) each:(NuBlock *) block
{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        id cursor = self;
        while (cursor && (cursor != Nu__null)) {
            [args setCar:[cursor car]];
            [block evalWithArguments:args context:Nu__null];
            cursor = [cursor cdr];
        }
        [args release];
    }
    return self;
}

- (id) eachPair:(NuBlock *) block
{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        [args setCdr:[[[NuCell alloc] init] autorelease]];
        id cursor = self;
        while (cursor && (cursor != Nu__null)) {
            [args setCar:[cursor car]];
            [[args cdr] setCar:[[cursor cdr] car]];
            [block evalWithArguments:args context:Nu__null];
            cursor = [[cursor cdr] cdr];
        }
        [args release];
    }
    return self;
}

- (id) map:(NuBlock *) block
{
    NuCell *result = [[[NuCell alloc] init] autorelease];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        [args setCar:[self car]];
        [result setCar: [block evalWithArguments:args context:Nu__null]];
        [args release];
        if ([self cdr] != Nu__null)
            [result setCdr: [[self cdr] map: block]];
    }
    return result;
}

- (int) length
{
    int count = 0;
    id cursor = self;
    while (cursor && (cursor != Nu__null)) {
        cursor = [cursor cdr];
        count++;
    }
    return count;
}

- (id) comments {return nil;}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:car];
    [coder encodeObject:cdr];
}

- (id) initWithCoder:(NSCoder *)coder
{
    [super init];
    car = [[coder decodeObject] retain];
    cdr = [[coder decodeObject] retain];
    return self;
}

@end

@implementation NuCellWithComments

- (id) comments {return comments;}

- (void) setComments:(id) c
{
    [c retain];
    [comments release];
    comments = c;
}

@end
