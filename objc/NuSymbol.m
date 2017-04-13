//
//  NuSymbol.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuSymbol.h"
#import "NuInternals.h"
#import "NSDictionary+Nu.h"
#import "NuBridge.h"
#import "NuBridgedFunction.h"
#import "NuBridgedConstant.h"
#import "NuClass.h"

#pragma mark - NuSymbol.m

@interface NuSymbol ()
{
    NuSymbolTable *table;
    id value;
@public                                       // only for use by the symbol table
    bool isLabel;
    bool isGensym;                                // in macro evaluation, symbol is replaced with an automatically-generated unique symbol.
    NSString *stringValue;			  // let's keep this for efficiency
}
- (void) _setStringValue:(NSString *) string;
@end

@interface NuSymbolTable ()
{
    NSMutableDictionary *symbol_table;
}
@end

void load_builtins(NuSymbolTable *);

static NuSymbolTable *sharedSymbolTable = 0;


@implementation NuSymbolTable

+ (NuSymbolTable *) sharedSymbolTable
{
    if (!sharedSymbolTable) {
        sharedSymbolTable = [[self alloc] init];
        load_builtins(sharedSymbolTable);
    }
    return sharedSymbolTable;
}

- (void) dealloc
{
    NSLog(@"WARNING: deleting a symbol table. Leaking stored symbols.");
    [super dealloc];
}

// Designated initializer
- (NuSymbol *) symbolWithString:(NSString *)string
{
    if (!symbol_table) symbol_table = [[NSMutableDictionary alloc] init];
    
    // If the symbol is already in the table, return it.
    NuSymbol *symbol;
    symbol = [symbol_table objectForKey:string];
    if (symbol) {
        return symbol;
    }
    
    // If not, create it.
    symbol = [[[NuSymbol alloc] init] autorelease];             // keep construction private
    [symbol _setStringValue:string];
    
    // Put the new symbol in the symbol table and return it.
    [symbol_table setObject:symbol forKey:string];
    return symbol;
}

- (NuSymbol *) lookup:(NSString *) string
{
    return [symbol_table objectForKey:string];
}

- (NSArray *) all
{
    return [symbol_table allValues];
}

- (void) removeSymbol:(NuSymbol *) symbol
{
    [symbol_table removeObjectForKey:[symbol stringValue]];
}

@end

#import "NuMarkupOperator.h"

@implementation NuSymbol

- (void) _setStringValue:(NSString *) string {
    self->stringValue = [string copy];
    
    const char *cstring = [string UTF8String];
    NSUInteger len = strlen(cstring);
    self->isLabel = (cstring[len - 1] == ':');
    self->isGensym = (len > 2) && (cstring[0] == '_') && (cstring[1] == '_');
}

- (void) dealloc
{
    [stringValue release];
    [super dealloc];
}

- (BOOL) isEqual: (NuSymbol *)other
{
    return (self == other) ? 1l : 0l;
}

- (id) value
{
    return value;
}

- (void) setValue:(id)v
{
    [v retain];
    [value release];
    value = v;
}

- (NSString *) description
{
    return stringValue;
}

- (NSString *) stringValue
{
    return stringValue;
}

- (int) intValue
{
    return (value == [NSNull null]) ? 0 : 1;
}

- (bool) isGensym
{
    return isGensym;
}

- (bool) isLabel
{
    return isLabel;
}

- (NSString *) labelName
{
    if (isLabel)
        return [[self stringValue] substringToIndex:[[self stringValue] length] - 1];
    else
        return [self stringValue];
}

- (NSString *) labelValue
{
    if (isLabel)
        return [[self stringValue] substringToIndex:[[self stringValue] length] - 1];
    else
        return [self stringValue];
}

