// operator.m
//  Nu operators.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "operator.h"
#import "extensions.h"
#import "cell.h"
#import "symbol.h"
#import "block.h"
#import "macro.h"
#import "class.h"
#import "objc_runtime.h"
#import "object.h"
#import "parser.h"
#import "regex.h"
#import "version.h"

@interface NuBreakException : NSException {}
@end

@implementation NuBreakException
- (id) init
{
    return [super initWithName:@"NuBreakException" reason:@"A break operator was evaluated" userInfo:nil];
}

@end

@interface NuContinueException : NSException {}
@end

@implementation NuContinueException
- (id) init
{
    return [super initWithName:@"NuContinueException" reason:@"A continue operator was evaluated" userInfo:nil];
}

@end

static bool valueIsTrue(id value)
{
    bool result = value && (value != Nu__null);
    if (result && [value isKindOfClass:[NSNumber class]]) {
        if ([value intValue] == 0)
            result = false;
    }
    return result;
}

@implementation NuOperator : NSObject
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context {return nil;}
- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context {return [self callWithArguments:cdr context:context];}
@end

@interface Nu_car : NuOperator {}
@end

@implementation Nu_car

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    id value = [cadr evalWithContext:context];
    return ([value respondsToSelector:@selector(car)]) ? [value car] : Nu__null;
}

@end

@interface Nu_cdr : NuOperator {}
@end

@implementation Nu_cdr

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    id value = [cadr evalWithContext:context];
    return ([value respondsToSelector:@selector(cdr)]) ? [value cdr] : Nu__null;
}

@end

@interface Nu_atom : NuOperator {}
@end

@implementation Nu_atom

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    id value = [cadr evalWithContext:context];
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if ([value atom])
        return [symbolTable symbolWithCString:"t"];
    else
        return Nu__null;
}

@end

@interface Nu_eq : NuOperator {}
@end

@implementation Nu_eq
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    id caddr = [[cdr cdr] car];
    id value1 = [cadr evalWithContext:context];
    id value2 = [caddr evalWithContext:context];
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if ((value1 == nil) && (value2 == nil)) {
        return [symbolTable symbolWithCString:"t"];
    }
    else if ([value1 isEqual:value2]) {
        return [symbolTable symbolWithCString:"t"];
    }
    else {
        return Nu__null;
    }
}

@end

@interface Nu_neq : NuOperator {}
@end

@implementation Nu_neq
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    id caddr = [[cdr cdr] car];
    id value1 = [cadr evalWithContext:context];
    id value2 = [caddr evalWithContext:context];
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if ((value1 == nil) && (value2 == nil)) {
        return Nu__null;
    }
    else if ([value1 isEqual:value2]) {
        return Nu__null;
    }
    else {
        return [symbolTable symbolWithCString:"t"];
    }
}

@end

@interface Nu_cons : NuOperator {}
@end

@implementation Nu_cons
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    id cddr = [cdr cdr];
    id value1 = [cadr evalWithContext:context];
    id value2 = [cddr evalWithContext:context];
    id newCell = [[[NuCell alloc] init] autorelease];
    [newCell setCar:value1];
    [newCell setCdr:value2];
    return newCell;
}

@end

@interface Nu_append : NuOperator {}
@end

@implementation Nu_append
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id newList = Nu__null;
    id cursor = nil;
    id list_to_append = cdr;
    while (list_to_append && (list_to_append != Nu__null)) {
        id item_to_append = [[list_to_append car] evalWithContext:context];
        while (item_to_append && (item_to_append != Nu__null)) {
            if (newList == Nu__null) {
                newList = [[[NuCell alloc] init] autorelease];
                cursor = newList;
            }
            else {
                [cursor setCdr: [[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
            }
            id item = [item_to_append car];
            [cursor setCar: item];
            item_to_append = [item_to_append cdr];
        }
        list_to_append = [list_to_append cdr];
    }
    return newList;
}

@end

@interface Nu_cond : NuOperator {}
@end

@implementation Nu_cond
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id pairs = cdr;
    id value = Nu__null;
    while (pairs != Nu__null) {
        id condition = [[pairs car] car];
        id test = [condition evalWithContext:context];
        if (valueIsTrue(test)) {
            value = test;
            id cursor = [[pairs car] cdr];
            while (cursor && (cursor != Nu__null)) {
                value = [[cursor car] evalWithContext:context];
                cursor = [cursor cdr];
            }
            return value;
        }
        pairs = [pairs cdr];
    }
    return value;
}

@end

@interface Nu_case : NuOperator {}
@end

@implementation Nu_case
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id target = [[cdr car] evalWithContext:context];
    id cases = [cdr cdr];
    while ([cases cdr] != Nu__null) {
        id condition = [[cases car] car];
        id result = [condition evalWithContext:context];
        if ([result isEqual:target]) {
            id value = Nu__null;
            id cursor = [[cases car] cdr];
            while (cursor && (cursor != Nu__null)) {
                value = [[cursor car] evalWithContext:context];
                cursor = [cursor cdr];
            }
            return value;
        }
        cases = [cases cdr];
    }
    // or return the last one
    id value = Nu__null;
    id cursor = [[cases car] cdr];
    while (cursor && (cursor != Nu__null)) {
        value = [[cursor car] evalWithContext:context];
        cursor = [cursor cdr];
    }
    return value;
}

