/*!
@file operator.m
@description Nu operators.
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
#import "nuinternals.h"
#import "operator.h"
#import "extensions.h"
#import "cell.h"
#import "bridge.h"
#import "symbol.h"
#import "block.h"
#import "macro.h"
#import "class.h"
#import "objc_runtime.h"
#import "object.h"
#import "parser.h"
#import "regex.h"
#import "version.h"
#import "Nu/Nu.h"
#ifndef IPHONE
#include <readline/readline.h>
#endif
#include <stdlib.h>

@implementation NuBreakException
- (id) init
{
    return [super initWithName:@"NuBreakException" reason:@"A break operator was evaluated" userInfo:nil];
}

@end

@implementation NuContinueException
- (id) init
{
    return [super initWithName:@"NuContinueException" reason:@"A continue operator was evaluated" userInfo:nil];
}

@end

@implementation NuReturnException
- (id) initWithValue:(id) v;
{
    [super initWithName:@"NuReturnException" reason:@"A return operator was evaluated" userInfo:nil];
    value = [v retain];
    return self; ;
}

- (void) dealloc
{
    [value release];
    [super dealloc];
}

- (id) value
{
    return value;
}

@end

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
        if (nu_valueIsTrue(test)) {
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
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context flipped:(bool)flip;
@end

@implementation Nu_if_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return [self callWithArguments:cdr context:context flipped:NO];
}

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context flipped:(bool)flip
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    //id thenSymbol = [symbolTable symbolWithCString:"then"];
    id elseSymbol = [symbolTable symbolWithCString:"else"];
    //id elseifSymbol = [symbolTable symbolWithCString:"elseif"];

    id result = Nu__null;
    id test = [[cdr car] evalWithContext:context];

    bool testIsTrue = flip ^ nu_valueIsTrue(test);
    bool noneIsTrue = !testIsTrue;

    id expressions = [cdr cdr];
    while (expressions && (expressions != Nu__null)) {
        id nextExpression = [expressions car];
        if (nu_objectIsKindOfClass(nextExpression, [NuCell class])) {
            /*if ([nextExpression car] == elseifSymbol) {
                test = [[[[expressions car] cdr] car] evalWithContext:context];
                testIsTrue = noneIsTrue && nu_valueIsTrue(test);
                noneIsTrue = noneIsTrue && !testIsTrue;
                if (testIsTrue)
                    // skip the test:
                    result = [[[nextExpression cdr] cdr] evalWithContext:context];
            }
            else */
            if ([nextExpression car] == elseSymbol) {
                if (noneIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
            else {
                if (testIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
        }
        else {
            /*if (nextExpression == elseifSymbol) {
                test = [[[expressions cdr] car] evalWithContext:context];
                testIsTrue = noneIsTrue && nu_valueIsTrue(test);
                noneIsTrue = noneIsTrue && !testIsTrue;
                expressions = [expressions cdr];            // skip the test
            }
            else */
            if (nextExpression == elseSymbol) {
                testIsTrue = noneIsTrue;
                noneIsTrue = NO;
            }
            else {
                if (testIsTrue)
                    result = [nextExpression evalWithContext:context];
            }
        }
        expressions = [expressions cdr];
    }
    return result;
}

@end

@interface Nu_unless_operator : Nu_if_operator {}
@end

@implementation Nu_unless_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return [super callWithArguments:cdr context:context flipped:YES];
}

@end

@interface Nu_while_operator : NuOperator {}
@end

