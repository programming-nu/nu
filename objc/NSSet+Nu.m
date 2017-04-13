//
//  NSSet+Nu.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NSSet+Nu.h"
#import "NuCell.h"
#import "NuInternals.h"


@implementation NSSet(Nu)
+ (NSSet *) setWithList:(id) list
{
    NSMutableSet *s = [NSMutableSet set];
    id cursor = list;
    while (cursor && cursor != Nu__null) {
        [s addObject:[cursor car]];
        cursor = [cursor cdr];
    }
    return s;
}

// Convert a set into a list.
- (NuCell *) list
{
    NSEnumerator *setEnumerator = [self objectEnumerator];
    NSObject *anObject = [setEnumerator nextObject];
    
    if(!anObject)
        return nil;
    
    NuCell *result = [[[NuCell alloc] init] autorelease];
    NuCell *cursor = result;
    [cursor setCar:anObject];
    
    while ((anObject = [setEnumerator nextObject])) {
        [cursor setCdr:[[[NuCell alloc] init] autorelease]];
        cursor = [cursor cdr];
        [cursor setCar:anObject];
    }
    return result;
}

@end

@implementation NSMutableSet(Nu)

- (void) addPossiblyNullObject:(id)anObject
{
    [self addObject:((anObject == nil) ? Nu__null : anObject)];
}

@end