@end

@interface Nu_if : NuOperator {}
@end

@implementation Nu_if
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    //id thenSymbol = [symbolTable symbolWithCString:"then"];
    id elseSymbol = [symbolTable symbolWithCString:"else"];

    id result = Nu__null;
    id test = [[cdr car] evalWithContext:context];

    bool testIsTrue = valueIsTrue(test);

    id expressions = [cdr cdr];
    while (expressions && (expressions != Nu__null)) {
        id nextExpression = [expressions car];
        if ([nextExpression isKindOfClass:[NuCell class]]) {
            if ([nextExpression car] == elseSymbol) {
                if (!testIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
            else {
                if (testIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
        }
        else {
            if (testIsTrue)
                result = [nextExpression evalWithContext:context];
        }
        expressions = [expressions cdr];
    }
    return result;
}

@end

@interface Nu_unless : NuOperator {}
@end

@implementation Nu_unless
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    //id thenSymbol = [symbolTable symbolWithCString:"then"];
    id elseSymbol = [symbolTable symbolWithCString:"else"];

    id result = Nu__null;
    id test = [[cdr car] evalWithContext:context];

    bool testIsTrue = valueIsTrue(test);

    id expressions = [cdr cdr];
    while (expressions && (expressions != Nu__null)) {
        id nextExpression = [expressions car];
        if ([nextExpression isKindOfClass:[NuCell class]]) {
            if ([nextExpression car] == elseSymbol) {
                if (testIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
            else {
                if (!testIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
        }
        else {
            if (!testIsTrue)
                result = [nextExpression evalWithContext:context];
        }
        expressions = [expressions cdr];
    }
    return result;
}

@end

@interface Nu_while : NuOperator {}
@end

@implementation Nu_while
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id result = Nu__null;
    id test = [[cdr car] evalWithContext:context];
    while (valueIsTrue(test)) {
        @try
        {
            id expressions = [cdr cdr];
            while (expressions && (expressions != Nu__null)) {
                result = [[expressions car] evalWithContext:context];
                expressions = [expressions cdr];
            }
        }
        @catch (NuBreakException *exception) {
            break;
        }
        @catch (NuContinueException *exception) {
            // do nothing, just continue with the next loop iteration
        }
        @catch (id exception) {
            @throw(exception);
        }
        test = [[cdr car] evalWithContext:context];
    }
    return result;
}

@end

@interface Nu_until : NuOperator {}
@end

@implementation Nu_until
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id result = Nu__null;
    id test = [[cdr car] evalWithContext:context];
    while (!valueIsTrue(test)) {
        @try
        {
            id expressions = [cdr cdr];
            while (expressions && (expressions != Nu__null)) {
                result = [[expressions car] evalWithContext:context];
                expressions = [expressions cdr];
            }
        }
        @catch (NuBreakException *exception) {
            break;
        }
        @catch (NuContinueException *exception) {
            // do nothing, just continue with the next loop iteration
        }
        @catch (id exception) {
            @throw(exception);
        }
        test = [[cdr car] evalWithContext:context];
    }
    return result;
}

@end

@interface Nu_for : NuOperator {}
@end

@implementation Nu_for
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id result = Nu__null;
    id controls = [cdr car];                      // this could use some error checking!
    id loopinit = [controls car];
    id looptest = [[controls cdr] car];
    id loopincr = [[[controls cdr] cdr] car];
    // initialize the loop
    [loopinit evalWithContext:context];
    // evaluate the loop condition
    id test = [looptest evalWithContext:context];
    while (valueIsTrue(test)) {
        @try
        {
            id expressions = [cdr cdr];
            while (expressions && (expressions != Nu__null)) {
                result = [[expressions car] evalWithContext:context];
                expressions = [expressions cdr];
            }
        }
        @catch (NuBreakException *exception) {
            break;
        }
        @catch (NuContinueException *exception) {
            // do nothing, just continue with the next loop iteration
        }
        @catch (id exception) {
            @throw(exception);
        }
        // perform the end of loop increment step
        [loopincr evalWithContext:context];
        // evaluate the loop condition
        test = [looptest evalWithContext:context];
    }
    return result;
}

@end

@interface Nu_try : NuOperator {}
@end

@implementation Nu_try
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id catchSymbol = [symbolTable symbolWithCString:"catch"];
    id finallySymbol = [symbolTable symbolWithCString:"finally"];
    id result = Nu__null;
    @try
    {
        // evaluate all the expressions that are outside catch and finally blocks
        id expressions = cdr;
        while (expressions && (expressions != Nu__null)) {
            id nextExpression = [expressions car];
            if ([nextExpression isKindOfClass:[NuCell class]]) {
                if (([nextExpression car] != catchSymbol) && ([nextExpression car] != finallySymbol)) {
                    result = [nextExpression evalWithContext:context];
                }
            }
            else {
                result = [nextExpression evalWithContext:context];
            }
            expressions = [expressions cdr];
        }
    }
    @catch (id thrownObject) {
        // evaluate all the expressions that are in catch blocks
        id expressions = cdr;
        while (expressions && (expressions != Nu__null)) {
            id nextExpression = [expressions car];
            if ([nextExpression isKindOfClass:[NuCell class]]) {
                if (([nextExpression car] == catchSymbol)) {
                    // this is a catch block.
                    // the first expression should be a list with a single symbol
                    // that's a name.  we'll set that name to the thing we caught
                    id nameList = [[nextExpression cdr] car];
                    id name = [nameList car];
                    [context setValue:thrownObject forKey:name];
                    // now we loop over the rest of the expressions and evaluate them one by one
                    id cursor = [[nextExpression cdr] cdr];
                    while (cursor && (cursor != Nu__null)) {
                        result = [[cursor car] evalWithContext:context];
                        cursor = [cursor cdr];
                    }
                }
            }
            expressions = [expressions cdr];
        }
    }
    @finally
    {
        // evaluate all the expressions that are in finally blocks
        id expressions = cdr;
        while (expressions && (expressions != Nu__null)) {
            id nextExpression = [expressions car];
            if ([nextExpression isKindOfClass:[NuCell class]]) {
                if (([nextExpression car] == finallySymbol)) {
                    // this is a finally block
                    // loop over the rest of the expressions and evaluate them one by one
                    id cursor = [nextExpression cdr];
                    while (cursor && (cursor != Nu__null)) {
                        result = [[cursor car] evalWithContext:context];
                        cursor = [cursor cdr];
                    }
                }
            }
            expressions = [expressions cdr];
        }
    }
    return result;
}

@end

@interface Nu_throw : NuOperator {}
@end

@implementation Nu_throw
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id exception = [[cdr car] evalWithContext:context];
    @throw exception;
    return exception;
}

@end

@interface Nu_synchronized : NuOperator {}
@end

@implementation Nu_synchronized
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    //  NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];

    id object = [[cdr car] evalWithContext:context];
    id result = Nu__null;

    @synchronized(object) {
        // evaluate the rest of the expressions
        id expressions = [cdr cdr];
        while (expressions && (expressions != Nu__null)) {
            id nextExpression = [expressions car];
            result = [nextExpression evalWithContext:context];
            expressions = [expressions cdr];
        }
    }
    return result;
}