@implementation Nu_while_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id result = Nu__null;
    id test = [[cdr car] evalWithContext:context];
    while (nu_valueIsTrue(test)) {
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
    while (!nu_valueIsTrue(test)) {
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
    while (nu_valueIsTrue(test)) {
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
    #ifdef DARWIN
    @try
        #else
        NS_DURING
        #endif
    {
        // evaluate all the expressions that are outside catch and finally blocks
        id expressions = cdr;
        while (expressions && (expressions != Nu__null)) {
            id nextExpression = [expressions car];
            if (nu_objectIsKindOfClass(nextExpression, [NuCell class])) {
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
    #ifdef DARWIN
    @catch (id thrownObject)
        #else
        NS_HANDLER
        #endif
    {
        #ifndef DARWIN
        id thrownObject = localException;
        #endif
        // evaluate all the expressions that are in catch blocks
        id expressions = cdr;
        while (expressions && (expressions != Nu__null)) {
            id nextExpression = [expressions car];
            if (nu_objectIsKindOfClass(nextExpression, [NuCell class])) {
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
    #ifdef DARWIN
    @finally
        #else
        NS_ENDHANDLER
        #endif
    {
        // evaluate all the expressions that are in finally blocks
        id expressions = cdr;
        while (expressions && (expressions != Nu__null)) {
            id nextExpression = [expressions car];
            if (nu_objectIsKindOfClass(nextExpression, [NuCell class])) {
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

#ifdef DARWIN
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
#endif

#ifdef DARWIN
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
#endif

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

    NuSymbol *symbol = [cdr car];
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
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id classSymbol = [symbolTable symbolWithCString:"_class"];
        id searchContext = context;
        while (searchContext) {
            if ([searchContext objectForKey:symbol]) {
                [searchContext setPossiblyNullObject:result forKey:symbol];
                return result;
            }
            else if ([searchContext objectForKey:classSymbol]) {
                break;
            }
            searchContext = [searchContext objectForKey:PARENT_KEY];
        }
        #endif
        [context setPossiblyNullObject:result forKey:symbol];
    }
    return result;
}

@end

@interface Nu_global_operator : NuOperator {}
@end

@implementation Nu_global_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{

    NuSymbol *symbol = [cdr car];
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
                                                  // this defines the function in the calling context
    [context setPossiblyNullObject:block forKey:symbol];
                                                  // this defines the function in the block context, which allows recursion
    [[block context] setPossiblyNullObject:block forKey:symbol];
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
    if (nu_objectIsKindOfClass(value, [NuBlock class])) {
        //NSLog(@"setting context[%@] = %@", symbol, value);
        [((NSMutableDictionary *)[value context]) setPossiblyNullObject:value forKey:symbol];
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
                                                  // this defines the function in the calling context
    [context setPossiblyNullObject:macro forKey:name];
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
        NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithCString:"_class"]];
        [classWrapper registerClass];
        Class classToExtend = [classWrapper wrappedClass];
        return help_add_method_to_class(classToExtend, cdr, context, YES);
    }
    // otherwise, it's an addition
    id firstArgument = [[cdr car] evalWithContext:context];
    if (nu_objectIsKindOfClass(firstArgument, [NSValue class])) {
        double sum = [firstArgument doubleValue];
        id cursor = [cdr cdr];
        while (cursor && (cursor != Nu__null)) {
            sum += [[[cursor car] evalWithContext:context] doubleValue];
            cursor = [cursor cdr];
        }
        return [NSNumber numberWithDouble:sum];
    }
    else {
        NSMutableString *result = [NSMutableString stringWithString:[firstArgument stringValue]];
        id cursor = [cdr cdr];
        while (cursor && (cursor != Nu__null)) {
            [result appendString:[[[cursor car] evalWithContext:context] stringValue]];
            cursor = [cursor cdr];
        }
        return result;
    }
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
        NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithCString:"_class"]];
        [classWrapper registerClass];
        Class classToExtend = [classWrapper wrappedClass];
        return help_add_method_to_class(classToExtend, cdr, context, NO);
    }
    // otherwise, it's a subtraction
    id cursor = cdr;
    double sum = [[[cursor car] evalWithContext:context] doubleValue];
    cursor = [cursor cdr];
    if (!cursor || (cursor == Nu__null)) {
        // if there is just one operand, negate it
        sum = -sum;
    }
    else {
        // otherwise, subtract all the remaining operands from the first one
        while (cursor && (cursor != Nu__null)) {
            sum -= [[[cursor car] evalWithContext:context] doubleValue];
            cursor = [cursor cdr];
        }
    }
    return [NSNumber numberWithDouble:sum];
}

@end

@interface Nu_exponentiation_operator : NuOperator {}
@end

@implementation Nu_exponentiation_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cursor = cdr;
    double result = [[[cursor car] evalWithContext:context] doubleValue];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        result = pow(result, [[[cursor car] evalWithContext:context] doubleValue]);
        cursor = [cursor cdr];
    }
    return [NSNumber numberWithDouble:result];
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

@interface Nu_modulus_operator : NuOperator {}
@end

@implementation Nu_modulus_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id cursor = cdr;
    int product = [[[cursor car] evalWithContext:context] intValue];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        product %= [[[cursor car] evalWithContext:context] intValue];
        cursor = [cursor cdr];
    }
    return [NSNumber numberWithInt:product];
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
    id cursor = cdr;
    id current = [[cursor car] evalWithContext:context];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        id next = [[cursor car] evalWithContext:context];
        NSComparisonResult result = [current compare:next];
        if (result != NSOrderedDescending)
            return Nu__null;
        current = next;
        cursor = [cursor cdr];
    }
    return [symbolTable symbolWithCString:"t"];
}

@end

@interface Nu_lessthan_operator : NuOperator {}
@end

@implementation Nu_lessthan_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id cursor = cdr;
    id current = [[cursor car] evalWithContext:context];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        id next = [[cursor car] evalWithContext:context];
        NSComparisonResult result = [current compare:next];
        if (result != NSOrderedAscending)
            return Nu__null;
        current = next;
        cursor = [cursor cdr];
    }
    return [symbolTable symbolWithCString:"t"];
}

