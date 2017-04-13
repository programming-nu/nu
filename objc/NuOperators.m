//
//  NuOperators.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuOperators.h"
#import "NuInternals.h"
#import "NuRegex.h"
#import "NuMacro.h"
#import "NSBundle+Nu.h"
#import "NSDictionary+Nu.h"
#import "NSFileManager+Nu.h"
#import "NSArray+Nu.h"
#import "NuBridge.h"
#import "NuBridgedFunction.h"
#import "NuClass.h"
#include <readline/readline.h>
#import "NSString+Nu.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif


#pragma mark - NuOperator.m

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
- (id) initWithValue:(id) v
{
    if ((self = [super initWithName:@"NuReturnException" reason:@"A return operator was evaluated" userInfo:nil])) {
        value = [v retain];
        blockForReturn = nil;
    }
    return self;
}

- (id) initWithValue:(id) v blockForReturn:(id) b
{
    if ((self = [super initWithName:@"NuReturnException" reason:@"A return operator was evaluated" userInfo:nil])) {
        value = [v retain];
        blockForReturn = b;                           // weak reference
    }
    return self;
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

- (id) blockForReturn
{
    return blockForReturn;
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
        return [symbolTable symbolWithString:@"t"];
    else
        return Nu__null;
}

@end

@interface Nu_defined_operator : NuOperator {}
@end

@implementation Nu_defined_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    bool is_defined = YES;
    id cadr = [cdr car];
    @try
    {
        [cadr evalWithContext:context];
    }
    @catch (id exception) {
        // is this an undefined symbol exception? if not, throw it
        if ([[exception name] isEqualToString:@"NuUndefinedSymbol"]) {
            is_defined = NO;
        }
        else {
            @throw(exception);
        }
    }
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if (is_defined)
        return [symbolTable symbolWithString:@"t"];
    else
        return Nu__null;
}

@end

@interface Nu_eq_operator : NuOperator {}
@end

@implementation Nu_eq_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id cursor = cdr;
    id current = [[cursor car] evalWithContext:context];
    cursor = [cursor cdr];
    while (cursor && (cursor != Nu__null)) {
        id next = [[cursor car] evalWithContext: context];
        if (![current isEqual:next])
            return Nu__null;
        current = next;
        cursor = [cursor cdr];
    }
    return [symbolTable symbolWithString:@"t"];
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
        return [symbolTable symbolWithString:@"t"];
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


@interface Nu_apply_operator : NuOperator {}
@end