@end

@interface Nu_quote : NuOperator {}
@end

@implementation Nu_quote
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    return cadr;
}

@end

@interface Nu_context : NuOperator {}
@end

@implementation Nu_context
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return context;
}

@end

@interface Nu_set : NuOperator {}
@end

@implementation Nu_set
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{

    id symbol = [cdr car];
    id value = [[cdr cdr] car];
    value = [value evalWithContext:context];

    char c = (char) [[symbol stringValue] characterAtIndex:0];
    if (c == '$') {
        [symbol setValue:value];
    }
    else if (c == '@') {
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id object = [context objectForKey:[symbolTable symbolWithCString:"self"]];
        id ivar = [[symbol stringValue] substringFromIndex:1];
        //NSLog(@"setting value for ivar %@ to %@", ivar, value);
        [object setValue:value forIvar:ivar];
    }
    else {
        [context setObject:value forKey:symbol];
    }
    return value;
}

@end

@interface Nu_global : NuOperator {}
@end

@implementation Nu_global
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{

    id symbol = [cdr car];
    id value = [[cdr cdr] car];
    value = [value evalWithContext:context];
    [symbol setValue:value];
    return value;
}

@end

@interface Nu_regex : NuOperator {}
@end

@implementation Nu_regex
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id value = [cdr car];
    value = [value evalWithContext:context];
    return [NuRegex regexWithPattern:value];
}