@end

@interface Nu_gte_operator : NuOperator {}
@end

@implementation Nu_gte_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id cursor = cdr;
    id current = [[cursor car] evalWithContext:context];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        id next = [[cursor car] evalWithContext:context];
        NSComparisonResult result = [current compare:next];
        if (result == NSOrderedAscending)
            return Nu__null;
        current = next;
        cursor = [cursor cdr];
    }
    return [symbolTable symbolWithCString:"t"];
}

@end

@interface Nu_lte_operator : NuOperator {}
@end

@implementation Nu_lte_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id cursor = cdr;
    id current = [[cursor car] evalWithContext:context];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        id next = [[cursor car] evalWithContext:context];
        NSComparisonResult result = [current compare:next];
        if (result == NSOrderedDescending)
            return Nu__null;
        current = next;
        cursor = [cursor cdr];
    }
    return [symbolTable symbolWithCString:"t"];
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
        if (!nu_valueIsTrue(value))
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
        if (nu_valueIsTrue(value))
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
        return nu_valueIsTrue(value) ? Nu__null : [symbolTable symbolWithCString:"t"];
    }
    return Nu__null;
}

@end

@interface NuConsoleViewController : NSObject {}
- (void) write:(id) string;
@end

@interface Nu_puts_operator : NuOperator {}
@end

@implementation Nu_puts_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuConsoleViewController *console = [[symbolTable symbolWithCString:"$$console"] value];
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

#ifndef IPHONE
@interface Nu_gets_operator : NuOperator {}
@end

@implementation Nu_gets_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    char *input = readline("");
    NSString *result = [NSString stringWithUTF8String: input];
    return result;
}

@end
#endif

@interface Nu_print_operator : NuOperator {}
@end

@implementation Nu_print_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuConsoleViewController *console = [[symbolTable symbolWithCString:"$$console"] value];

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

