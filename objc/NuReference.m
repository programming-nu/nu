//
//  NuReference.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuReference.h"

#pragma mark - NuReference.m

@interface NuReference ()
{
    id *pointer;
    bool thePointerIsMine;
}
@end

@implementation NuReference

- (id) init
{
    if ((self = [super init])) {
        pointer = 0;
        thePointerIsMine = false;
    }
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