@implementation Nu_apply_operator
- (id) prependCell:(id)item withSymbol:(id)symbol
{
    id qitem = [[[NuCell alloc] init] autorelease];
    [qitem setCar:symbol];
    [qitem setCdr:[[[NuCell alloc] init] autorelease]];
    [[qitem cdr] setCar:item];
    return qitem;
}

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id quoteSymbol = [symbolTable symbolWithString:@"quote"];
    
    id fn = [cdr car];
    
    // Arguments to fn can be anything, but last item must be a list
    id qargs = Nu__null;
    id qargs_cursor = Nu__null;
    id cursor = [cdr cdr];
    
    while (cursor && (cursor != Nu__null) && [cursor cdr] && ([cursor cdr] != Nu__null)) {
        if (qargs == Nu__null) {
            qargs = [[[NuCell alloc] init] autorelease];
            qargs_cursor = qargs;
        }
        else {
            [qargs_cursor setCdr:[[[NuCell alloc] init] autorelease]];
            qargs_cursor = [qargs_cursor cdr];
        }
        
        id item = [[cursor car] evalWithContext:context];
        id qitem = [self prependCell:item withSymbol:quoteSymbol];
        [qargs_cursor setCar:qitem];
        cursor = [cursor cdr];
    }
    
    // The rest of the arguments are in a list
    id args = [cursor evalWithContext:context];
    cursor = args;
    
    while (cursor && (cursor != Nu__null)) {
        if (qargs == Nu__null) {
            qargs = [[[NuCell alloc] init] autorelease];
            qargs_cursor = qargs;
        }
        else {
            [qargs_cursor setCdr:[[[NuCell alloc] init] autorelease]];
            qargs_cursor = [qargs_cursor cdr];
        }
        id item = [cursor car];
        
        id qitem = [self prependCell:item withSymbol:quoteSymbol];
        [qargs_cursor setCar:qitem];
        cursor = [cursor cdr];
    }
    
    // Call the real function with the evaluated and quoted args
    id expr = [[[NuCell alloc] init] autorelease];
    [expr setCar:fn];
    [expr setCdr:qargs];
    
    id result = [expr evalWithContext:context];
    
    return result;
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
    //id thenSymbol = [symbolTable symbolWithString:@"then"];
    id elseSymbol = [symbolTable symbolWithString:@"else"];
    //id elseifSymbol = [symbolTable symbolWithString:@"elseif"];
    
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
    id catchSymbol = [symbolTable symbolWithString:@"catch"];
    id finallySymbol = [symbolTable symbolWithString:@"finally"];
    id result = Nu__null;
    
    @try
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
    @catch (id thrownObject) {
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
    @finally
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

@interface Nu_quasiquote_eval_operator : NuOperator {}
@end

@implementation Nu_quasiquote_eval_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    // bqcomma is handled by Nu_quasiquote_operator.
    // If we get here, it means someone called bq_comma
    // outside of a backquote
    [NSException raise:@"NuQuasiquoteEvalOutsideQuasiquote"
                format:@"Comma must be inside a backquote"];
    
    // Purely cosmetic...
    return Nu__null;
}

@end

@interface Nu_quasiquote_splice_operator : NuOperator {}
@end

@implementation Nu_quasiquote_splice_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    // bqcomma-at is handled by Nu_quasiquote_operator.
    // If we get here, it means someone called bq_comma
    // outside of a backquote
    [NSException raise:@"NuQuasiquoteSpliceOutsideQuasiquote"
                format:@"Comma-at must be inside a backquote"];
    
    // Purely cosmetic...
    return Nu__null;
}

@end

// Temporary use for debugging quasiquote functions...
#if 0
#define QuasiLog(args...)   NSLog(args)
#else
#define QuasiLog(args...)
#endif

@interface Nu_quasiquote_operator : NuOperator {}
@end

@implementation Nu_quasiquote_operator

