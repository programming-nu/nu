/*!
@file reference.m
@description The Nu pointer wrapper.
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
#import "reference.h"

@implementation NuReference

- (id) init
{
    [super init];
    pointer = 0;
    thePointerIsMine = false;
    return self;
}

- (id) value {return pointer ? *pointer : nil;}

- (void) setValue:(id) v
{
    if (!pointer) {
        pointer = (id *) malloc (sizeof (id));
        *pointer = nil;
        thePointerIsMine = true;
    }
    [v retain];
    [(*pointer) release];
    (*pointer)  = v;
}

- (void) setPointer:(id *) p
{
    if (thePointerIsMine) {
        free(pointer);
        thePointerIsMine = false;
    }
    pointer = p;
}

- (id *) pointerToReferencedObject
{
    if (!pointer) {
        pointer = (id *) malloc (sizeof (id));
        *pointer = nil;
        thePointerIsMine = true;
    }
    return pointer;
}

- (void) retainReferencedObject
{
    [(*pointer) retain];
}

- (void) dealloc
{
    if (thePointerIsMine)
        free(pointer);
    [super dealloc];
}

@end
