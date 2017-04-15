//
//  NuStack.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuStack.h"

@interface NuStack ()
{
    NSMutableArray *storage;
}
@end

@implementation NuStack
- (id) init
{
    if ((self = [super init])) {
        storage = [[NSMutableArray alloc] init];
    }
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

- (NSUInteger) depth
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
    for (NSInteger i = [storage count]-1; i >= 0; i--) {
        NSLog(@"stack: %@", [storage objectAtIndex:i]);
    }
}

@end