- (id) evalQuasiquote:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    
    id quasiquote_eval = [[symbolTable symbolWithString:@"quasiquote-eval"] value];
    id quasiquote_splice = [[symbolTable symbolWithString:@"quasiquote-splice"] value];
    
    QuasiLog(@"bq:Entered. callWithArguments cdr = %@", [cdr stringValue]);
    
    id result = Nu__null;
    id result_cursor = Nu__null;
    id cursor = cdr;
    
    while (cursor && (cursor != Nu__null)) {
        id value;
        QuasiLog(@"quasiquote: [cursor car] == %@", [[cursor car] stringValue]);
        
        if ([[cursor car] atom]) {
            // Treat it as a quoted value
            QuasiLog(@"quasiquote: Quoting cursor car: %@", [[cursor car] stringValue]);
            value = [cursor car];
        }
        else if ([cursor car] == Nu__null) {
            QuasiLog(@"  quasiquote: null-list");
            value = Nu__null;
        }
        else if ([[symbolTable lookup:[[[cursor car] car] stringValue]] value] == quasiquote_eval) {
            QuasiLog(@"quasiquote-eval: Evaling: [[cursor car] cdr]: %@", [[[cursor car] cdr] stringValue]);
            value = [[[cursor car] cdr] evalWithContext:context];
            QuasiLog(@"  quasiquote-eval: Value: %@", [value stringValue]);
        }
        else if ([[symbolTable lookup:[[[cursor car] car] stringValue]] value] == quasiquote_splice) {
            QuasiLog(@"quasiquote-splice: Evaling: [[cursor car] cdr]: %@",
                     [[[cursor car] cdr] stringValue]);
            value = [[[cursor car] cdr] evalWithContext:context];
            QuasiLog(@"  quasiquote-splice: Value: %@", [value stringValue]);
            
            if (value != Nu__null && [value atom]) {
                [NSException raise:@"NuQuasiquoteSpliceNoListError"
                            format:@"An atom was passed to Quasiquote splicer.  Splicing can only splice a list."];
            }
            
            id value_cursor = value;
            
            while (value_cursor && (value_cursor != Nu__null)) {
                id value_item = [value_cursor car];
                
                if (result_cursor == Nu__null) {
                    result_cursor = [[[NuCell alloc] init] autorelease];
                    result = result_cursor;
                }
                else {
                    [result_cursor setCdr: [[[NuCell alloc] init] autorelease]];
                    result_cursor = [result_cursor cdr];
                }
                
                [result_cursor setCar: value_item];
                value_cursor = [value_cursor cdr];
            }
            
            QuasiLog(@"  quasiquote-splice-append: result: %@", [result stringValue]);
            
            cursor = [cursor cdr];
            
            // Don't want to do the normal cursor handling at bottom of the loop
            // in this case as we've already done it in the splicing above...
            continue;
        }
        else {
            QuasiLog(@"quasiquote: recursive callWithArguments: %@", [[cursor car] stringValue]);
            value = [self evalQuasiquote:[cursor car] context:context];
            QuasiLog(@"quasiquote: leaving recursive call with value: %@", [value stringValue]);
        }
        
        if (result == Nu__null) {
            result = [[[NuCell alloc] init] autorelease];
            result_cursor = result;
        }
        else {
            [result_cursor setCdr:[[[NuCell alloc] init] autorelease]];
            result_cursor = [result_cursor cdr];
        }
        
        [result_cursor setCar:value];
        
        QuasiLog(@"quasiquote: result_cursor: %@", [result_cursor stringValue]);
        QuasiLog(@"quasiquote: result:        %@", [result stringValue]);
        
        cursor = [cursor cdr];
    }
    QuasiLog(@"quasiquote: returning result = %@", [result stringValue]);
    return result;
}

#if 0
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
#endif

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return [[self evalQuasiquote:cdr context:context] car];
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
        id object = [context lookupObjectForKey:[symbolTable symbolWithString:@"self"]];
        id ivar = [[symbol stringValue] substringFromIndex:1];
        [object setValue:result forIvar:ivar];
    }
    else {
#ifndef CLOSE_ON_VALUES
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id classSymbol = [symbolTable symbolWithString:@"_class"];
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

@interface Nu_local_operator : NuOperator {}
@end

@implementation Nu_local_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    
    NuSymbol *symbol = [cdr car];
    id value = [[cdr cdr] car];
    id result = [value evalWithContext:context];
    [context setPossiblyNullObject:result forKey:symbol];
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
    return [NSRegularExpression regexWithPattern:value];
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
    NuBlock *block = [[[NuBlock alloc] initWithParameters:args body:body context:context] autorelease];
    // this defines the function in the calling context, lexical closures make recursion possible
    [context setPossiblyNullObject:block forKey:symbol];
#ifdef CLOSE_ON_VALUES
    // in this case, we don't have closures, so we set this to allow recursion (but it creates a retain cycle)
    [[block context] setPossiblyNullObject:block forKey:symbol];
#endif
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

@interface Nu_macro_0_operator : NuOperator {}
@end

@implementation Nu_macro_0_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id name = [cdr car];
    id body = [cdr cdr];
    
    NuMacro_0 *macro = [[[NuMacro_0 alloc] initWithName:name body:body] autorelease];
    // this defines the function in the calling context
    [context setPossiblyNullObject:macro forKey:name];
    return macro;
}

@end

