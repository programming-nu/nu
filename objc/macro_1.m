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
#import "match.h"

extern id Nu__null;

#define USE_DESTRUCTURING_BIND	1
//#define MACRO1_DEBUG	1

// Following  debug output on and off for this file only
#ifdef MACRO1_DEBUG
#define Macro1Debug(arg...) NSLog(arg)
#else
#define Macro1Debug(arg...)
#endif


@implementation NuMacro_1

+ (id) macroWithName:(NSString *)n parameters:(NuCell*)p body:(NuCell *)b
{
    return [[[self alloc] initWithName:n parameters:p body:b] autorelease];
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

	id match = [NuMatch matcher];

	if (([parameters length] == 1) 
		&& ([[[parameters car] stringValue] isEqualToString:@"*args"]))
	{
		// Skip the check
	}
	else
	{
		id foundArgs = [match findAtom:@"*args" inSequence:parameters];

		if (foundArgs && (foundArgs != Nu__null))
		{
			printf("Warning: Overriding implicit variable '*args'.\n");
		}
	}

    return self;
}

- (NSString *) stringValue
{
    return [NSString stringWithFormat:@"(macro-1 %@ %@ %@)", name, [parameters stringValue], [body stringValue]];
}



- (void) dumpContext:(NSMutableDictionary*)context
{
	NSArray* keys = [context allKeys];
	for (id key in keys)
	{
		Macro1Debug(@"contextdump: %@  =  %@  [%@]", key, 
			[[context objectForKey:key] stringValue],
			[[context objectForKey:key] class]);
	}
}


- (id) expandAndEval:(id)cdr context:(NSMutableDictionary*)calling_context evalFlag:(BOOL)evalFlag
{
    NuSymbolTable *symbolTable = [calling_context objectForKey:SYMBOLS_KEY];

	NSMutableDictionary* maskedVariables = [[NSMutableDictionary alloc] init];

	id plist;

	Macro1Debug(@"Dumping context:");
	Macro1Debug(@"---------------:");
	[self dumpContext:calling_context];

    id old_args = [calling_context objectForKey:[symbolTable symbolWithCString:"*args"]];
	[calling_context setPossiblyNullObject:cdr forKey:[symbolTable symbolWithCString:"*args"]];

#ifdef USE_DESTRUCTURING_BIND

	id match = [NuMatch matcher];

	// Destructure the arguments
	id destructure = [match mdestructure:parameters withSequence:cdr];
	
	plist = destructure;
	while (plist && (plist != Nu__null))
	{
		id parameter = [[plist car] car];
		id value = [[[plist car] cdr] car];
		Macro1Debug(@"Destructure: %@ = %@", [parameter stringValue], [value stringValue]);
			
		id pvalue = [calling_context objectForKey:parameter];
		
		if (pvalue)
		{
			Macro1Debug(@"  Saving context: %@ = %@", 
					[parameter stringValue],
					[pvalue stringValue]);
			[maskedVariables setPossiblyNullObject:pvalue forKey:parameter];
		}

		[calling_context setPossiblyNullObject:value forKey:parameter];
		
		plist = [plist cdr];
	}
	
#else
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

	
	// Get the unevaluated values of the macro's parameter list
	plist = parameters;
	id vlist = cdr;

	while (plist && (plist != Nu__null))
	{
		id parameter = [plist car];

		// Save the values of any variables in the calling context that are 
		// masked by the macro arguments.
		id pvalue = [calling_context objectForKey:parameter];

		if (pvalue)
		{
			[maskedVariables setPossiblyNullObject:pvalue forKey:parameter];
		}


        if ([[parameter stringValue] characterAtIndex:0] == '*')
		{
            id varargs = [[[NuCell alloc] init] autorelease];
            id cursor = varargs;
            while (vlist != Nu__null) {
                [cursor setCdr:[[[NuCell alloc] init] autorelease]];
                cursor = [cursor cdr];
                id value = [vlist car];
                [cursor setCar:value];
                vlist = [vlist cdr];
            }

            [calling_context setPossiblyNullObject:[varargs cdr] forKey:parameter];
            plist = [plist cdr];

            // this must be the last element in the parameter list
            if (plist != Nu__null)
			{
                [NSException raise:@"NuBadParameterList"
                    format:@"Variable argument list must be the last parameter in the parameter list: %@",
                    [parameters stringValue]];
            }
        }
        else 
		{
            id value = [vlist car];

			[calling_context setPossiblyNullObject:value forKey:parameter];

            plist = [plist cdr];
            vlist = [vlist cdr];
        }
	}

#endif

	Macro1Debug(@"Dumping context (after destructure):");
	Macro1Debug(@"-----------------------------------:");
	[self dumpContext:calling_context];


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

	// Macro1Debug(@"macro evaluating: %@", [bodyToEvaluate stringValue]);
	// Macro1Debug(@"macro context: %@", [calling_context stringValue]);

	// Macro expansion
    id cursor = [self expandUnquotes:bodyToEvaluate withContext:calling_context];
    while (cursor && (cursor != Nu__null)) {
		Macro1Debug(@"macro eval cursor: %@", [cursor stringValue]);
        value = [[cursor car] evalWithContext:calling_context];
		Macro1Debug(@"macro expand value: %@", [value stringValue]);
        cursor = [cursor cdr];
    }


	// Now that macro expansion is done, restore the masked calling context variables
#ifdef USE_DESTRUCTURING_BIND
	plist = destructure;
#else
	plist = parameters;
#endif

	while (plist && (plist != Nu__null))
	{
#ifdef USE_DESTRUCTURING_BIND
		id param = [[plist car] car];
#else
		id param = [plist car];
#endif

		[calling_context removeObjectForKey:param];		
		id pvalue = [maskedVariables objectForKey:param];
		
		Macro1Debug(@"restoring calling context for: %@, value: %@",
			[param stringValue], [pvalue stringValue]);
		
		if (pvalue)
		{
			[calling_context setPossiblyNullObject:pvalue forKey:param];
		}
		
		plist = [plist cdr];
	}
	
	Macro1Debug(@"var = %@", [[calling_context objectForKey:@"var"] stringValue]);


	// if just macro-expanding, don't do the next step...

	// Macro evaluation
	if (evalFlag)
	{
		Macro1Debug(@"About to execute: %@", [value stringValue]);
	    value = [value evalWithContext:calling_context];
		Macro1Debug(@"macro eval value: %@", [value stringValue]);		
	}


	
	[maskedVariables release];

	Macro1Debug(@"Dumping context at end:");
	Macro1Debug(@"----------------------:");
	[self dumpContext:calling_context];

    // restore the old value of margs
    if (old_args == nil) {
        [calling_context removeObjectForKey:[symbolTable symbolWithCString:"*args"]];
    }
    else {
        [calling_context setPossiblyNullObject:old_args forKey:[symbolTable symbolWithCString:"*args"]];
    }

	Macro1Debug(@"macro result: %@", value);
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
