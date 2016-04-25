//
//  NuBlock.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuBlock.h"
#import "NuInternals.h"
#import "NuSuper.h"
#import "NSDictionary+Nu.h"
#import "NuCell.h"

@interface NuBlock ()
{
    NuCell *parameters;
    NuCell *body;
    NSMutableDictionary *context;
}
@end

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
    if ((self = [super init])) {
        parameters = [p retain];
        body = [b retain];
#ifdef CLOSE_ON_VALUES
        context = [c mutableCopy];
#else
        context = [[NSMutableDictionary alloc] init];
        [context setPossiblyNullObject:c forKey:PARENT_KEY];
        [context setPossiblyNullObject:[c objectForKey:SYMBOLS_KEY] forKey:SYMBOLS_KEY];
#endif
        
        // Check for the presence of "*args" in parameter list
        id plist = parameters;
        
        if (!(   ([parameters length] == 1)
              && ([[[parameters car] stringValue] isEqualToString:@"*args"])))
        {
            while (plist && (plist != Nu__null))
            {
                id parameter = [plist car];
                
                if ([[parameter stringValue] isEqualToString:@"*args"])
                {
                    printf("Warning: Overriding implicit variable '*args'.\n");
                    return self;
                }
                
                plist = [plist cdr];
            }
        }
    }
    return self;
}

