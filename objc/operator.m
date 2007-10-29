// operator.m
//  Nu operators.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "nuinternals.h"
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
#include <stdlib.h>

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
        if ([value doubleValue] == 0.0)
            result = false;
    }
    return result;
}

@implementation NuOperator : NSObject
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context {return nil;}
- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context {return [self callWithArguments:cdr context:context];}
@end

@interface Nu_car_operator : NuOperator {}
@end

@implementation Nu_car_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    id value = [cadr evalWithContext:context];
    return ([value respondsToSelector:@selector(car)]) ? [value car] : Nu__null;
}

@end

@interface Nu_cdr_operator : NuOperator {}
@end

@implementation Nu_cdr_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    id value = [cadr evalWithContext:context];
    return ([value respondsToSelector:@selector(cdr)]) ? [value cdr] : Nu__null;
}

@end

@interface Nu_atom_operator : NuOperator {}
@end

@implementation Nu_atom_operator

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

@interface Nu_eq_operator : NuOperator {}
@end

@implementation Nu_eq_operator
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

@interface Nu_neq_operator : NuOperator {}
@end

@implementation Nu_neq_operator
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

@interface Nu_cons_operator : NuOperator {}
@end

@implementation Nu_cons_operator
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

@interface Nu_append_operator : NuOperator {}
@end

@implementation Nu_append_operator
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

@interface Nu_cond_operator : NuOperator {}
@end

@implementation Nu_cond_operator
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

@interface Nu_case_operator : NuOperator {}
@end

@implementation Nu_case_operator
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

@interface Nu_if_operator : NuOperator {}
@end

@implementation Nu_if_operator
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

@interface Nu_unless_operator : NuOperator {}
@end

@implementation Nu_unless_operator
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

@interface Nu_while_operator : NuOperator {}
@end

@implementation Nu_while_operator
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

@interface Nu_until_operator : NuOperator {}
@end

@implementation Nu_until_operator
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

@interface Nu_for_operator : NuOperator {}
@end

@implementation Nu_for_operator
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

@interface Nu_try_operator : NuOperator {}
@end

@implementation Nu_try_operator
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

@interface Nu_throw_operator : NuOperator {}
@end

@implementation Nu_throw_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id exception = [[cdr car] evalWithContext:context];
    @throw exception;
    return exception;
}

@end

@interface Nu_synchronized_operator : NuOperator {}
@end

@implementation Nu_synchronized_operator
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

@interface Nu_quote_operator : NuOperator {}
@end

@implementation Nu_quote_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cadr = [cdr car];
    return cadr;
}

@end

@interface Nu_context_operator : NuOperator {}
@end

@implementation Nu_context_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return context;
}

@end

@interface Nu_set_operator : NuOperator {}
@end

@implementation Nu_set_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{

    id symbol = [cdr car];
    id value = [[cdr cdr] car];
    id result = [value evalWithContext:context];

    char c = (char) [[symbol stringValue] characterAtIndex:0];
    if (c == '$') {
        [symbol setValue:result];
    }
    else if (c == '@') {
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id object = [context lookupObjectForKey:[symbolTable symbolWithCString:"self"]];
        id ivar = [[symbol stringValue] substringFromIndex:1];
        //NSLog(@"setting value for ivar %@ to %@", ivar, result);
        [object setValue:result forIvar:ivar];
    }
    else {
        #ifndef CLOSE_ON_VALUES
        id searchContext = context;
        while (searchContext) {
            if ([searchContext objectForKey:symbol]) {
                [searchContext setObject:result forKey:symbol];
                return result;
            }
            searchContext = [searchContext objectForKey:PARENT_KEY];
        }
        #endif
        [context setObject:result forKey:symbol];
    }
    return result;
}

@end

@interface Nu_global_operator : NuOperator {}
@end

@implementation Nu_global_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{

    id symbol = [cdr car];
    id value = [[cdr cdr] car];
    id result = [value evalWithContext:context];
    [symbol setValue:result];
    return result;
}

