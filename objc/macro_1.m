/*!
@file macro_1.m
@description Nu macros with a more Lispy expand/eval cycle.

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
#import "macro_0.h"
#import "macro_1.h"
#import "cell.h"
#import "symbol.h"
#import "class.h"
#import "extensions.h"
#import "objc_runtime.h"

extern id Nu__null;

#if 0
#define DefMacroLog(arg...)	NSLog(args)
#else
#define DefMacroLog(arg...)
#endif

@implementation NuMacro_1

+ (id) macroWithName:(NSString *)n body:(NuCell *)b
{
    return [[[self alloc] initWithName:n body:b] autorelease];
}

- (void) dealloc
{
	[parameters release];
    [super dealloc];
}

- (id) initWithName:(NSString *)n parameters:(NuCell *)p body:(NuCell *)b
{
    [super initWithName:n body:b];
	parameters = [p retain];
    return self;
}

- (NSString *) stringValue
{
    return [NSString stringWithFormat:@"(macro %@ %@)", name, [body stringValue]];
}

- (id) expandAndEval:(id)cdr context:(NSMutableDictionary*)calling_context evalFlag:(BOOL)evalFlag
{
	int numberOfArguments = [cdr length];
	int numberOfParameters = [parameters length];
	if (numberOfArguments != numberOfParameters)
	{
       // is the last parameter a variable argument? if so, it's ok, and we allow it to have zero elements.
        id lastParameter = [parameters lastObject];
        if (lastParameter && ([[lastParameter stringValue] characterAtIndex:0] == '*')) {
            if (numberOfArguments < (numberOfParameters - 1)) {
                [NSException raise:@"NuIncorrectNumberOfArguments"
                    format:@"Incorrect number of arguments to macro. Received %d but expected %d or more: %@",
                    numberOfArguments,
                    numberOfParameters - 1,
                    [parameters stringValue]];
            }
        }
        else {
            [NSException raise:@"NuIncorrectNumberOfArguments"
                format:@"Incorrect number of arguments to macro. Received %d but expected %d: %@",
                numberOfArguments,
                numberOfParameters,
                [parameters stringValue]];
        }
	}

    NuSymbolTable *symbolTable = [calling_context objectForKey:SYMBOLS_KEY];

	
	id plist = parameters;
	id vlist = cdr;

	NSMutableDictionary* maskedVariables = [[NSMutableDictionary alloc] init];

	while (plist && (plist != Nu__null))
	{
		// jsb TODO: "auto-gensym" these parameters
		id param = [plist car];
		id value = [vlist car];
		
		id pvalue = [calling_context objectForKey:param];
		
		if (pvalue)
		{
			[maskedVariables setPossiblyNullObject:pvalue forKey:param];
		}

		[calling_context setPossiblyNullObject:value forKey:param];
		plist = [plist cdr];
		vlist = [vlist cdr];
	}


#ifdef USE_MARGS
    // save the current value of margs
    id old_margs = [calling_context objectForKey:[symbolTable symbolWithCString:"margs"]];
    // set the arguments to the special variable "margs"
    [calling_context setPossiblyNullObject:cdr forKey:[symbolTable symbolWithCString:"margs"]];
#endif

    // evaluate the body of the block in the calling context (implicit progn)
    id value = Nu__null;

    // if the macro contains gensyms, give them a unique prefix
    int gensymCount = [[self gensyms] count];
    id gensymPrefix = nil;
    if (gensymCount > 0) {
        gensymPrefix = [NSString stringWithFormat:@"g%ld", [NuMath random]];
    }

    id bodyToEvaluate = (gensymCount == 0)
        ? (id)body : [self body:body withGensymPrefix:gensymPrefix symbolTable:symbolTable];

    DefMacroLog(@"macro evaluating: %@", [bodyToEvaluate stringValue]);
    DefMacroLog(@"macro context: %@", [calling_context stringValue]);

	// Macro expansion
    id cursor = [self expandUnquotes:bodyToEvaluate withContext:calling_context];
    while (cursor && (cursor != Nu__null)) {
		DefMacroLog(@"macro eval cursor: %@", [cursor stringValue]);
        value = [[cursor car] evalWithContext:calling_context];
		DefMacroLog(@"macro expand value: %@", [value stringValue]);
        cursor = [cursor cdr];
    }

	// if just macro-expanding, don't do the next step...

	// Macro evaluation
	if (evalFlag)
	{
	    value = [value evalWithContext:calling_context];
		DefMacroLog(@"macro eval value: %@", [value stringValue]);		
	}


	// Restore the masked calling context variables
	plist = parameters;
	while (plist && (plist != Nu__null))
	{
		id param = [plist car];
		
		[calling_context removeObjectForKey:param];
		
		id pvalue = [maskedVariables objectForKey:param];
		
		if (pvalue)
		{
			[calling_context setPossiblyNullObject:pvalue forKey:param];
		}
		
		plist = [plist cdr];
	}
	
	[maskedVariables release];

#ifdef USE_MARGS
    // restore the old value of margs
    if (old_margs == nil) {
        [calling_context removeObjectForKey:[symbolTable symbolWithCString:"margs"]];
    }
    else {
        [calling_context setPossiblyNullObject:old_margs forKey:[symbolTable symbolWithCString:"margs"]];
    }
#endif

	DefMacroLog(@"macro result: %@", value);
    return value;
}

- (id) expand1:(id)cdr context:(NSMutableDictionary*)calling_context
{
	return [self expandAndEval:cdr context:calling_context evalFlag:NO];
}


- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)calling_context
{
	return [self expandAndEval:cdr context:calling_context evalFlag:YES];
}

@end
