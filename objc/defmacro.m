/*!
@file defmacro.m
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
#import "macro.h"
#import "defmacro.h"
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

@implementation NuDefmacro

+ (id) macroWithName:(NSString *)n body:(NuCell *)b
{
    return [[[self alloc] initWithName:n body:b] autorelease];
}

- (void) dealloc
{
    [super dealloc];
}

- (id) initWithName:(NSString *)n body:(NuCell *)b
{
    [super initWithName:n body:b];
    return self;
}

- (NSString *) stringValue
{
    return [NSString stringWithFormat:@"(defmacro %@ %@)", name, [body stringValue]];
}

- (id) expandAndEval:(id)cdr context:(NSMutableDictionary*)calling_context evalFlag:(BOOL)evalFlag
{
    NuSymbolTable *symbolTable = [calling_context objectForKey:SYMBOLS_KEY];

    // save the current value of margs
    id old_margs = [calling_context objectForKey:[symbolTable symbolWithCString:"margs"]];
    // set the arguments to the special variable "margs"
    [calling_context setPossiblyNullObject:cdr forKey:[symbolTable symbolWithCString:"margs"]];
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

    DefMacroLog(@"defmacro evaluating: %@", [bodyToEvaluate stringValue]);
    DefMacroLog(@"defmacro context: %@", [calling_context stringValue]);

	// Macro expansion
    id cursor = [self expandUnquotes:bodyToEvaluate withContext:calling_context];
    while (cursor && (cursor != Nu__null)) {
		DefMacroLog(@"defmacro eval cursor: %@", [cursor stringValue]);
        value = [[cursor car] evalWithContext:calling_context];
		DefMacroLog(@"defmacro expand value: %@", [value stringValue]);
        cursor = [cursor cdr];
    }

	// if just macro-expanding, don't do the next step...

	// Macro evaluation
	if (evalFlag)
	{
	    value = [value evalWithContext:calling_context];
		DefMacroLog(@"defmacro eval value: %@", [value stringValue]);		
	}

    // restore the old value of margs
    if (old_margs == nil) {
        [calling_context removeObjectForKey:[symbolTable symbolWithCString:"margs"]];
    }
    else {
        [calling_context setPossiblyNullObject:old_margs forKey:[symbolTable symbolWithCString:"margs"]];
    }

	DefMacroLog(@"result is %@", value);
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
