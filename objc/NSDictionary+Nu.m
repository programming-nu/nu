//
//  NSDictionary+Nu.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NSDictionary+Nu.h"
#import "NuCell.h"
#import "NuInternals.h"

@implementation NSDictionary(Nu)

+ (NSDictionary *) dictionaryWithList:(id) list
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    id cursor = list;
    while (cursor && (cursor != Nu__null) && ([cursor cdr]) && ([cursor cdr] != Nu__null)) {
        id key = [cursor car];
        if ([key isKindOfClass:[NuSymbol class]] && [key isLabel]) {
            key = [key labelName];
        }
        id value = [[cursor cdr] car];
        if (!value || [value isEqual:Nu__null]) {
            [d removeObjectForKey:key];
        } else {
            [d setValue:value forKey:key];
        }
        cursor = [[cursor cdr] cdr];
    }
    return d;
}

- (id) objectForKey:(id)key withDefault:(id)defaultValue
{
    id value = [self objectForKey:key];
    return value ? value : defaultValue;
}

// When an unknown message is received by a dictionary, treat it as a call to objectForKey:
- (id) handleUnknownMessage:(NuCell *) method withContext:(NSMutableDictionary *) context
{
    id cursor = method;
    while (cursor && (cursor != Nu__null) && ([cursor cdr]) && ([cursor cdr] != Nu__null)) {
        id key = [cursor car];
        id value = [[cursor cdr] car];
        if ([key isKindOfClass:[NuSymbol class]] && [key isLabel]) {
            id evaluated_key = [key labelName];
            id evaluated_value = [value evalWithContext:context];
            [self setValue:evaluated_value forKey:evaluated_key];
        }
        else {
            id evaluated_key = [key evalWithContext:context];
            id evaluated_value = [value evalWithContext:context];
            [self setValue:evaluated_value forKey:evaluated_key];
        }
        cursor = [[cursor cdr] cdr];
    }
    if (cursor && (cursor != Nu__null)) {
        // if the method is a label, use its value as the key.
        if ([[cursor car] isKindOfClass:[NuSymbol class]] && ([[cursor car] isLabel])) {
            id result = [self objectForKey:[[cursor car] labelName]];
            return result ? result : Nu__null;
        }
        else {
            id result = [self objectForKey:[[cursor car] evalWithContext:context]];
            return result ? result : Nu__null;
        }
    }
    else {
        return Nu__null;
    }
}

// Iterate over the key-object pairs in a dictionary. Pass it a block with two arguments: (key object).
- (id) each:(id) block
{
    id args = [[NuCell alloc] init];
    [args setCdr:[[[NuCell alloc] init] autorelease]];
    NSEnumerator *keyEnumerator = [[self allKeys] objectEnumerator];
    id key;
    while ((key = [keyEnumerator nextObject])) {
        @try
        {
            [args setCar:key];
            [[args cdr] setCar:[self objectForKey:key]];
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
    [args release];
    return self;
}

- (NSDictionary *) map: (id) callable
{
    NSMutableDictionary *results = [NSMutableDictionary dictionary];
    id args = [[NuCell alloc] init];
    if ([callable respondsToSelector:@selector(evalWithArguments:context:)]) {
        NSEnumerator *enumerator = [self keyEnumerator];
        id object;
        while ((object = [enumerator nextObject])) {
            [args setCar:object];
            [args setCdr:[[[NuCell alloc] init] autorelease]];
            [[args cdr] setCar:[self objectForKey:object]];
            [results setObject:[callable evalWithArguments:args context:nil] forKey:object];
        }
    }
    [args release];
    return results;
}

@end

@implementation NSMutableDictionary(Nu)
- (id) lookupObjectForKey:(id)key
{
    id object = [self objectForKey:key];
    if (object) return object;
    id parent = [self objectForKey:PARENT_KEY];
    if (!parent) return nil;
    return [parent lookupObjectForKey:key];
}

- (void) setPossiblyNullObject:(id) anObject forKey:(id) aKey
{
    [self setObject:((anObject == nil) ? Nu__null : anObject) forKey:aKey];
}

@end