@interface Nu_macro_1_operator : NuOperator {}
@end

@implementation Nu_macro_1_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id name = [cdr car];
    id args = [[cdr cdr] car];
    id body = [[cdr cdr] cdr];
    
    NuMacro_1 *macro = [[[NuMacro_1 alloc] initWithName:name parameters:args body:body] autorelease];
    // this defines the function in the calling context
    [context setPossiblyNullObject:macro forKey:name];
    return macro;
}

@end

@interface Nu_macrox_operator : NuOperator {}
@end

@implementation Nu_macrox_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id call = [cdr car];
    id name = [call car];
    id margs = [call cdr];
    
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id macro = [context objectForKey:[symbolTable symbolWithString:[name stringValue]]];
    
    if (macro == nil) {
        [NSException raise:@"NuMacroxWrongType" format:@"macrox was called on an object which is not a macro"];
    }
    
    id expanded = [macro expand1:margs context:context];
    return expanded;
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
    if ([context objectForKey:[symbolTable symbolWithString:@"_class"]] && ![context objectForKey:[symbolTable symbolWithString:@"_method"]]) {
        // we are inside a class declaration and outside a method declaration.
        // treat this as a "cmethod" call
        NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithString:@"_class"]];
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
            id carValue = [[cursor car] evalWithContext:context];
            if (carValue && (carValue != Nu__null)) {
                [result appendString:[carValue stringValue]];
            }
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
    if ([context objectForKey:[symbolTable symbolWithString:@"_class"]] && ![context objectForKey:[symbolTable symbolWithString:@"_method"]]) {
        // we are inside a class declaration and outside a method declaration.
        // treat this as an "imethod" call
        NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithString:@"_class"]];
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
    return [symbolTable symbolWithString:@"t"];
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
    return [symbolTable symbolWithString:@"t"];
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
    return [symbolTable symbolWithString:@"t"];
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
    return [symbolTable symbolWithString:@"t"];
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
        return nu_valueIsTrue(value) ? Nu__null : [symbolTable symbolWithString:@"t"];
    }
    return Nu__null;
}

@end

#if !TARGET_OS_IPHONE
@interface NuConsoleViewController : NSObject {}
- (void) write:(id) string;
@end
#endif

@interface Nu_puts_operator : NuOperator {}
@end

@implementation Nu_puts_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
#if !TARGET_OS_IPHONE
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuConsoleViewController *console = (NuConsoleViewController*)
    [[symbolTable symbolWithString:@"$$console"] value];
#endif
    NSString *string;
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        id value = [[cursor car] evalWithContext:context];
        if (value) {
            string = [value stringValue];
#if !TARGET_OS_IPHONE
            if (console && (console != Nu__null)) {
                [console write:string];
                [console write:[NSString carriageReturn]];
            }
            else {
#endif
                printf("%s\n", [string cStringUsingEncoding:NSUTF8StringEncoding]);
#if !TARGET_OS_IPHONE
            }
#endif
        }
        cursor = [cursor cdr];
    }
    return Nu__null;;
}

@end