@end

@interface Nu_regex_operator : NuOperator {}
@end

@implementation Nu_regex_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id value = [cdr car];
    value = [value evalWithContext:context];
    return [NuRegex regexWithPattern:value];
}

@end

@interface Nu_do_operator : NuOperator {}
@end

@implementation Nu_do_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id args = [cdr car];
    id body = [cdr cdr];
    NuBlock *block = [[[NuBlock alloc] initWithParameters:args body:body context:context] autorelease];
    return block;
}

@end

@interface Nu_function_operator : NuOperator {}
@end

@implementation Nu_function_operator
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

@interface Nu_label_operator : NuOperator {}
@end

@implementation Nu_label_operator
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

@interface Nu_macro_operator : NuOperator {}
@end

@implementation Nu_macro_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id name = [cdr car];
    id body = [cdr cdr];

    NuMacro *macro = [[NuMacro alloc] initWithName:name body:body];
    [context setObject:macro forKey:name];        // this defines the function in the calling context
    return macro;
}

@end

@interface Nu_list_operator : NuOperator {}
@end

@implementation Nu_list_operator
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

@interface Nu_add_operator : NuOperator {}
@end

@implementation Nu_add_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if ([context objectForKey:[symbolTable symbolWithCString:"_class"]] && ![context objectForKey:[symbolTable symbolWithCString:"_method"]]) {
        // we are inside a class declaration and outside a method declaration.
        // treat this as a "cmethod" call
        Class classToExtend = [[ context objectForKey:[symbolTable symbolWithCString:"_class"]] wrappedClass]->isa;
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

@interface Nu_multiply_operator : NuOperator {}
@end

@implementation Nu_multiply_operator
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

@interface Nu_subtract_operator : NuOperator {}
@end

@implementation Nu_subtract_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if ([context objectForKey:[symbolTable symbolWithCString:"_class"]] && ![context objectForKey:[symbolTable symbolWithCString:"_method"]]) {
        // we are inside a class declaration and outside a method declaration.
        // treat this as an "imethod" call
        Class classToExtend = [[ context objectForKey:[symbolTable symbolWithCString:"_class"]] wrappedClass];
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

@interface Nu_divide_operator : NuOperator {}
@end

@implementation Nu_divide_operator
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

@interface Nu_bitwiseand_operator : NuOperator {}
@end

@implementation Nu_bitwiseand_operator
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

@interface Nu_bitwiseor_operator : NuOperator {}
@end

@implementation Nu_bitwiseor_operator
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

@interface Nu_greaterthan_operator : NuOperator {}
@end

@implementation Nu_greaterthan_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    double first = [[[cdr car] evalWithContext:context] doubleValue];
    double second = [[[[cdr cdr] car] evalWithContext:context] doubleValue];
    return (first > second) ? [symbolTable symbolWithCString:"t"] : Nu__null;
}

@end

@interface Nu_lessthan_operator : NuOperator {}
@end

@implementation Nu_lessthan_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    double first = [[[cdr car] evalWithContext:context] doubleValue];
    double second = [[[[cdr cdr] car] evalWithContext:context] doubleValue];
    return (first < second) ? [symbolTable symbolWithCString:"t"] : Nu__null;
}

@end

@interface Nu_gte_operator : NuOperator {}
@end

@implementation Nu_gte_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    double first = [[[cdr car] evalWithContext:context] doubleValue];
    double second = [[[[cdr cdr] car] evalWithContext:context] doubleValue];
    return (first >= second) ? [symbolTable symbolWithCString:"t"] : Nu__null;
}

@end

@interface Nu_lte_operator : NuOperator {}
@end

@implementation Nu_lte_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    double first = [[[cdr car] evalWithContext:context] doubleValue];
    double second = [[[[cdr cdr] car] evalWithContext:context] doubleValue];
    return (first <= second) ? [symbolTable symbolWithCString:"t"] : Nu__null;
}