@end

@interface Nu_do : NuOperator {}
@end

@implementation Nu_do
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id args = [cdr car];
    id body = [cdr cdr];
    NuBlock *block = [[[NuBlock alloc] initWithParameters:args body:body context:context] autorelease];
    return block;
}

@end

@interface Nu_function : NuOperator {}
@end

@implementation Nu_function
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id symbol = [cdr car];
    id args = [[cdr cdr] car];
    id body = [[cdr cdr] cdr];
    NuBlock *block = [[NuBlock alloc] initWithParameters:args body:body context:context];
    [context setObject:block forKey:symbol];      // this defines the function in the calling context
                                                  // this defines the function in the block context, which allows recursion
    [[block context] setObject:block forKey:symbol];
    return block;
}

@end

@interface Nu_label : NuOperator {}
@end

@implementation Nu_label
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id symbol = [cdr car];
    id value = [[cdr cdr] car];
    value = [value evalWithContext:context];
    if ([value isKindOfClass:[NuBlock class]]) {
        //NSLog(@"setting context[%@] = %@", symbol, value);
        [((NSMutableDictionary *)[value context]) setObject:value forKey:symbol];
    }
    return value;
}

@end

@interface Nu_macro : NuOperator {}
@end

@implementation Nu_macro
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id name = [cdr car];
    id body = [cdr cdr];

    NuMacro *macro = [[NuMacro alloc] initWithName:name body:body];
    [context setObject:macro forKey:name];        // this defines the function in the calling context
    return macro;
}

@end

@interface Nu_list : NuOperator {}
@end

@implementation Nu_list
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id result = Nu__null;
    id cursor = cdr;
    id result_cursor = Nu__null;
    while (cursor && (cursor != Nu__null)) {
        if (result == Nu__null) {
            result = [[[NuCell alloc] init] autorelease];
            result_cursor = result;
        }
        else {
            [result_cursor setCdr:[[[NuCell alloc] init] autorelease]];
            result_cursor = [result_cursor cdr];
        }
        id value = [[cursor car] evalWithContext:context];
        [result_cursor setCar:value];
        cursor = [cursor cdr];
    }
    return result;
}

@end

@interface Nu_add : NuOperator {}
@end

@implementation Nu_add
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if ([context objectForKey:[symbolTable symbolWithCString:"__class"]] && ![context objectForKey:[symbolTable symbolWithCString:"__method"]]) {
        // we are inside a class declaration and outside a method declaration.
        // treat this as a "cmethod" call
        Class classToExtend = [[ context objectForKey:[symbolTable symbolWithCString:"__class"]] wrappedClass]->isa;
        return help_add_method_to_class(classToExtend, cdr, context);
    }
    // otherwise, it's an addition
    double sum = 0;
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        sum += [[[cursor car] evalWithContext:context] doubleValue];
        cursor = [cursor cdr];
    }
    return [NSNumber numberWithDouble:sum];
}

@end

@interface Nu_multiply : NuOperator {}
@end

@implementation Nu_multiply
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    double product = 1;
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        product *= [[[cursor car] evalWithContext:context] doubleValue];
        cursor = [cursor cdr];
    }
    return [NSNumber numberWithDouble:product];
}

@end

@interface Nu_subtract : NuOperator {}
@end