#ifdef LINUX
id loadNuLibraryFile(NSString *nuFileName, id parser, id context, id symbolTable)
{
    NSString *fullPath = [NSString stringWithFormat:@"/usr/local/share/libNu/nu/%@.nu", nuFileName];
    if ([NSFileManager fileExistsNamed:fullPath]) {
        NSString *string = [NSString stringWithContentsOfFile:fullPath];
        id value = Nu__null;
        if (string) {
            id body = [parser parse:string asIfFromFilename:[fullPath cStringUsingEncoding:NSUTF8StringEncoding]];
            value = [body evalWithContext:context];
            return [symbolTable symbolWithCString:"t"];
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}
#endif

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
        #ifdef LINUX
        if ([frameworkName isEqual:@"Nu"]) {
            if (loadNuLibraryFile(nuFileName, parser, context, symbolTable) == nil) {
                [NSException raise:@"NuLoadFailed" format:@"unable to load %@", nuFileName];
            }
            else {
                return [symbolTable symbolWithCString:"t"];
            }
        }
        #endif
        NSBundle *framework = [NSBundle frameworkWithName:frameworkName];
        if ([framework loadNuFile:nuFileName withContext:context])
            return [symbolTable symbolWithCString:"t"];
        else {
            [NSException raise:@"NuLoadFailed" format:@"unable to load %@", resourceName];
            return nil;
        }
    }
    else {
        // first try to find a file at the specified path
        id fileName = [resourceName stringByExpandingTildeInPath];
        if (![NSFileManager fileExistsNamed:fileName]) {
            // if that failed, try looking for a Nu_ source file in the current directory,
            // first with and then without the ".nu" suffix
            fileName = [NSString stringWithFormat:@"./%@.nu", resourceName];
            if (![NSFileManager fileExistsNamed: fileName]) {
                fileName = [NSString stringWithFormat:@"./%@", resourceName];
                if (![NSFileManager fileExistsNamed: fileName]) fileName = nil;
            }
        }
        if (fileName) {
            NSString *string = [NSString stringWithContentsOfFile: fileName];
            id value = Nu__null;
            if (string) {
                id body = [parser parse:string asIfFromFilename:[fileName cStringUsingEncoding:NSUTF8StringEncoding]];
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

        // next, try the main Nu bundle
        if ([Nu loadNuFile:resourceName fromBundleWithIdentifier:@"nu.programming.framework" withContext:context])
            return [symbolTable symbolWithCString:"t"];

        #ifdef LINUX
        if (loadNuLibraryFile(resourceName, parser, context, symbolTable))
            return [symbolTable symbolWithCString:"t"];
        #endif

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
    if ((cursor != [NSNull null]) && [[cursor car] atom]) {
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    id body = [cdr cdr];
    NuBlock *block = [[NuBlock alloc] initWithParameters:arg_names body:body context:context];
    id result = [[block evalWithArguments:arg_values context:context] retain];
    [arg_names release];
    [arg_values release];
    [block release];
    [pool release];
    [result autorelease];
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
    #if defined(__x86_64__) || defined(IPHONE)
    Class newClass = nil;
    #endif
    NuClass *childClass;
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

        #if defined(__x86_64__) || defined(IPHONE)
        newClass = objc_allocateClassPair(parentClass, [[className stringValue] cStringUsingEncoding:NSUTF8StringEncoding], 0);
        childClass = [NuClass classWithClass:newClass];
        [childClass setRegistered:NO];
        //NSLog(@"created class %@", [childClass name]);
        // it seems dangerous to call this here. Maybe it's better to wait until the new class is registered.
        if ([parentClass respondsToSelector:@selector(inheritedByClass:)]) {
            [parentClass inheritedByClass:childClass];
        }
        #else
        [parentClass createSubclassNamed:[className stringValue]];
        childClass = [NuClass classWithName:[className stringValue]];
        #endif
        body = [[[cdr cdr] cdr] cdr];
    }
    else {
        childClass = [NuClass classWithName:[className stringValue]];
        body = [cdr cdr];
    }
    if (!childClass)
        [NSException raise:@"NuUndefinedClass" format:@"undefined class %@", [className stringValue]];
    id result = nil;
    if (body && (body != Nu__null)) {
        NuBlock *block = [[NuBlock alloc] initWithParameters:Nu__null body:body context:context];
        [[block context]
            setPossiblyNullObject:childClass
            forKey:[symbolTable symbolWithCString:"_class"]];
        result = [block evalWithArguments:Nu__null context:Nu__null];
        [block release];
    }
    #if defined(__x86_64__) || defined(IPHONE)
    if (newClass && ([childClass isRegistered] == NO)) {
        [childClass registerClass];
    }
    #endif
    return result;
}

@end

@interface Nu_cmethod_operator : NuOperator {}
@end

@implementation Nu_cmethod_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithCString:"_class"]];
    [classWrapper registerClass];
    Class classToExtend = [classWrapper wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"class method declaration with no enclosing class declaration"];
    return help_add_method_to_class(classToExtend, cdr, context, YES);
}

@end

@interface Nu_imethod_operator : NuOperator {}
@end

@implementation Nu_imethod_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithCString:"_class"]];
    [classWrapper registerClass];
    Class classToExtend = [classWrapper wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"instance method declaration with no enclosing class declaration"];
    return help_add_method_to_class(classToExtend, cdr, context, NO);
}

@end

@interface Nu_ivar_operator : NuOperator {}
@end