@end

@interface Nu_leftshift_operator : NuOperator {}
@end

@implementation Nu_leftshift_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    long result = [[[cdr car] evalWithContext:context] longValue];
    result = result << [[[[cdr cdr] car] evalWithContext:context] longValue];
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_rightshift_operator : NuOperator {}
@end

@implementation Nu_rightshift_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    long result = [[[cdr car] evalWithContext:context] longValue];
    result = result >> [[[[cdr cdr] car] evalWithContext:context] longValue];
    return [NSNumber numberWithLong:result];
}

@end

@interface Nu_and_operator : NuOperator {}
@end

@implementation Nu_and_operator
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

@interface Nu_or_operator : NuOperator {}
@end

@implementation Nu_or_operator
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

@interface Nu_not_operator : NuOperator {}
@end

@implementation Nu_not_operator
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

@interface Nu_puts_operator : NuOperator {}
@end

@implementation Nu_puts_operator
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

@interface Nu_print_operator : NuOperator {}
@end

@implementation Nu_print_operator
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

@interface Nu_call_operator : NuOperator {}
@end

@implementation Nu_call_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id function = [[cdr car] evalWithContext:context];
    id arguments = [cdr cdr];
    id value = [function callWithArguments:arguments context:context];
    return value;
}

@end

@interface Nu_send_operator : NuOperator {}
@end

@implementation Nu_send_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id target = [[cdr car] evalWithContext:context];
    id message = [cdr cdr];
    id value = [target sendMessage:message withContext:context];
    return value;
}

@end

@interface Nu_progn_operator : NuOperator {}
@end

@implementation Nu_progn_operator
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

@interface Nu_eval_operator : NuOperator {}
@end

@implementation Nu_eval_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id value = [[[cdr car] evalWithContext:context] evalWithContext:context];
    return value;
}

@end

@interface Nu_load_operator : NuOperator {}
@end

@implementation Nu_load_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id parser = [context lookupObjectForKey:[symbolTable symbolWithString:@"_parser"]];
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

@interface Nu_let_operator : NuOperator {}
@end

@implementation Nu_let_operator
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

@interface Nu_class_operator : NuOperator {}
@end

@implementation Nu_class_operator
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
            forKey:[symbolTable symbolWithCString:"_class"]];
        result = [block evalWithArguments:Nu__null context:Nu__null];
        [block release];
    }
    return result;
}

@end

@interface Nu_cmethod_operator : NuOperator {}
@end

@implementation Nu_cmethod_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    Class classToExtend = [[context objectForKey:[symbolTable symbolWithCString:"_class"]] wrappedClass];
    if (classToExtend) classToExtend = classToExtend->isa;
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"class method declaration with no enclosing class declaration"];
    return help_add_method_to_class(classToExtend, cdr, context);
}

@end

@interface Nu_imethod_operator : NuOperator {}
@end

@implementation Nu_imethod_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    Class classToExtend = [[context objectForKey:[symbolTable symbolWithCString:"_class"]] wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"instance method declaration with no enclosing class declaration"];
    return help_add_method_to_class(classToExtend, cdr, context);
}

@end

@interface Nu_ivar_operator : NuOperator {}
@end

@implementation Nu_ivar_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    Class classToExtend = [[context lookupObjectForKey:[symbolTable symbolWithCString:"_class"]] wrappedClass];
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

@interface Nu_ivars_operator : NuOperator {}
@end

@implementation Nu_ivars_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    Class classToExtend = [[context lookupObjectForKey:[symbolTable symbolWithCString:"_class"]] wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"dynamic instance variables declaration with no enclosing class declaration"];
    [classToExtend addInstanceVariable:@"__nuivars" signature:@"@"];
    return Nu__null;
}

@end

@interface Nu_beep_operator : NuOperator {}
@end

@implementation Nu_beep_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NSBeep();
    return Nu__null;
}

@end

@interface Nu_system_operator : NuOperator {}
@end

