/*!
@file ivars.m
@description Helpers for instance variable memory management.
@copyright Copyright (c) 2008 Neon Design Technology, Inc.

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
#import <Foundation/Foundation.h>
#import "nuinternals.h"

static NSMapTable *ivarsToRelease = NULL;

// use this to remember that instance variables created by Nu must be released when their owner is deallocated.
void nu_registerIvarForRelease(Class c, NSString *name)
{
    return; // temporarily disable ivar releases.
    if (!ivarsToRelease) {
        //NSLog(@"creating ivarsToRelease map table");
        ivarsToRelease = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSObjectMapValueCallBacks, 0);
    }
    NSMutableArray *ivars = NSMapGet(ivarsToRelease, c);
    if (!ivars) {
        ivars = [NSMutableArray array];
        [ivars addObject:name];
        //NSLog(@"inserting array of ivars to release for class %@(%d) %@", [c className], (int) c, [ivars description]);
        NSMapInsert(ivarsToRelease, c, ivars);
    }
    else {
        //NSLog(@"appending %@ to list of ivars for class %@", name, [c className]);
        [ivars addObject:name];
    }
}

// use this to get the instance variables that should be released.
NSArray *nu_ivarsToRelease(Class c)
{
    NSArray *ivars;
    return (ivarsToRelease && ((ivars = NSMapGet(ivarsToRelease, c)))) ? ivars : nil;
}
