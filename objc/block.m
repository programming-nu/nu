// block.m
//  Nu blocks.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "nuinternals.h"
#import "block.h"
#import "cell.h"
#import "symbol.h"
#import "class.h"
#import "super.h"

extern id Nu__null;

@class NuSuper;

@implementation NuBlock

- (void) dealloc
{
    [parameters release];
    [body release];
    [context release];
    [super dealloc];
}

- (id) initWithParameters:(NuCell *)p body:(NuCell *)b context:(NSMutableDictionary *)c
{
    [super init];
    parameters = [p retain];
    body = [b retain];
    #ifdef CLOSE_ON_VALUES
    context = [c mutableCopy];
    #else
    context = [[NSMutableDictionary alloc] init];
    [context setObject:c forKey:PARENT_KEY];
    [context setObject:[c objectForKey:SYMBOLS_KEY] forKey:SYMBOLS_KEY];
    #endif
    return self;
}

- (NSString *) stringValue
{
    return [NSString stringWithFormat:@"(do %@ %@)", [parameters stringValue], [body stringValue]];
}

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context
{
    int numberOfArguments = [cdr length];
    int numberOfParameters = [parameters length];
    if (numberOfArguments != numberOfParameters) {
        [NSException raise:@"NuIncorrectNumberOfArguments"
            format:@"Incorrect number of arguments to block. Received %d but expected %d, %@",
            numberOfArguments,
            numberOfParameters,
            [parameters stringValue]];
    }

    //NSLog(@"block eval %@", [cdr stringValue]);
    // loop over the arguments, looking up their values in the calling_context and copying them into the evaluation_context
    id alist = parameters;
    id vlist = cdr;
    id evaluation_context = [context mutableCopy];
    //    NSLog(@"after copying, evaluation context %@ retain count %d", evaluation_context, [evaluation_context retainCount]);
    while (alist && (alist != Nu__null) && vlist && (vlist != Nu__null)) {
        id arg = [alist car];
        id value = [vlist car];
        if (calling_context && (calling_context != Nu__null))
            value = [value evalWithContext:calling_context];
        //NSLog(@"setting %@ = %@", arg, value);
        [evaluation_context setObject:value forKey:arg];
        alist = [alist cdr];
        vlist = [vlist cdr];
    }
    // evaluate the body of the block with the saved context (implicit progn)
    id value = Nu__null;
    id cursor = body;
    while (cursor && (cursor != Nu__null)) {
        value = [[cursor car] evalWithContext:evaluation_context];
        cursor = [cursor cdr];
    }
    //    NSLog(@"before releasing, evaluation context %@ retain count %d", evaluation_context, [evaluation_context retainCount]);
    //    NSLog(@"before releasing, value %@ retain count %d", value, [value retainCount]);
    [value retain];
    [value autorelease];
    [evaluation_context release];
    return value;
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context
{
    return [self callWithArguments:cdr context:calling_context];
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context self:(id)object
{
    int numberOfArguments = [cdr length];
    int numberOfParameters = [parameters length];
    if (numberOfArguments != numberOfParameters) {
        [NSException raise:@"NuIncorrectNumberOfArguments"
            format:@"Incorrect number of arguments to method. Received %d but expected %d, %@",
            numberOfArguments,
            numberOfParameters,
            [parameters stringValue]];
    }
    //    NSLog(@"block eval %@", [cdr stringValue]);
    // loop over the arguments, looking up their values in the calling_context and copying them into the evaluation_context
    id alist = parameters;
    id vlist = cdr;
    id evaluation_context = [context mutableCopy];
    //    NSLog(@"after copying, evaluation context %@ retain count %d", evaluation_context, [evaluation_context retainCount]);
    if (object) {
        NuSymbolTable *symbolTable = [evaluation_context objectForKey:SYMBOLS_KEY];
        NuClass *c = [context objectForKey:[symbolTable symbolWithString:@"_class"]];
        [evaluation_context setObject:object forKey:[symbolTable symbolWithCString:"self"]];
        [evaluation_context setObject:[NuSuper superWithObject:object ofClass:[c wrappedClass]] forKey:[symbolTable symbolWithCString:"super"]];
    }
    while (alist && (alist != Nu__null) && vlist && (vlist != Nu__null)) {
        id arg = [alist car];
        // since this message is sent by a method handler (which has already evaluated the block arguments),
        // we don't evaluate them here; instead we just copy them
        id value = [vlist car];
        //        NSLog(@"setting %@ = %@", arg, value);
        [evaluation_context setObject:value forKey:arg];
        alist = [alist cdr];
        vlist = [vlist cdr];
    }
    // evaluate the body of the block with the saved context (implicit progn)
    id value = Nu__null;
    id cursor = body;
    while (cursor && (cursor != Nu__null)) {
        value = [[cursor car] evalWithContext:evaluation_context];
        cursor = [cursor cdr];
    }
    [value retain];
    [value autorelease];
    [evaluation_context release];
    return value;
}

- (NSMutableDictionary *) context
{
    return context;
}

- (NuCell *) parameters
{
    return parameters;
}

- (NuCell *) body
{
    return body;
}

@end