@implementation Nu_system_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id command = [[cdr car] evalWithContext:context];
    const char *commandString = [[command stringValue] cStringUsingEncoding:NSUTF8StringEncoding];
    int result = system(commandString) >> 8; // this needs an explanation
    return [NSNumber numberWithInt:result];
}

@end

@interface Nu_help_operator : NuOperator {}
@end

@implementation Nu_help_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id object = [[cdr car] evalWithContext:context];
    return [object help];
}

@end

@interface Nu_break_operator : NuOperator {}
@end

@implementation Nu_break_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    @throw [[NuBreakException alloc] init];
    return nil;                                   // unreached
}

@end

@interface Nu_continue_operator : NuOperator {}
@end

@implementation Nu_continue_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    @throw [[NuContinueException alloc] init];
    return nil;                                   // unreached
}

@end

@interface Nu_version_operator : NuOperator {}
@end

@implementation Nu_version_operator

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

    install("car",      Nu_car_operator);
    install("cdr",      Nu_cdr_operator);
    install("head",     Nu_car_operator);
    install("tail",     Nu_cdr_operator);
    install("atom",     Nu_atom_operator);

    install("eq",       Nu_eq_operator);
    install("==",       Nu_eq_operator);
    install("!=",       Nu_neq_operator);

    install("cons",     Nu_cons_operator);
    install("append",   Nu_append_operator);

    install("cond",     Nu_cond_operator);
    install("case",     Nu_case_operator);
    install("if",       Nu_if_operator);
    install("unless",   Nu_unless_operator);
    install("while",    Nu_while_operator);
    install("until",    Nu_until_operator);
    install("for",      Nu_for_operator);
    install("break",    Nu_break_operator);
    install("continue", Nu_continue_operator);

    install("try",      Nu_try_operator);
    install("throw",    Nu_throw_operator);
    install("synchronized", Nu_synchronized_operator);

    install("quote",    Nu_quote_operator);
    install("eval",     Nu_eval_operator);

    install("context",  Nu_context_operator);
    install("set",      Nu_set_operator);
    install("global",   Nu_global_operator);

    install("regex",    Nu_regex_operator);

    install("def",      Nu_function_operator);
    install("function", Nu_function_operator);
    install("macro",    Nu_macro_operator);
    install("progn",    Nu_progn_operator);
    install("then",     Nu_progn_operator);
    install("else",     Nu_progn_operator);

    install("+",        Nu_add_operator);
    install("-",        Nu_subtract_operator);
    install("*",        Nu_multiply_operator);
    install("/",        Nu_divide_operator);
    install("&",        Nu_bitwiseand_operator);
    install("|",        Nu_bitwiseor_operator);
    install(">",        Nu_greaterthan_operator);
    install("<",        Nu_lessthan_operator);
    install(">=",       Nu_gte_operator);
    install("<=",       Nu_lte_operator);
    install("<<",       Nu_leftshift_operator);
    install(">>",       Nu_rightshift_operator);
    install("and",      Nu_and_operator);
    install("or",       Nu_or_operator);
    install("not",      Nu_not_operator);

    install("list",     Nu_list_operator);

    install("do",       Nu_do_operator);

    install("puts",     Nu_puts_operator);
    install("print",    Nu_print_operator);

    //  install("label",    Nu_label_operator);
    install("let",      Nu_let_operator);

    install("load",     Nu_load_operator);
    install("beep",     Nu_beep_operator);
    install("system",   Nu_system_operator);

    install("class",    Nu_class_operator);
    install("imethod",  Nu_imethod_operator);
    install("cmethod",  Nu_cmethod_operator);
    install("ivar",     Nu_ivar_operator);
    install("ivars",    Nu_ivars_operator);

    install("call",     Nu_call_operator);
    install("send",     Nu_send_operator);

    install("help",     Nu_help_operator);
    install("?",        Nu_help_operator);
    install("version",  Nu_version_operator);
}
