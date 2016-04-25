//
//  NuHandler.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//

#import "NuHandler.h"
#import "NuCell.h"
#import "NuInternals.h"
#import "NuBlock.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

static id collect_arguments(struct nu_handler_description *description, va_list ap)
{
    int i = 0;
    char *type;
    id arguments = [[NuCell alloc] init];
    id cursor = arguments;
    while((type = description->description[2+i])) {
        [cursor setCdr:[[[NuCell alloc] init] autorelease]];
        cursor = [cursor cdr];
        // NSLog(@"argument type %d: %s", i, type);
        if (!strcmp(type, "@")) {
            [cursor setCar:va_arg(ap, id)];
        }
        else if (!strcmp(type, "i")) {
            int x = va_arg(ap, int);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "C")) {
            // unsigned char is promoted to int in va_arg()
            //unsigned char x = va_arg(ap, unsigned char);
            int x = va_arg(ap, int);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "f")) {
            // calling this w/ float crashes on intel
            double x = (double) va_arg(ap, double);
            //NSLog(@"argument is %f", *((float *) &x));
            ap = ap - sizeof(float);              // messy, messy...
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "d")) {
            double x = va_arg(ap, double);
            //NSLog(@"argument is %lf", x);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, ":")) {
            SEL x = va_arg(ap, SEL);
            //NSLog(@"collect_arguments: [:] (SEL) = %@", NSStringFromSelector(x));
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "^@")) {
            void *x = va_arg(ap, void *);
            //NSLog(@"argument is %lf", x);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
#if TARGET_OS_IPHONE
        else if (!strcmp(type, "{CGRect={CGPoint=ff}{CGSize=ff}}")
                 || (!strcmp(type, "{CGRect=\"origin\"{CGPoint=\"x\"f\"y\"f}\"size\"{CGSize=\"width\"f\"height\"f}}"))) {
            CGRect x = va_arg(ap, CGRect);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
#else
        else if (!strcmp(type, "{_NSRect={_NSPoint=dd}{_NSSize=dd}}")) {
            NSRect x = va_arg(ap, NSRect);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "{CGRect={CGPoint=dd}{CGSize=dd}}")) {
#ifdef DARWIN
            CGRect x = va_arg(ap, CGRect);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
#endif
        }
        else if (!strcmp(type, "{_NSPoint=dd}")) {
            NSPoint x = va_arg(ap, NSPoint);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "{_NSSize=dd}")) {
            NSSize x = va_arg(ap, NSSize);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "{_NSRange=QQ}")) {
            NSRange x = va_arg(ap, NSRange);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
#endif
        else {
            NSLog(@"unsupported argument type %s, see objc/handler.m to add support for it", type);
        }
        i++;
    }
    return arguments;
}

// helper function called by method handlers
static void nu_handler(void *return_value, struct nu_handler_description *handler, id receiver, va_list ap)
{
    id result;
    BOOL retained_through_autorelease = NO;
    @autoreleasepool {
        NuBlock *block = (NuBlock *) handler->description[1];
        // NSLog(@"handling %@", [block stringValue]);
        id arguments = collect_arguments(handler, ap);
        result = [block evalWithArguments:[arguments cdr] context:nil self:receiver];
        if (return_value) {
            // if the call returns an object, retain the result so that it will survive the autorelease.
            // we undo this retain once we're safely outside of the autorelease block.
            if (handler->description[0][1] == '@') {
                retained_through_autorelease = YES;
                [result retain];
                // if the call is supposed to return a retained object, add an additional retain.
                if (handler->description[0][0] == '!') {
                    // The static analyzer says this is a potential leak.
                    // It's intentional, we are returning from a method that should return a retained (+1) object.
                    [result retain];
                }
            }
            set_objc_value_from_nu_value(return_value, result, handler->description[0]+1);
        }
        [arguments release];
    }
    if (retained_through_autorelease) {
        // undo the object-preserving retain we made in the autorelease block above.
        [result autorelease];
    }
}

@interface NuHandlers : NSObject
{
@public
    struct nu_handler_description *handlers;
    int handler_count;
    int next_free_handler;
}

@end

@implementation NuHandlers
- (id) initWithHandlers:(struct nu_handler_description *) h count:(int) count
{
    if ((self = [super init])) {
        handlers = h;
        handler_count = count;
        next_free_handler = 0;
    }
    return self;
}

@end

static IMP handler_returning_void(void *userdata) {
    return imp_implementationWithBlock(^(id receiver, ...) {
        struct nu_handler_description description;
        description.handler = NULL;
        description.description = userdata;
        va_list ap;
        va_start(ap, receiver);
        nu_handler(0, &description, receiver, ap);
    });
}

