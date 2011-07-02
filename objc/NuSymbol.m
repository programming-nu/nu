/*!
 @file NuSymbol.m
 @description A class for Nu symbols and symbol tables.
 @copyright Copyright (c) 2007 Radtastical Inc.
 
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
#import "NuSymbol.h"
#import "NuClass.h"
#import "NuObject.h"
#import "NuExtensions.h"
#import "NuBridge.h"
#import "NuParser.h"

extern void load_builtins(NuSymbolTable *);

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
- (NuSymbol *) symbolWithCString:(const char *)cstring
{
    if (!symbol_table) symbol_table = [[NSMutableDictionary alloc] init];
    
    NSString *string = [NSString stringWithCString:cstring encoding:NSUTF8StringEncoding];
    // If the symbol is already in the table, return it.
    NuSymbol *symbol = [symbol_table objectForKey:string];
    if (symbol) {
        return symbol;
    }
    
    // If not, create it. Don't autorelease it; it is owned by the table.
    symbol = [[NuSymbol alloc] init];             // keep construction private
    symbol->string = strdup(cstring);
    // the symbol table does not use strong refs so make one here for each symbol
    int len = strlen(cstring);
    symbol->isLabel = (cstring[len - 1] == ':');
    symbol->isGensym = (len > 2) && (cstring[0] == '_') && (cstring[1] == '_');
    
    // Put the new symbol in the symbol table and return it.
    [symbol_table setObject:symbol forKey:string];
    return symbol;
}

- (NuSymbol *) symbolWithString:(NSString *)string
{
    return [self symbolWithCString:[string cStringUsingEncoding:NSUTF8StringEncoding]];
}

- (NuSymbol *) symbolWithBytes:(const void *)bytes length:(unsigned)length
{
    char buffer[1024];                            // overrun risk!!
    strncpy(buffer, bytes, length);
    buffer[length] = 0;
    return [self symbolWithCString:buffer];
}

- (NuSymbol *) lookup:(const char *) cstring
{
    return [symbol_table objectForKey:[NSString stringWithCString:cstring encoding:NSUTF8StringEncoding]];
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

@implementation NuSymbol

- (void) dealloc
{
    free(string);
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
    if (!stringValue)
        stringValue = [[NSString alloc] initWithCString:string encoding:NSUTF8StringEncoding];
    return stringValue;
}

- (NSString *) stringValue
{
    if (!stringValue)
        stringValue = [[NSString alloc] initWithCString:string encoding:NSUTF8StringEncoding];
    return stringValue;
}

- (int) intValue
{
    return (value == [NSNull null]) ? 0 : 1;
}

- (const char *) string
{
    return string;
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

- (id) evalWithContext:(NSMutableDictionary *)context
{
    
    char c = (char) [[self stringValue] characterAtIndex:0];
    // If the symbol is a class instance variable, find "self" and ask it for the ivar value.
    if (c == '@') {
        NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
        id object = [context lookupObjectForKey:[symbolTable symbolWithCString:"self"]];
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
    
    // Still-undefined symbols throw an exception.
    NSMutableString *errorDescription = [NSMutableString stringWithFormat:@"undefined symbol %@", [self stringValue]];
    id expression = [context lookupObjectForKey:[symbolTable symbolWithCString:"_expression"]];
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
    return strcmp(string, anotherSymbol->string);
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
