// macro.m
//  Nu macros.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "macro.h"
#import "cell.h"
#import "symbol.h"
#import "class.h"
#import "extensions.h"
#import "objc_runtime.h"

extern id Nu__null;

@implementation NuMacro

+ (id) macroWithName:(NSString *)n body:(NuCell *)b
{
    return [[[self alloc] initWithName:n body:b] autorelease];
}

- (void) dealloc
{
    [body release];
    [super dealloc];
}

- (NSString *) name
{
    return name;
}

- (NuCell *) body
{
    return body;
}

- (NSSet *) gensyms
{
    return gensyms;
}

- (void) collectGensyms:(NuCell *)cell
{
    id car = [cell car];
    if ([car atom]) {
        if (nu_objectIsKindOfClass(car, [NuSymbol class]) && [car isGensym]) {
            [gensyms addObject:car];
        }
    }
    else if (car && (car != Nu__null)) {
        [self collectGensyms:car];
    }
    id cdr = [cell cdr];
    if (cdr && (cdr != Nu__null)) {
        [self collectGensyms:cdr];
    }
}

- (id) initWithName:(NSString *)n body:(NuCell *)b
{
    [super init];
    name = [n retain];
    body = [b retain];
    gensyms = [[NSMutableSet alloc] init];
    [self collectGensyms:body];
    return self;
}

- (NSString *) stringValue
{
    return [NSString stringWithFormat:@"(macro %@ %@)", name, [body stringValue]];
}

- (id) body:(NuCell *) oldBody withGensymPrefix:(NSString *) prefix symbolTable:(NuSymbolTable *) symbolTable
{
    NuCell *newBody = [[[NuCell alloc] init] autorelease];
    id car = [oldBody car];
    if (car == Nu__null) {
		[newBody setCar:car];
    }
    else if ([car atom]) {
        if (nu_objectIsKindOfClass(car, [NuSymbol class]) && [car isGensym]) {
            [newBody setCar:[symbolTable symbolWithString:[NSString stringWithFormat:@"%@%@", prefix, [car stringValue]]]];
        }
        else if (nu_objectIsKindOfClass(car, [NSString class])) {
            // Here we replace gensyms in interpolated strings.
            // The current solution is workable but fragile;
            // we just blindly replace the gensym names with their expanded names.
            // It would be better to
            // 		1. only replace gensym names in interpolated expressions.
            // 		2. ensure substitutions never overlap.  To do this, I think we should
            //           a. order gensyms by size and do the longest ones first.
            //           b. make the gensym transformation idempotent.
            // That's for another day.
            // For now, I just substitute each gensym name with its expansion.
            //
            NSMutableString *tempString = [NSMutableString stringWithString:car];
            //NSLog(@"checking %@", tempString);
            NSEnumerator *gensymEnumerator = [gensyms objectEnumerator];
            NuSymbol *gensymSymbol;
            while ((gensymSymbol = [gensymEnumerator nextObject])) {
                //NSLog(@"gensym is %@", [gensymSymbol stringValue]);
                [tempString replaceOccurrencesOfString:[gensymSymbol stringValue]
                    withString:[NSString stringWithFormat:@"%@%@", prefix, [gensymSymbol stringValue]]
                    options:0 range:NSMakeRange(0, [tempString length])];
            }
            //NSLog(@"setting string to %@", tempString);
            [newBody setCar:tempString];
        }
        else {
            [newBody setCar:car];
        }
    }
    else {
        [newBody setCar:[self body:car withGensymPrefix:prefix symbolTable:symbolTable]];
    }
    id cdr = [oldBody cdr];
    if (cdr && (cdr != Nu__null)) {
        [newBody setCdr:[self body:cdr withGensymPrefix:prefix symbolTable:symbolTable]];
    }
    else {
        [newBody setCdr:cdr];
    }
    return newBody;
}

- (id) expandUnquotes:(id) oldBody withContext:(NSMutableDictionary *) context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    if (oldBody == [NSNull null])
        return oldBody;
    id unquote = [symbolTable symbolWithString:@"unquote"];
    id car = [oldBody car];
    id cdr = [oldBody cdr];
    if ([car atom]) {
        if (car == unquote) {
            return [[cdr car] evalWithContext:context];
        }
        else {
            NuCell *newBody = [[[NuCell alloc] init] autorelease];
            [newBody setCar:car];
            [newBody setCdr:[self expandUnquotes:cdr withContext:context]];
            return newBody;
        }
    }
    else {
        NuCell *newBody = [[[NuCell alloc] init] autorelease];
        [newBody setCar:[self expandUnquotes:car withContext:context]];
        [newBody setCdr:[self expandUnquotes:cdr withContext:context]];
        return newBody;
    }
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context
{
    NuSymbolTable *symbolTable = [calling_context objectForKey:SYMBOLS_KEY];
    //NSLog(@"macro eval %@", [cdr stringValue]);
    // save the current value of margs
    id old_margs = [calling_context objectForKey:[symbolTable symbolWithCString:"margs"]];
    // set the arguments to the special variable "margs"
    [calling_context setObject:cdr forKey:[symbolTable symbolWithCString:"margs"]];
    // evaluate the body of the block in the calling context (implicit progn)
    id value = Nu__null;

    // if the macro contains gensyms, give them a unique prefix
    id bodyToEvaluate = ([[self gensyms] count] == 0)
        ? body : [self body:body withGensymPrefix:[NSString stringWithFormat:@"g%ld", [NuMath random]] symbolTable:symbolTable];

    // uncomment this to get the old (no gensym) behavior.
    //bodyToEvaluate = body;
    //NSLog(@"evaluating %@", [bodyToEvaluate stringValue]);

    id cursor = [self expandUnquotes:bodyToEvaluate withContext:calling_context];
    while (cursor && (cursor != Nu__null)) {
        value = [[cursor car] evalWithContext:calling_context];
        cursor = [cursor cdr];
    }
    // restore the old value of margs
    if (old_margs == nil) {
        [calling_context removeObjectForKey:[symbolTable symbolWithCString:"margs"]];
    }
    else {
        [calling_context setObject:old_margs forKey:[symbolTable symbolWithCString:"margs"]];
    }
    // NSLog(@"result is %@", value);
    return value;
}

@end