#define MAKE_HANDLER_WITH_TYPE(type) \
static IMP handler_returning_ ## type (void* userdata) \
{ \
return imp_implementationWithBlock(^(id receiver, ...) { \
struct nu_handler_description description; \
description.handler = NULL; \
description.description = userdata; \
va_list ap; \
va_start(ap, receiver); \
type result; \
nu_handler(&result, &description, receiver, ap); \
return result; \
}); \
}

MAKE_HANDLER_WITH_TYPE(id)
MAKE_HANDLER_WITH_TYPE(int)
MAKE_HANDLER_WITH_TYPE(bool)
MAKE_HANDLER_WITH_TYPE(float)
MAKE_HANDLER_WITH_TYPE(double)
#ifdef DARWIN
MAKE_HANDLER_WITH_TYPE(CGRect)
MAKE_HANDLER_WITH_TYPE(CGPoint)
MAKE_HANDLER_WITH_TYPE(CGSize)
#endif
#if !TARGET_OS_IPHONE
MAKE_HANDLER_WITH_TYPE(NSRect)
MAKE_HANDLER_WITH_TYPE(NSPoint)
MAKE_HANDLER_WITH_TYPE(NSSize)
#endif
MAKE_HANDLER_WITH_TYPE(NSRange)

static NSMutableDictionary *handlerWarehouse = nil;

@implementation NuHandlerWarehouse

+ (void) registerHandlers:(struct nu_handler_description *) description withCount:(int) count forReturnType:(NSString *) returnType
{
    if (!handlerWarehouse) {
        handlerWarehouse = [[NSMutableDictionary alloc] init];
    }
    NuHandlers *handlers = [[NuHandlers alloc] initWithHandlers:description count:count];
    [handlerWarehouse setObject:handlers forKey:returnType];
    [handlers release];
}

+ (IMP) handlerWithSelector:(SEL)sel block:(NuBlock *)block signature:(const char *) signature userdata:(char **) userdata
{
    NSString *returnType = [NSString stringWithCString:userdata[0]+1 encoding:NSUTF8StringEncoding];
    if ([returnType isEqualToString:@"v"]) {
        return handler_returning_void(userdata);
    }
    else if ([returnType isEqualToString:@"@"]) {
        return handler_returning_id(userdata);
    }
    else if ([returnType isEqualToString:@"i"]) {
        return handler_returning_int(userdata);
    }
    else if ([returnType isEqualToString:@"C"]) {
        return handler_returning_bool(userdata);
    }
    else if ([returnType isEqualToString:@"f"]) {
        return handler_returning_float(userdata);
    }
    else if ([returnType isEqualToString:@"d"]) {
        return handler_returning_double(userdata);
    }
#ifdef DARWIN
    else if ([returnType isEqualToString:@"{CGRect={CGPoint=ff}{CGSize=ff}}"]) {
        return handler_returning_CGRect(userdata);
    }
    else if ([returnType isEqualToString:@"{CGPoint=ff}"]) {
        return handler_returning_CGPoint(userdata);
    }
    else if ([returnType isEqualToString:@"{CGSize=ff}"]) {
        return handler_returning_CGSize(userdata);
    }
#endif
    else if ([returnType isEqualToString:@"{_NSRange=II}"]) {
        return handler_returning_NSRange(userdata);
    }
#if !TARGET_OS_IPHONE
    else if ([returnType isEqualToString:@"{_NSRect={_NSPoint=dd}{_NSSize=dd}}"]) {
        return handler_returning_NSRect(userdata);
    }
    else if ([returnType isEqualToString:@"{_NSPoint=dd}"]) {
        return handler_returning_NSPoint(userdata);
    }
    else if ([returnType isEqualToString:@"{_NSSize=dd}"]) {
        return handler_returning_NSSize(userdata);
    }
    else if ([returnType isEqualToString:@"{_NSRange=QQ}"]) {
        return handler_returning_NSRange(userdata);
    }
#endif
    else {
#if TARGET_OS_IPHONE
        // this is only a problem on iOS.
        NSLog(@"UNKNOWN RETURN TYPE %@", returnType);
#endif
    }
    // the following is deprecated. Now that we can create IMPs from blocks, we don't need handler pools.
    if (!handlerWarehouse) {
        return NULL;
    }
    NuHandlers *handlers = [handlerWarehouse objectForKey:returnType];
    if (handlers) {
        if (handlers->next_free_handler < handlers->handler_count) {
            handlers->handlers[handlers->next_free_handler].description = userdata;
            IMP handler = handlers->handlers[handlers->next_free_handler].handler;
            handlers->next_free_handler++;
            return handler;
        }
    }
    return NULL;
}

@end