#if !TARGET_OS_IPHONE
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
#if !TARGET_OS_IPHONE
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuConsoleViewController *console = (NuConsoleViewController*)[[symbolTable symbolWithString:@"$$console"] value];
#endif
    NSString *string;
    id cursor = cdr;
    while (cursor && (cursor != Nu__null)) {
        string = [[[cursor car] evalWithContext:context] stringValue];
#if !TARGET_OS_IPHONE
        if (console && (console != Nu__null)) {
            [console write:string];
        }
        else {
#endif
            printf("%s", [string cStringUsingEncoding:NSUTF8StringEncoding]);
#if !TARGET_OS_IPHONE
        }
#endif
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

#ifdef LINUX
id loadNuLibraryFile(NSString *nuFileName, id parser, id context, id symbolTable)
{
    NSString *fullPath = [NSString stringWithFormat:@"/usr/local/share/libNu/%@.nu", nuFileName];
    if ([NSFileManager fileExistsNamed:fullPath]) {
        NSString *string = [NSString stringWithContentsOfFile:fullPath];
        id value = Nu__null;
        if (string) {
            id body = [parser parse:string asIfFromFilename:[fullPath cStringUsingEncoding:NSUTF8StringEncoding]];
            value = [body evalWithContext:context];
            return [symbolTable symbolWithString:@"t"];
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

@interface Nu_load_operator : NuOperator {}
@end

@implementation Nu_load_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id parser = [context lookupObjectForKey:[symbolTable symbolWithString:@"_parser"]];
    id resourceName = [[cdr car] evalWithContext:context];
    
    // does the resourceName contain a colon? if so, it's a framework:nu-source-file pair.
    NSArray *split = [resourceName componentsSeparatedByString:@":"];
    if ([split count] == 2) {
        id frameworkName = [split objectAtIndex:0];
        id nuFileName = [split objectAtIndex:1];
#ifdef LINUX
        if ([frameworkName isEqual:@"Nu"]) {
            if (loadNuLibraryFile(nuFileName, parser, context, symbolTable) == nil) {
                [NSException raise:@"NuLoadFailed" format:@"unable to load %@", nuFileName];
            }
            else {
                return [symbolTable symbolWithString:@"t"];
            }
        }
#endif
        
        NSBundle *framework = [NSBundle frameworkWithName:frameworkName];
        if ([framework loadNuFile:nuFileName withContext:context])
            return [symbolTable symbolWithString:@"t"];
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
            NSString *string = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
            if (string) {
                id body = [parser parse:string asIfFromFilename:[fileName cStringUsingEncoding:NSUTF8StringEncoding]];
                [body evalWithContext:context];
                return [symbolTable symbolWithString:@"t"];
            }
            else {
                [NSException raise:@"NuLoadFailed" format:@"unable to load %@", fileName];
                return nil;
            }
        }
        
        // if that failed, try to load the file the main application bundle
        if ([[NSBundle mainBundle] loadNuFile:resourceName withContext:context]) {
            return [symbolTable symbolWithString:@"t"];
        }
        
        // next, try the main Nu bundle
        if ([Nu loadNuFile:resourceName fromBundleWithIdentifier:@"nu.programming.framework" withContext:context]) {
            return [symbolTable symbolWithString:@"t"];
        }
        
        // if no file was found, try to load a framework with the given name
        if ([NSBundle frameworkWithName:resourceName]) {
#ifdef LINUX
            // if we're on Linux, call this a second (redundant) time because GNUstep seems to sometimes fail to properly load on the first call.
            [NSBundle frameworkWithName:resourceName];
#endif
            return [symbolTable symbolWithString:@"t"];
        }
        
#ifdef LINUX
        if (loadNuLibraryFile(resourceName, parser, context, symbolTable)) {
            return [symbolTable symbolWithString:@"t"];
        }
#endif
        
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
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
    id body = [cdr cdr];
    NuBlock *block = [[NuBlock alloc] initWithParameters:arg_names body:body context:context];
    id result = [[block evalWithArguments:arg_values context:context] retain];
    [block release];
    
    [arg_names release];
    [arg_values release];
    [pool drain];
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
    id body;
#if defined(__x86_64__) || TARGET_OS_IPHONE
    Class newClass = nil;
#endif
    
    NuClass *childClass;
    //NSLog(@"class name: %@", className);
    if ([cdr cdr]
        && ([cdr cdr] != Nu__null)
        && [[[cdr cdr] car] isEqual: [symbolTable symbolWithString:@"is"]]
        ) {
        id parentName = [[[cdr cdr] cdr] car];
        //NSLog(@"parent name: %@", [parentName stringValue]);
        Class parentClass = NSClassFromString([parentName stringValue]);
        if (!parentClass)
            [NSException raise:@"NuUndefinedSuperclass" format:@"undefined superclass %@", [parentName stringValue]];
        
#if defined(__x86_64__) || TARGET_OS_IPHONE
        
        newClass = objc_allocateClassPair(parentClass, [[className stringValue] cStringUsingEncoding:NSUTF8StringEncoding], 0);
        childClass = [NuClass classWithClass:newClass];
        [childClass setRegistered:NO];
        //NSLog(@"created class %@", [childClass name]);
        
        if (!childClass) {
            // This class may have already been defined previously
            // (perhaps by loading the same .nu file twice).
            // If so, the above call to objc_allocateClassPair() returns nil.
            // So if childClass is nil, it may be that the class was
            // already defined, so we'll try to find it and use it.
            Class existingClass = NSClassFromString([className stringValue]);
            if (existingClass) {
                childClass = [NuClass classWithClass:existingClass];
                //if (childClass)
                //    NSLog(@"Warning: attempting to re-define existing class: %@.  Ignoring.", [className stringValue]);
            }
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
         forKey:[symbolTable symbolWithString:@"_class"]];
        result = [block evalWithArguments:Nu__null context:Nu__null];
        [block release];
    }
#if defined(__x86_64__) || TARGET_OS_IPHONE
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
    NSLog(@"The cmethod operator is deprecated. Please replace it with '+' in your code.");
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithString:@"_class"]];
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
    NSLog(@"The imethod operator is deprecated. Please replace it with '-' in your code.");
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithString:@"_class"]];
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
    NuClass *classWrapper = [context objectForKey:[symbolTable symbolWithString:@"_class"]];
    // this will only work if the class is unregistered...
    if ([classWrapper isRegistered]) {
        [NSException raise:@"NuIvarAddedTooLate" format:@"explicit instance variables must be added when a class is created and before any method declarations"];
    }
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
        nu_class_addInstanceVariable_withSignature(classToExtend,
                                                   [[variableName stringValue] cStringUsingEncoding:NSUTF8StringEncoding],
                                                   [signature cStringUsingEncoding:NSUTF8StringEncoding]);
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
    NSLog(@"The ivars operator is unnecessary. Please remove it from your source.");
    return Nu__null;
}

