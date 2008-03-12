/*!
@file stack.m
@description A simple stack class used by the Nu parser.
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