@implementation Nu_ivar_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithCString:"_class"]];
    #if defined(__x86_64__) || defined(IPHONE)
    // this will only work if the class is unregistered...
    if ([classWrapper isRegistered]) {
        [NSException raise:@"NuIvarAddedTooLate" format:@"instance variables must be added when a class is created and before any method declarations"];
    }
    #endif
    Class classToExtend = [classWrapper wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"instance variable declaration with no enclosing class declaration"];
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        id variableType = [cursor car];
        cursor = [cursor cdr];
        id variableName = [cursor car];
        cursor = [cursor cdr];
        NSString *signature = signature_for_identifier(variableType, symbolTable);
        class_addInstanceVariable_withSignature(classToExtend,
            [[variableName stringValue] cStringUsingEncoding:NSUTF8StringEncoding],
            [signature cStringUsingEncoding:NSUTF8StringEncoding]);
        if ([signature isEqual:@"@"]) {
            //nu_registerIvarForRelease(classToExtend, [variableName stringValue]);
        }
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

    NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithCString:"_class"]];
    #if defined(__x86_64__) || defined(IPHONE)
    // this will only work if the class is unregistered...
    if ([classWrapper isRegistered]) {
        [NSException raise:@"NuIvarAddedTooLate" format:@"instance variables must be added when a class is created and before any method declarations"];
    }
    #endif
    Class classToExtend = [classWrapper wrappedClass];
    if (!classToExtend)
        [NSException raise:@"NuMisplacedDeclaration" format:@"dynamic instance variables declaration with no enclosing class declaration"];
    class_addInstanceVariable_withSignature(classToExtend, "__nuivars", "@");
    nu_registerIvarForRelease(classToExtend, @"__nuivars");
    return Nu__null;
}

@end

@interface Nu_ivar_accessors_operator : NuOperator {}
@end

@implementation Nu_ivar_accessors_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithCString:"_class"]];
    [classWrapper registerClass];
    Class classToExtend = [classWrapper wrappedClass];
    [classToExtend include:[NuClass classWithClass:[NuAutomaticIvars class]]];
    return Nu__null;
}

@end

#if defined(DARWIN) && !defined(IPHONE)
#import <Cocoa/Cocoa.h>

@interface Nu_beep_operator : NuOperator {}
@end

@implementation Nu_beep_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NSBeep();
    return Nu__null;
}

@end
#endif

@interface Nu_system_operator : NuOperator {}
@end

@implementation Nu_system_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id command = [[cdr car] evalWithContext:context];
    const char *commandString = [[command stringValue] cStringUsingEncoding:NSUTF8StringEncoding];
    int result = system(commandString) >> 8;      // this needs an explanation
    return [NSNumber numberWithInt:result];
}

@end

@interface Nu_uname_operator : NuOperator {}
@end

@implementation Nu_uname_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    #if defined DARWIN
    return @"Darwin";
    #elif defined LINUX
    return @"Linux";
    #else
    return @"Unknown";
    #endif
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
    @throw [[[NuBreakException alloc] init] autorelease];
    return nil;                                   // unreached
}

@end

@interface Nu_continue_operator : NuOperator {}
@end

@implementation Nu_continue_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    @throw [[[NuContinueException alloc] init] autorelease];
    return nil;                                   // unreached
}

@end

@interface Nu_return_operator : NuOperator {}
@end

@implementation Nu_return_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id value = nil;
    if (cdr && cdr != Nu__null) {
        value = [[cdr car] evalWithContext:context];
    }
    @throw [[[NuReturnException alloc] initWithValue:value] autorelease];
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

@interface Nu_min_operator : NuOperator {}
@end

@implementation Nu_min_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    if (cdr == Nu__null)
        [NSException raise: @"NuArityError" format:@"min expects at least 1 argument, got 0"];
    id smallest = [[cdr car] evalWithContext:context];
    id cursor = [cdr cdr];
    while (cursor && (cursor != Nu__null)) {
        id nextValue = [[cursor car] evalWithContext:context];
        if([smallest compare:nextValue] == 1) {
            smallest = nextValue;
        }
        cursor = [cursor cdr];
    }
    return smallest;
}

@end

@interface Nu_max_operator : NuOperator {}
@end