@end

@interface Nu_ivar_accessors_operator : NuOperator {}
@end

@implementation Nu_ivar_accessors_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NSLog(@"The ivar-accessors operator is unnecessary. Please remove it from your source.");
    return Nu__null;
}

@end

@interface Nu_system_operator : NuOperator {}
@end

@implementation Nu_system_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
#if TARGET_OS_IPHONE
	NSLog(@"System operator currently not supported on iOS");
	//FIXME: Use NSTask
	return [NSNumber numberWithInt:1];
#else
	id cursor = cdr;
    NSMutableString *command = [NSMutableString string];
    while (cursor && (cursor != [NSNull null])) {
        [command appendString:[[[cursor car] evalWithContext:context] stringValue]];
        cursor = [cursor cdr];
    }
    const char *commandString = [command cStringUsingEncoding:NSUTF8StringEncoding];
    int result = system(commandString) >> 8;      // this needs an explanation
    return [NSNumber numberWithInt:result];
#endif
}

@end

@interface Nu_exit_operator : NuOperator {}
@end

@implementation Nu_exit_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    if (cdr && (cdr != Nu__null)) {
        int status = [[[cdr car] evalWithContext:context] intValue];
        exit(status);
    }
    else {
        exit (0);
    }
    return Nu__null;                              // we'll never get here.
}

@end

@interface Nu_sleep_operator : NuOperator {}
@end

@implementation Nu_sleep_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    int result = -1;
    if (cdr && (cdr != Nu__null)) {
        int seconds = [[[cdr car] evalWithContext:context] intValue];
        result = sleep(seconds);
    }
    else {
        [NSException raise: @"NuArityError" format:@"sleep expects 1 argument, got 0"];
    }
    return [NSNumber numberWithInt:result];
}

