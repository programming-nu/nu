/*
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

#import "nutypes.h"

#import <Foundation/Foundation.h>
#import "main.h"

static BOOL verbose_helper = false;

@interface NuTestHelper : NSObject
{
}

@end

static int deallocationCount = 0;

@implementation NuTestHelper

+ (void) setVerbose:(BOOL) v
{
    verbose_helper = v;
}

+ (BOOL) verbose
{
    return verbose_helper;
}

+ (id) helperInObjCUsingAllocInit
{
    id object = [[[NuTestHelper alloc] init] autorelease];
    return object;
}

+ (id) helperInObjCUsingNew
{
    id object = [[NuTestHelper new] autorelease];
    return object;
}

- (void) dealloc
{
    if (verbose_helper)
        NSLog(@"(NuTestHelper dealloc)");
    deallocationCount++;
    [super dealloc];
}

- (void) finalize
{
    if (verbose_helper)
        NSLog(@"(NuTestHelper finalize %p)", self);
    deallocationCount++;
    [super finalize];
}

+ (void) resetDeallocationCount
{
#ifdef DARWIN
#ifndef IPHONE
	[[NSGarbageCollector defaultCollector] collectExhaustively];
#endif
#endif
    deallocationCount = 0;
}

+ (int) deallocationCount
{
#ifdef DARWIN
#ifndef IPHONE
	[[NSGarbageCollector defaultCollector] collectExhaustively];
#endif
#endif
    return deallocationCount;
}

@end
