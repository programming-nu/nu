//
//  NuMarkupOperator.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "Nu.h"
#import "NuInternals.h"
#import "NuMarkupOperator.h"
#import "NuCell.h"

@implementation NuMarkupOperator

static NSSet *voidHTMLElements = nil;
static NSDictionary *elementPrefixes = nil;

+ (void) initialize {
    voidHTMLElements = [[NSSet setWithObjects:
                         @"area",
                         @"base",
                         @"br",
                         @"col",
                         @"command",
                         @"embed",
                         @"hr",
                         @"img",
                         @"input",
                         @"keygen",
                         @"link",
                         @"meta",
                         @"param",
                         @"source",
                         @"track",
                         @"wbr",
                         nil] retain];
    elementPrefixes = [[NSDictionary dictionaryWithObjectsAndKeys:
                        @"<!DOCTYPE html>", @"html",
                        nil] retain];
}

+ (id) operatorWithTag:(NSString *) _tag
{
    return [[[self alloc] initWithTag:_tag] autorelease];
}

+ (id) operatorWithTag:(NSString *) _tag prefix:(NSString *) _prefix
{
    return [[[self alloc] initWithTag:_tag prefix:_prefix contents:nil] autorelease];
}

+ (id) operatorWithTag:(NSString *) _tag prefix:(NSString *) _prefix contents:(id) _contents
{
    return [[[self alloc] initWithTag:_tag prefix:_prefix contents:_contents] autorelease];
}

- (id) initWithTag:(NSString *) _tag
{
    return [self initWithTag:_tag prefix:nil contents:nil];
}

- (id) initWithTag:(NSString *) _tag prefix:(NSString *) _prefix contents:(id) _contents
{
    self = [super init];
    
    // Scan through the tag looking for "." or "#" characters.
    // When we find them, we split the and use the following strings as class or id attributes.
    if (_tag) {
        NSScanner *scanner = [NSScanner scannerWithString:_tag];
        NSCharacterSet *scanSet = [NSCharacterSet characterSetWithCharactersInString:@".#"];
        NSString *token;
        char typeFlag = 0;
        while ([scanner scanUpToCharactersFromSet:scanSet intoString:&token]) {
            if (typeFlag == 0) {
                _tag = token;
            } else if (typeFlag == '.') {
                if (!tagClasses) {
                    tagClasses = [[NSMutableArray alloc] init];
                }
                [tagClasses addObject:token];
            } else if (typeFlag == '#') {
                if (!tagIds) {
                    tagIds = [[NSMutableArray alloc] init];
                }
                [tagIds addObject:token];
           	}
            if ([scanner scanCharactersFromSet:scanSet intoString:&token]) {
                if ([token length]) {
                    typeFlag = [token characterAtIndex:[token length] - 1];
                } else {
                    typeFlag = 0;
                }
            }
        }
    }
    tag = _tag ? [_tag stringByReplacingOccurrencesOfString:@"=" withString:@":"] : nil;
    [tag retain];
    prefix = _prefix ? _prefix : [elementPrefixes objectForKey:tag];
    if (!prefix) {
        prefix = @"";
    }
    [prefix retain];
    contents = _contents ? _contents : Nu__null;
    [contents retain];
    empty = [voidHTMLElements containsObject:tag];
    return self;
}

- (void) dealloc
{
    [tag release];
    [prefix release];
    [contents release];
    [tagIds release];
    [tagClasses release];
    [super dealloc];
}

- (void) setEmpty:(BOOL) e
{
    empty = e;
}

- (id) callWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
    id t_symbol = [symbolTable symbolWithString:@"t"];
    
    NSMutableString *body = [NSMutableString string];
    NSMutableString *attributes = [NSMutableString string];
    
    static id NuSymbol = nil;
    if (!NuSymbol) {
        NuSymbol = NSClassFromString(@"NuSymbol");
    }
    if (tagIds) {
        for (int i = 0; i < [tagIds count]; i++) {
            [attributes appendFormat:@" id=\"%@\"", [tagIds objectAtIndex:i]];
        }
    }
    if (tagClasses) {
        for (int i = 0; i < [tagClasses count]; i++) {
            [attributes appendFormat:@" class=\"%@\"", [tagClasses objectAtIndex:i]];
        }
    }
    for (int i = 0; i < 2; i++) {
        id cursor = (i == 0) ? contents : cdr;
        while (cursor && (cursor != Nu__null)) {
            id item = [cursor car];
            if ([item isKindOfClass:[NuSymbol class]] && [item isLabel]) {
                cursor = [cursor cdr];
                if (cursor && (cursor != Nu__null)) {
                    id value = [[cursor car] evalWithContext:context];
                    id attributeName = [[item labelName] stringByReplacingOccurrencesOfString:@"=" withString:@":"];
                    if ([value isEqual:Nu__null]) {
                        // omit attributes that are "false"
                    } else if ([value isEqual:t_symbol]) {
                        // boolean attributes with "true" are written without values
                        [attributes appendFormat:@" %@", attributeName];
                    } else {
                        id stringValue = [value isEqual:Nu__null] ? @"" : [value stringValue];
                        [attributes appendFormat:@" %@=\"%@\"", attributeName, stringValue];
                    }
                }
            }
            else {
                id evaluatedItem = [item evalWithContext:context];
                if (!evaluatedItem || (evaluatedItem == Nu__null)) {
                    // do nothing
                }
                else if ([evaluatedItem isKindOfClass:[NSString class]]) {
                    [body appendString:evaluatedItem];
                }
                else if ([evaluatedItem isKindOfClass:[NSArray class]]) {
                    NSArray *evaluatedArray = (NSArray *) evaluatedItem;
                    NSUInteger max = [evaluatedArray count];
                    for (int i = 0; i < max; i++) {
                        id objectAtIndex = [evaluatedArray objectAtIndex:i];
                        [body appendString:[objectAtIndex stringValue]];
                    }
                }
                else {
                    [body appendString:[evaluatedItem stringValue]];
                }
            }
            if (cursor && (cursor != Nu__null))
                cursor = [cursor cdr];
        }
    }
    
    if (!tag) {
        return body;
    }
    else if ([body length] || !empty) {
        return [NSString stringWithFormat:@"%@<%@%@>%@</%@>", prefix, tag, attributes, body, tag];
    }
    else {
        return [NSString stringWithFormat:@"%@<%@%@/>", prefix, tag, attributes];
    }
}

- (NSString *) tag {return tag;}
- (NSString *) prefix {return prefix;}
- (id) contents {return contents;}
- (BOOL) empty {return empty;}

@end