@end

@interface Nu_uname_operator : NuOperator {}
@end

@implementation Nu_uname_operator
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    if (!cdr || (cdr == Nu__null)) {
#if TARGET_OS_IPHONE
        return @"iOS";
#else
#ifdef DARWIN
        return @"Darwin";
#else
        return @"Linux";
#endif
#endif
    }
    if ([[[cdr car] stringValue] isEqualToString:@"systemName"]) {
#if TARGET_OS_IPHONE
        return [[UIDevice currentDevice] systemName];
#else
        return @"Macintosh";
#endif
    }
    return nil;
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

@interface Nu_return_from_operator : NuOperator {}
@end

@implementation Nu_return_from_operator

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    id block = nil;
    id value = nil;
    id cursor = cdr;
    if (cursor && cursor != Nu__null) {
        block = [[cursor car] evalWithContext:context];
        cursor = [cursor cdr];
    }
    if (cursor && cursor != Nu__null) {
        value = [[cursor car] evalWithContext:context];
    }
    @throw [[[NuReturnException alloc] initWithValue:value blockForReturn:block] autorelease];
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

static id evaluatedArguments(id cdr, NSMutableDictionary *context)
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

@interface Nu_signature_operator : NuOperator {}
@end

@implementation Nu_signature_operator

// signature operator; basically gives access to the static signature_for_identifier function from within Nu code
- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return signature_for_identifier( [[cdr car] evalWithContext:context],[NuSymbolTable sharedSymbolTable]);
}

@end

#define install(name, class) [(NuSymbol *) [symbolTable symbolWithString:name] setValue:[[[class alloc] init] autorelease]]

void load_builtins(NuSymbolTable *symbolTable);