- (id) evalWithContext:(NSMutableDictionary *)context
{
    
    char c = (char) [[self stringValue] characterAtIndex:0];
    // If the symbol is a class instance variable, find "self" and ask it for the ivar value.
    if (c == '@') {
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id object = [context lookupObjectForKey:[symbolTable symbolWithString:@"self"]];
        if (!object) return [NSNull null];
        id ivarName = [[self stringValue] substringFromIndex:1];
        id result = [object valueForIvar:ivarName];
        return result ? result : (id) [NSNull null];
    }
    
    // Next, try to find the symbol in the local evaluation context.
    id valueInContext = [context lookupObjectForKey:self];
    if (valueInContext)
        return valueInContext;
    
#if 0
    // if it's not there, try the next context up
    id parentContext = [context objectForKey:@"context"];
    if (parentContext) {
        valueInContext = [parentContext objectForKey:self];
        if (valueInContext)
            return valueInContext;
    }
#endif
    
    // Next, return the global value assigned to the value.
    if (value)
        return value;
    
    // If the symbol is a label (ends in ':'), then it will evaluate to itself.
    if (isLabel)
        return self;
    
    // If the symbol is still unknown, try to find a class with this name.
    id className = [self stringValue];
    // the symbol should retain its value.
    value = [[NuClass classWithName:className] retain];
    if (value)
        return value;
    
    // Undefined globals evaluate to null.
    if (c == '$')
        return [NSNull null];
    
    // Now we try looking in the bridge support dictionaries.
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    NuSymbol *bridgeSupportSymbol = [symbolTable symbolWithString:@"BridgeSupport"];
    NSDictionary *bridgeSupport = bridgeSupportSymbol ? [bridgeSupportSymbol value] : nil;
    if (bridgeSupport) {
        // is it an enum?
        id enumValue = [[bridgeSupport valueForKey:@"enums"] valueForKey:[self stringValue]];
        if (enumValue) {
            value = enumValue;
            return value;
        }
        // is it a constant?
        id constantSignature = [[bridgeSupport valueForKey:@"constants"] valueForKey:[self stringValue]];
        if (constantSignature) {
            value = [[NuBridgedConstant constantWithName:[self stringValue] signature:constantSignature] retain];
            return value;
        }
        // is it a function?
        id functionSignature = [[bridgeSupport valueForKey:@"functions"] valueForKey:[self stringValue]];
        if (functionSignature) {
            value = [[NuBridgedFunction functionWithName:[self stringValue] signature:functionSignature] retain];
            return value;
        }
    }
    
    // Automatically create markup operators
    if ([[self stringValue] characterAtIndex:0] == '&') {
        NuMarkupOperator *newOperator = [NuMarkupOperator operatorWithTag:[[self stringValue] substringFromIndex:1]];
        [self setValue:newOperator];
        return newOperator;
    }
    
    // Still-undefined symbols throw an exception.
    NSMutableString *errorDescription = [NSMutableString stringWithFormat:@"undefined symbol %@", [self stringValue]];
    id expression = [context lookupObjectForKey:[symbolTable symbolWithString:@"_expression"]];
    if (expression) {
        [errorDescription appendFormat:@" while evaluating expression %@", [expression stringValue]];
        const char *filename = nu_parsedFilename([expression file]);
        if (filename) {
            [errorDescription appendFormat:@" at %s:%d", filename, [expression line]];
        }
    }
    [NSException raise:@"NuUndefinedSymbol" format:@"%@", errorDescription];
    return [NSNull null];
}

- (NSComparisonResult) compare:(NuSymbol *) anotherSymbol
{
    return [stringValue compare:anotherSymbol->stringValue];
}

- (id) copyWithZone:(NSZone *) zone
{
    // Symbols are unique, so we don't copy them, but we retain them again since copies are automatically retained.
    return [self retain];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[self stringValue]];
}

- (id) initWithCoder:(NSCoder *)coder
{
    [super init];
    [self autorelease];
    return [[[NuSymbolTable sharedSymbolTable] symbolWithString:[coder decodeObject]] retain];
}

@end

