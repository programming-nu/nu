// super.m
//  A proxy for an object's superclass.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import <Foundation/Foundation.h>
#import "symbol.h"
#import "super.h"
#import "cell.h"
#import "bridge.h"
#import "objc_runtime.h"

@implementation NuSuper

- (NuSuper *) initWithObject:(id) o ofClass:(Class) c
{
    [super init];
    object = o;
    class = c;
    return self;
}

+ (NuSuper *) superWithObject:(id) o ofClass:(Class) c
{
    return [[[self alloc] initWithObject:o ofClass:c] autorelease];
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    // By themselves, Objective-C objects evaluate to themselves.
    if (!cdr || (cdr == [NSNull null]))
        return object;

    //NSLog(@"messaging super with %@", [cdr stringValue]);
    // But when they're at the head of a list, the list is converted to a message and sent to the object
   
    NSMutableArray *args = [[NSMutableArray alloc] init];
    id cursor = cdr;
    id selector = [cursor car];
    NSMutableString *selectorString = [NSMutableString stringWithString:[selector stringValue]];
    cursor = [cursor cdr];
    while (cursor && (cursor != [NSNull null])) {
        [args addObject:[[cursor car] evalWithContext:context]];
        cursor = [cursor cdr];
        if (cursor && (cursor != [NSNull null])) {
            [selectorString appendString:[[cursor car] stringValue]];
            cursor = [cursor cdr];
        }
    }
    SEL sel = sel_getUid([selectorString cStringUsingEncoding:NSUTF8StringEncoding]);

	// we're going to send the message to the handler of its superclass instead of one defined for its class.
    Class c = class_getSuperclass(class);

    Method m = class_getInstanceMethod(c, sel);
    if (!m) m = class_getClassMethod(c, sel);

    id result = [NSNull null];
    if (m) {
        result = nu_calling_objc_method_handler(object, m, args);
    }
    else {
        NSLog(@"can't find function in superclass!");
        result = self;
    }
    [args release];
    return result;
}

@end