@implementation Nu_max_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    if (cdr == Nu__null)
        [NSException raise: @"NuArityError" format:@"max expects at least 1 argument, got 0"];
    id biggest = [[cdr car] evalWithContext:context];
    id cursor = [cdr cdr];
    while (cursor && (cursor != Nu__null)) {
        id nextValue = [[cursor car] evalWithContext:context];
        if([biggest compare:nextValue] == -1) {
            biggest = nextValue;
        }
        cursor = [cursor cdr];
    }
    return biggest;
}

@end

id evaluatedArguments(id cdr, NSMutableDictionary *context)
{
    NuCell *evaluatedArguments = nil;
    id cursor = cdr;
    id outCursor = nil;
    while (cursor && (cursor != Nu__null)) {
        id nextValue = [[cursor car] evalWithContext:context];
        id newCell = [[[NuCell alloc] init] autorelease];
        [newCell setCar:nextValue];
        if (!outCursor) {
            evaluatedArguments = newCell;
        }
        else {
            [outCursor setCdr:newCell];
        }
        outCursor = newCell;
        cursor = [cursor cdr];
    }
    return evaluatedArguments;
}

@interface Nu_array_operator : NuOperator {}
@end

@implementation Nu_array_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return [NSArray arrayWithList:evaluatedArguments(cdr, context)];
}

@end

@interface Nu_dict_operator : NuOperator {}
@end

@implementation Nu_dict_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return [NSDictionary dictionaryWithList:evaluatedArguments(cdr, context)];
}

@end

@interface Nu_parse_operator : NuOperator {}
@end

@implementation Nu_parse_operator

// parse operator; parses a string into Nu code objects
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id parser = [[[NuParser alloc] init] autorelease];
    return [parser parse:[[cdr car] evalWithContext:context]];
}

@end

#define install(name, class) [(NuSymbol *) [[symbolTable symbolWithCString:name] retain] setValue:[[class alloc] init]]

void load_builtins(NuSymbolTable *symbolTable)
{
    [(NuSymbol *) [[symbolTable symbolWithCString:"t"] retain] setValue:[symbolTable symbolWithCString:"t"]];
    [(NuSymbol *) [[symbolTable symbolWithCString:"nil"] retain] setValue:Nu__null];
    [(NuSymbol *) [[symbolTable symbolWithCString:"YES"] retain] setValue:[NSNumber numberWithInt:1]];
    [(NuSymbol *) [[symbolTable symbolWithCString:"NO"] retain] setValue:[NSNumber numberWithInt:0]];

    install("car",      Nu_car_operator);
    install("cdr",      Nu_cdr_operator);
    install("first",    Nu_car_operator);
    install("rest",     Nu_cdr_operator);
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
    install("return",   Nu_return_operator);

    install("try",      Nu_try_operator);
    #ifdef DARWIN
    install("throw",    Nu_throw_operator);
    install("synchronized", Nu_synchronized_operator);
    #endif

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
    install("**",       Nu_exponentiation_operator);
    install("%",        Nu_modulus_operator);
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

    install("min",      Nu_min_operator);
    install("max",      Nu_max_operator);

    install("list",     Nu_list_operator);

    install("do",       Nu_do_operator);

    #ifndef IPHONE
    install("gets",     Nu_gets_operator);
    #endif
    install("puts",     Nu_puts_operator);
    install("print",    Nu_print_operator);

    //  install("label",    Nu_label_operator);
    install("let",      Nu_let_operator);

    install("load",     Nu_load_operator);
    #if defined(DARWIN) && !defined(IPHONE)
    install("beep",     Nu_beep_operator);
    #endif

    install("uname",    Nu_uname_operator);
    install("system",   Nu_system_operator);

    install("class",    Nu_class_operator);
    install("imethod",  Nu_imethod_operator);
    install("cmethod",  Nu_cmethod_operator);
    install("ivar",     Nu_ivar_operator);
    install("ivars",    Nu_ivars_operator);
    install("ivar-accessors", Nu_ivar_accessors_operator);

    install("call",     Nu_call_operator);
    install("send",     Nu_send_operator);

    install("array",    Nu_array_operator);
    install("dict",     Nu_dict_operator);
    install("parse",    Nu_parse_operator);

    install("help",     Nu_help_operator);
    install("?",        Nu_help_operator);
    install("version",  Nu_version_operator);
}
