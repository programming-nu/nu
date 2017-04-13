//
//  NuSuper.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuSuper.h"
#import "Nu.h"
#import "NuInternals.h"
#import "NuCell.h"

#pragma mark - NuSuper.m

@interface NuSuper ()
{
    id object;
    Class class;
}
@end

@implementation NuSuper

- (NuSuper *) initWithObject:(id) o ofClass:(Class) c
{
    if ((self = [super init])) {
        object = o; // weak reference
        class = c; // weak reference
    }
    return self;
}

+ (NuSuper *) superWithObject:(id) o ofClass:(Class) c
{
    return [[[self alloc] initWithObject:o ofClass:c] autorelease];
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    // By themselves, Objective-C objects evaluate to themselves.
    if (!cdr || (cdr == Nu__null))
        return object;
    
    //NSLog(@"messaging super with %@", [cdr stringValue]);
    // But when they're at the head of a list, the list is converted to a message and sent to the object
    
    NSMutableArray *args = [[NSMutableArray alloc] init];
    id cursor = cdr;
    id selector = [cursor car];
    NSMutableString *selectorString = [NSMutableString stringWithString:[selector stringValue]];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        [args addObject:[[cursor car] evalWithContext:context]];
        cursor = [cursor cdr];
        if (cursor && (cursor != Nu__null)) {
            [selectorString appendString:[[cursor car] stringValue]];
            cursor = [cursor cdr];
        }
    }
    SEL sel = sel_getUid([selectorString UTF8String]);
    
    // we're going to send the message to the handler of its superclass instead of one defined for its class.
    Class c = class_getSuperclass(class);
    Method m = class_getInstanceMethod(c, sel);
    if (!m) m = class_getClassMethod(c, sel);
    
    id result;
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