@implementation Nu_subtract
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if ([context objectForKey:[symbolTable symbolWithCString:"__class"]] && ![context objectForKey:[symbolTable symbolWithCString:"__method"]]) {
        // we are inside a class declaration and outside a method declaration.
        // treat this as an "imethod" call
        Class classToExtend = [[ context objectForKey:[symbolTable symbolWithCString:"__class"]] wrappedClass];
        return help_add_method_to_class(classToExtend, cdr, context);
    }
    // otherwise, it's a subtraction
    id cursor = cdr;
    double sum = [[[cursor car] evalWithContext:context] doubleValue];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        sum -= [[[cursor car] evalWithContext:context] doubleValue];
        cursor = [cursor cdr];
    }
    return [NSNumber numberWithDouble:sum];
}

@end

@interface Nu_divide : NuOperator {}
@end

@implementation Nu_divide
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cursor = cdr;
    double product = [[[cursor car] evalWithContext:context] doubleValue];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        product /= [[[cursor car] evalWithContext:context] doubleValue];
        cursor = [cursor cdr];
    }
    return [NSNumber numberWithDouble:product];
}

@end

@interface Nu_bitwiseand : NuOperator {}
@end

@implementation Nu_bitwiseand
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cursor = cdr;
    long result = [[[cursor car] evalWithContext:context] longValue];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        result &= [[[cursor car] evalWithContext:context] longValue];
        cursor = [cursor cdr];
    }
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_bitwiseor : NuOperator {}
@end

@implementation Nu_bitwiseor
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cursor = cdr;
    long result = [[[cursor car] evalWithContext:context] longValue];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        result |= [[[cursor car] evalWithContext:context] longValue];
        cursor = [cursor cdr];
    }
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_greaterthan : NuOperator {}
@end

@implementation Nu_greaterthan
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    double first = [[[cdr car] evalWithContext:context] doubleValue];
    double second = [[[[cdr cdr] car] evalWithContext:context] doubleValue];
    return (first > second) ? [symbolTable symbolWithCString:"t"] : Nu__null;
}

@end

@interface Nu_lessthan : NuOperator {}
@end

@implementation Nu_lessthan
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    double first = [[[cdr car] evalWithContext:context] doubleValue];
    double second = [[[[cdr cdr] car] evalWithContext:context] doubleValue];
    return (first < second) ? [symbolTable symbolWithCString:"t"] : Nu__null;
}

@end

@interface Nu_gte : NuOperator {}
@end

@implementation Nu_gte
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    double first = [[[cdr car] evalWithContext:context] doubleValue];
    double second = [[[[cdr cdr] car] evalWithContext:context] doubleValue];
    return (first >= second) ? [symbolTable symbolWithCString:"t"] : Nu__null;
}

@end

@interface Nu_lte : NuOperator {}
@end

@implementation Nu_lte
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    double first = [[[cdr car] evalWithContext:context] doubleValue];
    double second = [[[[cdr cdr] car] evalWithContext:context] doubleValue];
    return (first <= second) ? [symbolTable symbolWithCString:"t"] : Nu__null;
}

@end

@interface Nu_leftshift : NuOperator {}
@end

@implementation Nu_leftshift
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    long result = [[[cdr car] evalWithContext:context] longValue];
    result = result << [[[[cdr cdr] car] evalWithContext:context] longValue];
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_rightshift : NuOperator {}
@end

@implementation Nu_rightshift
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    long result = [[[cdr car] evalWithContext:context] longValue];
    result = result >> [[[[cdr cdr] car] evalWithContext:context] longValue];
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_and : NuOperator {}
@end

@implementation Nu_and
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cursor = cdr;
    id value = Nu__null;
    while (cursor && (cursor != Nu__null)) {
        value = [[cursor car] evalWithContext:context];
        if (!valueIsTrue(value))
            return Nu__null;
        cursor = [cursor cdr];
    }
    return value;
}

@end

@interface Nu_or : NuOperator {}
@end

@implementation Nu_or
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        id value = [[cursor car] evalWithContext:context];
        if (valueIsTrue(value))
            return value;
        cursor = [cursor cdr];
    }
    return Nu__null;
}

@end

@interface Nu_not : NuOperator {}
@end

@implementation Nu_not
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id cursor = cdr;
    if (cursor && (cursor != Nu__null)) {
        id value = [[cursor car] evalWithContext:context];
        return valueIsTrue(value) ? Nu__null : [symbolTable symbolWithCString:"t"];
    }
    return Nu__null;
}