void load_builtins(NuSymbolTable *symbolTable)
{
    [(NuSymbol *) [symbolTable symbolWithString:@"t"] setValue:[symbolTable symbolWithString:@"t"]];
    [(NuSymbol *) [symbolTable symbolWithString:@"nil"] setValue:Nu__null];
    [(NuSymbol *) [symbolTable symbolWithString:@"YES"] setValue:[NSNumber numberWithBool:YES]];
    [(NuSymbol *) [symbolTable symbolWithString:@"NO"] setValue:[NSNumber numberWithBool:NO]];
    
    install(@"car",      Nu_car_operator);
    install(@"cdr",      Nu_cdr_operator);
    install(@"first",    Nu_car_operator);
    install(@"rest",     Nu_cdr_operator);
    install(@"head",     Nu_car_operator);
    install(@"tail",     Nu_cdr_operator);
    install(@"atom",     Nu_atom_operator);
    install(@"defined",  Nu_defined_operator);
    
    install(@"eq",       Nu_eq_operator);
    install(@"==",       Nu_eq_operator);
    install(@"ne",       Nu_neq_operator);
    install(@"!=",       Nu_neq_operator);
    install(@"gt",       Nu_greaterthan_operator);
    install(@">",        Nu_greaterthan_operator);
    install(@"lt",       Nu_lessthan_operator);
    install(@"<",        Nu_lessthan_operator);
    install(@"ge",       Nu_gte_operator);
    install(@">=",       Nu_gte_operator);
    install(@"le",       Nu_lte_operator);
    install(@"<=",       Nu_lte_operator);
    
    install(@"cons",     Nu_cons_operator);
    install(@"append",   Nu_append_operator);
    install(@"apply",    Nu_apply_operator);
    
    install(@"cond",     Nu_cond_operator);
    install(@"case",     Nu_case_operator);
    install(@"if",       Nu_if_operator);
    install(@"unless",   Nu_unless_operator);
    install(@"while",    Nu_while_operator);
    install(@"until",    Nu_until_operator);
    install(@"for",      Nu_for_operator);
    install(@"break",    Nu_break_operator);
    install(@"continue", Nu_continue_operator);
    install(@"return",   Nu_return_operator);
    install(@"return-from",   Nu_return_from_operator);
    
    install(@"try",      Nu_try_operator);
    
    install(@"throw",    Nu_throw_operator);
    install(@"synchronized", Nu_synchronized_operator);
    
    install(@"quote",    Nu_quote_operator);
    install(@"eval",     Nu_eval_operator);
    
    install(@"context",  Nu_context_operator);
    install(@"set",      Nu_set_operator);
    install(@"global",   Nu_global_operator);
    install(@"local",    Nu_local_operator);
    
    install(@"regex",    Nu_regex_operator);
    
    install(@"function", Nu_function_operator);
    install(@"def",      Nu_function_operator);
    
    install(@"progn",    Nu_progn_operator);
    install(@"then",     Nu_progn_operator);
    install(@"else",     Nu_progn_operator);
    
    install(@"macro",    Nu_macro_1_operator);
    install(@"macrox",   Nu_macrox_operator);
    
    install(@"quasiquote",           Nu_quasiquote_operator);
    install(@"quasiquote-eval",      Nu_quasiquote_eval_operator);
    install(@"quasiquote-splice",    Nu_quasiquote_splice_operator);
    
    install(@"+",        Nu_add_operator);
    install(@"-",        Nu_subtract_operator);
    install(@"*",        Nu_multiply_operator);
    install(@"/",        Nu_divide_operator);
    install(@"**",       Nu_exponentiation_operator);
    install(@"%",        Nu_modulus_operator);
    
    install(@"&",        Nu_bitwiseand_operator);
    install(@"|",        Nu_bitwiseor_operator);
    install(@"<<",       Nu_leftshift_operator);
    install(@">>",       Nu_rightshift_operator);
    
    install(@"&&",       Nu_and_operator);
    install(@"||",       Nu_or_operator);
    
    install(@"and",      Nu_and_operator);
    install(@"or",       Nu_or_operator);
    install(@"not",      Nu_not_operator);
    
    install(@"min",      Nu_min_operator);
    install(@"max",      Nu_max_operator);
    
    install(@"list",     Nu_list_operator);
    
    install(@"do",       Nu_do_operator);
    
#if !TARGET_OS_IPHONE
    install(@"gets",     Nu_gets_operator);
#endif
    install(@"puts",     Nu_puts_operator);
    install(@"print",    Nu_print_operator);
    
    install(@"let",      Nu_let_operator);
    
    install(@"load",     Nu_load_operator);
    
    install(@"uname",    Nu_uname_operator);
    install(@"system",   Nu_system_operator);
    install(@"exit",     Nu_exit_operator);
    install(@"sleep",    Nu_sleep_operator);
    
    install(@"class",    Nu_class_operator);
    install(@"imethod",  Nu_imethod_operator);
    install(@"cmethod",  Nu_cmethod_operator);
    install(@"ivar",     Nu_ivar_operator);
    install(@"ivars",    Nu_ivars_operator);
    install(@"ivar-accessors", Nu_ivar_accessors_operator);
    
    install(@"call",     Nu_call_operator);
    install(@"send",     Nu_send_operator);
    
    install(@"array",    Nu_array_operator);
    install(@"dict",     Nu_dict_operator);
    install(@"parse",    Nu_parse_operator);
    
    install(@"help",     Nu_help_operator);
    install(@"?",        Nu_help_operator);
    install(@"version",  Nu_version_operator);
    
    install(@"signature", Nu_signature_operator);
    
    // set some commonly-used globals
    [(NuSymbol *) [symbolTable symbolWithString:@"NSUTF8StringEncoding"]
     setValue:[NSNumber numberWithInt:NSUTF8StringEncoding]];
    
    [(NuSymbol *) [symbolTable symbolWithString:@"NSLog"] // let's make this an operator someday
     setValue:[NuBridgedFunction functionWithName:@"NSLog" signature:@"v@"]];
}
