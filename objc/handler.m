/*!
@file handler.m
@description Nu support for precompiled method handlers.
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

#import "handler.h"
#import "cell.h"
#ifdef IPHONE
#import <CoreGraphics/CoreGraphics.h>
#endif

static id collect_arguments(struct handler_description *description, va_list ap)
{
    int i = 0;
    char *type;
    id arguments = [[NuCell alloc] init];
    id cursor = arguments;
    while((type = description->description[2+i])) {
        [cursor setCdr:[[[NuCell alloc] init] autorelease]];
        cursor = [cursor cdr];
        //NSLog(@"argument type %d: %s", i, type);
        if (!strcmp(type, "@")) {
            [cursor setCar:va_arg(ap, id)];
        }
        else if (!strcmp(type, "i")) {
            int x = va_arg(ap, int);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        else if (!strcmp(type, "C")) {
            unsigned char x = va_arg(ap, unsigned char);
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
        else if (!strcmp(type, "^@")) {
            void *x = va_arg(ap, void *);
            //NSLog(@"argument is %lf", x);
            [cursor setCar:get_nu_value_from_objc_value(&x, type)];
        }
        #ifdef IPHONE
        else if (!strcmp(type, "{CGRect={CGPoint=ff}{CGSize=ff}}")
        || (!strcmp(type, "{CGRect=\"origin\"{CGPoint=\"x\"f\"y\"f}\"size\"{CGSize=\"width\"f\"height\"f}}"))) {
            CGRect x = va_arg(ap, CGRect);
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
void nu_handler(void *return_value, struct handler_description *description, id receiver, va_list ap)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    id arguments = collect_arguments(description, ap);
    NuBlock *block = (NuBlock *) description->description[1];
    id result = [block evalWithArguments:[arguments cdr] context:nil self:receiver];
    if (description->description[0][1] == '@') {
        [result retain];
        if (description->description[0][0] == '!') {
            [result retain];
        }
    }
    if (return_value) {
        set_objc_value_from_nu_value(return_value, result, description->description[0]+1);
    }
    [arguments release];
    [pool release];
    if (description->description[0][1] == '@') {
        [result autorelease];
    }
}

@interface NuHandlers : NSObject
{
    @public
    struct handler_description *handlers;
    int handler_count;
    int next_free_handler;
}

@end

@implementation NuHandlers
- (id) initWithHandlers:(struct handler_description *) h count:(int) count
{
    [super init];
    handlers = h;
    handler_count = count;
    next_free_handler = 0;
    return self;
}

@end

static NSMutableDictionary *handlerWarehouse = nil;

@implementation NuHandlerWarehouse

+ (void) registerHandlers:(struct handler_description *) description withCount:(int) count forReturnType:(NSString *) returnType
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
    if (!handlerWarehouse) {
        return NULL;
    }
    NuHandlers *handlers =
        [handlerWarehouse objectForKey:[NSString stringWithCString:userdata[0]+1 encoding:NSUTF8StringEncoding]];
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