@end

@interface Nu_puts : NuOperator {}
@end

@implementation Nu_puts
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id console = [[symbolTable symbolWithCString:"$$console"] value];
    NSString *string;
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        id value = [[cursor car] evalWithContext:context];
        string = [value stringValue];
        if (console && (console != Nu__null)) {
            [console write:string];
            [console write:[NSString carriageReturn]];
        }
        else {
            printf("%s\n", [string cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        cursor = [cursor cdr];
    }
    return Nu__null;;
}

@end

@interface Nu_print : NuOperator {}
@end

@implementation Nu_print
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id console = [[symbolTable symbolWithCString:"$$console"] value];

    NSString *string;
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        string = [[[cursor car] evalWithContext:context] stringValue];
        if (console && (console != Nu__null)) {
            [console write:string];
        }
        else {
            printf("%s", [string cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        cursor = [cursor cdr];
    }
    return Nu__null;;
}

@end

@interface Nu_call : NuOperator {}
@end

@implementation Nu_call
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id function = [[cdr car] evalWithContext:context];
    id arguments = [cdr cdr];
    id value = [function callWithArguments:arguments context:context];
    return value;
}

@end

@interface Nu_send : NuOperator {}
@end

@implementation Nu_send
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id target = [[cdr car] evalWithContext:context];
    id message = [cdr cdr];
    id value = [target sendMessage:message withContext:context];
    return value;
}

@end

@interface Nu_progn : NuOperator {}
@end

@implementation Nu_progn
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id value = Nu__null;
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        value = [[cursor car] evalWithContext:context];
        cursor = [cursor cdr];
    }
    return value;
}

@end

@interface Nu_eval : NuOperator {}
@end

@implementation Nu_eval
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id value = [[[cdr car] evalWithContext:context] evalWithContext:context];
    return value;
}

@end

@interface Nu_load : NuOperator {}
@end

@implementation Nu_load
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id parser = [context objectForKey:[symbolTable symbolWithString:@"_parser"]];
    id resourceName = [[cdr car] evalWithContext:context];

    // does the resourceName contain a colon? if so, it's a framework:nu-source-file pair.
    id split = [resourceName componentsSeparatedByString:@":"];
    if ([split count] == 2) {
        id frameworkName = [split objectAtIndex:0];
        id nuFileName = [split objectAtIndex:1];

        NSBundle *framework = [NSBundle frameworkWithName:frameworkName];
        if ([framework loadNuFile:nuFileName withContext:context])
            return [symbolTable symbolWithCString:"t"];
        else {
            [NSException raise:@"NuLoadFailed" format:@"unable to load %@", resourceName];
            return nil;
        }
    }
    else {
        // begin by looking for a Nu_ source file in the current directory, first with and then without the ".nu" suffix
        id fileName = [NSString stringWithFormat:@"./%@.nu", resourceName];
        if (![NSFileManager fileExistsNamed: fileName]) {
            fileName = [NSString stringWithFormat:@"./%@", resourceName];
            if (![NSFileManager fileExistsNamed: fileName]) fileName = nil;
        }
        if (fileName) {
            NSString *string = [NSString stringWithContentsOfFile: fileName];
            id value = Nu__null;
            if (string) {
                id body = [parser parse: string];
                value = [body evalWithContext:context];
                return [symbolTable symbolWithCString:"t"];
            }
            else {
                [NSException raise:@"NuLoadFailed" format:@"unable to load %@", fileName];
                return nil;
            }
        }

        // if that failed, try to load the file the main application bundle
        if ([[NSBundle mainBundle] loadNuFile:resourceName withContext:context])
            return [symbolTable symbolWithCString:"t"];

        // or try the Nu_ bundle
        if ([[NSBundle bundleForClass:[self class]] loadNuFile:resourceName withContext:context])
            return [symbolTable symbolWithCString:"t"];

        // if no file was found, try to load a framework with the given name
        if ([NSBundle frameworkWithName:resourceName])
            return [symbolTable symbolWithCString:"t"];

        [NSException raise:@"NuLoadFailed" format:@"unable to load %@", resourceName];
        return nil;
    }
}

@end

@interface Nu_let : NuOperator {}
@end