- (NSString *) stringValue
{
    return [NSString stringWithFormat:@"(do %@ %@)", [parameters stringValue], [body stringValue]];
}

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context
{
    NSUInteger numberOfArguments = [cdr length];
    NSUInteger numberOfParameters = [parameters length];
    
    if (numberOfArguments != numberOfParameters) {
        // is the last parameter a variable argument? if so, it's ok, and we allow it to have zero elements.
        id lastParameter = [parameters lastObject];
        if (lastParameter && ([[lastParameter stringValue] characterAtIndex:0] == '*')) {
            if (numberOfArguments < (numberOfParameters - 1)) {
                [NSException raise:@"NuIncorrectNumberOfArguments"
                            format:@"Incorrect number of arguments to block. Received %ld but expected %ld or more: %@",
                 (unsigned long) numberOfArguments,
                 (unsigned long) (numberOfParameters - 1),
                 [parameters stringValue]];
            }
        }
        else {
            [NSException raise:@"NuIncorrectNumberOfArguments"
                        format:@"Incorrect number of arguments to block. Received %ld but expected %ld: %@",
             (unsigned long) numberOfArguments,
             (unsigned long) numberOfParameters,
             [parameters stringValue]];
        }
    }
    //NSLog(@"block eval %@", [cdr stringValue]);
    // loop over the parameters, looking up their values in the calling_context and copying them into the evaluation_context
    id plist = parameters;
    id vlist = cdr;
    id evaluation_context = [context mutableCopy];
    
    // Insert the implicit variable "*args".  It contains the entire parameter list.
    NuSymbolTable *symbolTable = [evaluation_context objectForKey:SYMBOLS_KEY];
    [evaluation_context setPossiblyNullObject:cdr forKey:[symbolTable symbolWithString:@"*args"]];
    
    while (plist && (plist != Nu__null)) {
        id parameter = [plist car];
        if ([[parameter stringValue] characterAtIndex:0] == '*') {
            id varargs = [[[NuCell alloc] init] autorelease];
            id cursor = varargs;
            while (vlist != Nu__null) {
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                id value = [vlist car];
                if (calling_context && (calling_context != Nu__null))
                    value = [value evalWithContext:calling_context];
                [cursor setCar:value];
                vlist = [vlist cdr];
            }
            [evaluation_context setPossiblyNullObject:[varargs cdr] forKey:parameter];
            plist = [plist cdr];
            // this must be the last element in the parameter list
            if (plist != Nu__null) {
                [NSException raise:@"NuBadParameterList"
                            format:@"Variable argument list must be the last parameter in the parameter list: %@",
                 [parameters stringValue]];
            }
        }
        else {
            id value = [vlist car];
            if (calling_context && (calling_context != Nu__null))
                value = [value evalWithContext:calling_context];
            //NSLog(@"setting %@ = %@", parameter, value);
            [evaluation_context setPossiblyNullObject:value forKey:parameter];
            plist = [plist cdr];
            vlist = [vlist cdr];
        }
    }
    // evaluate the body of the block with the saved context (implicit progn)
    id value = Nu__null;
    id cursor = body;
    @try
    {
        while (cursor && (cursor != Nu__null)) {
            value = [[cursor car] evalWithContext:evaluation_context];
            cursor = [cursor cdr];
        }
    }
    @catch (NuReturnException *exception) {
        value = [exception value];
        if ([exception blockForReturn] && ([exception blockForReturn] != self)) {
            @throw(exception);
        }
    }
    @catch (id exception) {
        @throw(exception);
    }
    [value retain];
    [value autorelease];
    [evaluation_context release];
    return value;
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context
{
    return [self callWithArguments:cdr context:calling_context];
}

static id getObjectFromContext(id context, id symbol)
{
    while (IS_NOT_NULL(context)) {
        id object = [context objectForKey:symbol];
        if (object)
            return object;
        context = [context objectForKey:PARENT_KEY];
    }
    return nil;
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context self:(id)object
{
    NSUInteger numberOfArguments = [cdr length];
    NSUInteger numberOfParameters = [parameters length];
    if (numberOfArguments != numberOfParameters) {
        [NSException raise:@"NuIncorrectNumberOfArguments"
                    format:@"Incorrect number of arguments to method. Received %ld but expected %ld, %@",
         (unsigned long) numberOfArguments,
         (unsigned long) numberOfParameters,
         [parameters stringValue]];
    }
    //    NSLog(@"block eval %@", [cdr stringValue]);
    // loop over the arguments, looking up their values in the calling_context and copying them into the evaluation_context
    id plist = parameters;
    id vlist = cdr;
    id evaluation_context = [context mutableCopy];
    //    NSLog(@"after copying, evaluation context %@ retain count %d", evaluation_context, [evaluation_context retainCount]);
    if (object) {
        NuSymbolTable *symbolTable = [evaluation_context objectForKey:SYMBOLS_KEY];
        // look up one level for the _class value, but allow for it to be higher (in the perverse case of nested method declarations).
        NuClass *c = getObjectFromContext([context objectForKey:PARENT_KEY], [symbolTable symbolWithString:@"_class"]);
        [evaluation_context setPossiblyNullObject:object forKey:[symbolTable symbolWithString:@"self"]];
        [evaluation_context setPossiblyNullObject:[NuSuper superWithObject:object ofClass:[c wrappedClass]] forKey:[symbolTable symbolWithString:@"super"]];
    }
    while (plist && (plist != Nu__null) && vlist && (vlist != Nu__null)) {
        id arg = [plist car];
        // since this message is sent by a method handler (which has already evaluated the block arguments),
        // we don't evaluate them here; instead we just copy them
        id value = [vlist car];
        //        NSLog(@"setting %@ = %@", arg, value);
        [evaluation_context setPossiblyNullObject:value forKey:arg];
        plist = [plist cdr];
        vlist = [vlist cdr];
    }
    // evaluate the body of the block with the saved context (implicit progn)
    id value = Nu__null;
    id cursor = body;
    @try
    {
        while (cursor && (cursor != Nu__null)) {
            value = [[cursor car] evalWithContext:evaluation_context];
            cursor = [cursor cdr];
        }
    }
    @catch (NuReturnException *exception) {
        value = [exception value];
        if ([exception blockForReturn] && ([exception blockForReturn] != self)) {
            @throw(exception);
        }
    }
    @catch (id exception) {
        @throw(exception);
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