@implementation Nu_let
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id arg_names = [[NuCell alloc] init];
    id arg_values = [[NuCell alloc] init];

    id cursor = [cdr car];
    if ([[cursor car] atom]) {
        [arg_names setCar:[cursor car]];
        [arg_values setCar:[[cursor cdr] car]];
    }
    else {
        id arg_name_cursor = arg_names;
        id arg_value_cursor = arg_values;
        while (cursor && (cursor != Nu__null)) {
            [arg_name_cursor setCar:[[cursor car] car]];
            [arg_value_cursor setCar:[[[cursor car] cdr] car]];
            cursor = [cursor cdr];
            if (cursor && (cursor != Nu__null)) {
                [arg_name_cursor setCdr:[[[NuCell alloc] init] autorelease]];
                [arg_value_cursor setCdr:[[[NuCell alloc] init] autorelease]];
                arg_name_cursor = [arg_name_cursor cdr];
                arg_value_cursor = [arg_value_cursor cdr];
            }
        }
    }

    id body = [cdr cdr];
    NuBlock *block = [[NuBlock alloc] initWithParameters:arg_names body:body context:context];
    id result = [block evalWithArguments:arg_values context:context];
    [arg_names release];
    [arg_values release];
    [block release];
    return result;
}

@end

@interface Nu_class : NuOperator {}
@end

@implementation Nu_class
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id className = [cdr car];
    id body = Nu__null;
    //NSLog(@"class name: %@", className);
    if ([cdr cdr]
        && ([cdr cdr] != Nu__null)
        && [[[cdr cdr] car] isEqual: [symbolTable symbolWithCString:"is"]]
    ) {
        id parentName = [[[cdr cdr] cdr] car];
        //NSLog(@"parent name: %@", [parentName stringValue]);
        Class parentClass = NSClassFromString([parentName stringValue]);
        if (!parentClass)
            [NSException raise:@"NuUndefinedSuperclass" format:@"undefined superclass %@", [parentName stringValue]];
        [parentClass createSubclassNamed:[className stringValue]];
        body = [[[cdr cdr] cdr] cdr];
    }
    else {
        body = [cdr cdr];
    }
    NuClass *childClass = [NuClass classWithName:[className stringValue]];
    if (!childClass)
        [NSException raise:@"NuUndefinedClass" format:@"undefined class %@", [className stringValue]];
    id result = nil;
    if (body && (body != Nu__null)) {
        NuBlock *block = [[NuBlock alloc] initWithParameters:Nu__null body:body context:context];
        [[block context]
            setObject:childClass
            forKey:[symbolTable symbolWithCString:"__class"]];
        result = [block evalWithArguments:Nu__null context:Nu__null];
        [block release];
    }
    return result;
}

@end

@interface Nu_cmethod : NuOperator {}
@end

@implementation Nu_cmethod
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    Class classToExtend = [[ context objectForKey:[symbolTable symbolWithCString:"__class"]] wrappedClass];
    if (classToExtend) classToExtend = classToExtend->isa;
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"class method declaration with no enclosing class declaration"];
    return help_add_method_to_class(classToExtend, cdr, context);
}

@end

@interface Nu_imethod : NuOperator {}
@end

@implementation Nu_imethod
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    Class classToExtend = [[ context objectForKey:[symbolTable symbolWithCString:"__class"]] wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"instance method declaration with no enclosing class declaration"];
    return help_add_method_to_class(classToExtend, cdr, context);
}

@end

@interface Nu_ivar : NuOperator {}
@end

@implementation Nu_ivar
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    Class classToExtend = [[context objectForKey:[symbolTable symbolWithCString:"__class"]] wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"instance variable declaration with no enclosing class declaration"];
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        id variableType = [cursor car];
        cursor = [cursor cdr];
        id variableName = [cursor car];
        cursor = [cursor cdr];
        NSString *signature = signature_for_identifier(variableType, symbolTable);
        [classToExtend addInstanceVariable:[variableName stringValue] signature:signature];
        //NSLog(@"adding ivar %@ with signature %@", [variableName stringValue], signature);
    }
    return Nu__null;
}

@end

@interface Nu_ivars : NuOperator {}
@end

@implementation Nu_ivars
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    Class classToExtend = [[context objectForKey:[symbolTable symbolWithCString:"__class"]] wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"dynamic instance variables declaration with no enclosing class declaration"];
    [classToExtend addInstanceVariable:@"__nuivars" signature:@"@"];
    return Nu__null;
}

@end

@interface Nu_beep : NuOperator {}
@end

@implementation Nu_beep
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NSBeep();
    return Nu__null;
}

@end

@interface Nu_system : NuOperator {}
@end

@implementation Nu_system
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id command = [[cdr car] evalWithContext:context];
    const char *commandString = [[command stringValue] cStringUsingEncoding:NSUTF8StringEncoding];
    return [NSNumber numberWithInt:system(commandString)];
}

@end

@interface Nu_help : NuOperator {}
@end

@implementation Nu_help

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id object = [[cdr car] evalWithContext:context];
    return [object help];
}

@end

@interface Nu_break : NuOperator {}
@end

@implementation Nu_break

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    @throw [[NuBreakException alloc] init];
    return nil;                                   // unreached
}

@end

@interface Nu_continue : NuOperator {}
@end

@implementation Nu_continue

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    @throw [[NuContinueException alloc] init];
    return nil;                                   // unreached
}

@end

@interface Nu_version : NuOperator {}
@end

@implementation Nu_version

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return [NSString stringWithFormat:@"Nu %s (%s)", NU_VERSION, NU_RELEASE_DATE];
}

@end

#import "class.h"

#define install(name, class) [[[symbolTable symbolWithCString:name] retain] setValue:[[class alloc] init]]

void load_builtins(NuSymbolTable *symbolTable)
{
    [[[symbolTable symbolWithCString:"t"] retain] setValue:[symbolTable symbolWithCString:"t"]];
    [[[symbolTable symbolWithCString:"nil"] retain] setValue:Nu__null];
    [[[symbolTable symbolWithCString:"NULL"] retain] setValue:[NuZero zero]];
    [[[symbolTable symbolWithCString:"ZERO"] retain] setValue:[NuZero zero]];

    install("car",      Nu_car);
    install("cdr",      Nu_cdr);
    install("head",     Nu_car);
    install("tail",     Nu_cdr);
    install("atom",     Nu_atom);

    install("eq",       Nu_eq);
    install("==",       Nu_eq);
    install("!=",       Nu_neq);

    install("cons",     Nu_cons);
    install("append",   Nu_append);

    install("cond",     Nu_cond);
    install("case",     Nu_case);
    install("if",       Nu_if);
    install("unless",   Nu_unless);
    install("while",    Nu_while);
    install("until",    Nu_until);
    install("for",      Nu_for);
    install("break",    Nu_break);
    install("continue", Nu_continue);

    install("try",      Nu_try);
    install("throw",    Nu_throw);
    install("synchronized", Nu_synchronized);

    install("quote",    Nu_quote);
    install("eval",     Nu_eval);

    install("context",  Nu_context);
    install("set",      Nu_set);
    install("global",   Nu_global);

    install("regex",    Nu_regex);

    install("def",      Nu_function);
    install("function", Nu_function);
    install("macro",    Nu_macro);
    install("progn",    Nu_progn);
    install("then",     Nu_progn);
    install("else",     Nu_progn);

    install("+",        Nu_add);
    install("-",        Nu_subtract);
    install("*",        Nu_multiply);
    install("/",        Nu_divide);
    install("&",        Nu_bitwiseand);
    install("|",        Nu_bitwiseor);
    install(">",        Nu_greaterthan);
    install("<",        Nu_lessthan);
    install(">=",       Nu_gte);
    install("<=",       Nu_lte);
    install("<<",       Nu_leftshift);
    install(">>",       Nu_rightshift);
    install("and",      Nu_and);
    install("or",       Nu_or);
    install("not",      Nu_not);

    install("list",     Nu_list);

    install("do",       Nu_do);

    install("puts",     Nu_puts);
    install("print",    Nu_print);

    //  install("label",    Nu_label);
    install("let",      Nu_let);

    install("load",     Nu_load);
    install("beep",     Nu_beep);
    install("system",   Nu_system);

    install("class",    Nu_class);
    install("imethod",  Nu_imethod);
    install("cmethod",  Nu_cmethod);
    install("ivar",     Nu_ivar);
    install("ivars",    Nu_ivars);

    install("call",     Nu_call);
    install("send",     Nu_send);

    install("help",     Nu_help);
    install("?",        Nu_help);
    install("version",  Nu_version);
}
