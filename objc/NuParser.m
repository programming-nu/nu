//
//  NuParser.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuParser.h"
#import "Nu.h"
#import "NuInternals.h"
#import "NuStack.h"
#import "NSString+Nu.h"
#import "NSDictionary+Nu.h"
#import "NuException.h"
#import "NuCell.h"
#if !TARGET_OS_IPHONE
#include <readline/readline.h>
#include <readline/history.h>
#endif

#define PARSE_NORMAL     0
#define PARSE_COMMENT    1
#define PARSE_STRING     2
#define PARSE_HERESTRING 3
#define PARSE_REGEX      4

#define MAX_FILES 1024
static char *filenames[MAX_FILES];
static int filecount = 0;

// Turn debug output on and off for this file only
//#define PARSER_DEBUG 1

#ifdef PARSER_DEBUG
#define ParserDebug(arg...) NSLog(arg)
#else
#define ParserDebug(arg...)
#endif

const char *nu_parsedFilename(int i)
{
    return (i < 0) ? NULL: filenames[i];
}

@interface NuParser(Internal)
- (int) depth;
- (int) parens;
- (int) state;
- (NuCell *) root;
- (NuStack *) opens;
- (NSString *) stringValue;
- (const char *) UTF8String;
- (id) init;
- (void) openList;
- (void) closeList;
- (void) addAtom:(id)atom;
- (void) quoteNextElement;
- (void) quasiquoteNextElement;
- (void) quasiquoteEvalNextElement;
- (void) quasiquoteSpliceNextElement;
- (int) interact;
@end

static id atomWithString(NSString *string, NuSymbolTable *symbolTable)
{
    const char *cstring = [string UTF8String];
    char *endptr;
    // If the string can be converted to a long, it's an NSNumber.
    long lvalue = strtol(cstring, &endptr, 0);
    if (*endptr == 0) {
        return [NSNumber numberWithLong:lvalue];
    }
    // If the string can be converted to a double, it's an NSNumber.
    double dvalue = strtod(cstring, &endptr);
    if (*endptr == 0) {
        return [NSNumber numberWithDouble:dvalue];
    }
    // Otherwise, it's a symbol.
    NuSymbol *symbol = [symbolTable symbolWithString:string];
    return symbol;
}

static id regexWithString(NSString *string)
{
    // If the first character of the string is a forward slash, it's a regular expression literal.
    if (([string characterAtIndex:0] == '/') && ([string length] > 1)) {
        NSUInteger lastSlash = [string length];
        NSInteger i = lastSlash-1;
        while (i > 0) {
            if ([string characterAtIndex:i] == '/') {
                lastSlash = i;
                break;
            }
            i--;
        }
        // characters after the last slash specify options.
        NSInteger options = 0;
        NSInteger j;
        for (j = lastSlash+1; j < [string length]; j++) {
            unichar c = [string characterAtIndex:j];
            switch (c) {
                case 'i': options += NSRegularExpressionCaseInsensitive; break;
                case 's': options += NSRegularExpressionDotMatchesLineSeparators; break;
                case 'x': options += NSRegularExpressionAllowCommentsAndWhitespace; break;
                case 'm': options += NSRegularExpressionAnchorsMatchLines; break; // multiline
                default:
                    [NSException raise:@"NuParseError" format:@"unsupported regular expression option character: %C", c];
            }
        }
        NSString *pattern = [string substringWithRange:NSMakeRange(1, lastSlash-1)];
        return [NSRegularExpression regularExpressionWithPattern:pattern
                                                         options:options
                                                           error:NULL];
    }
    else {
        return nil;
    }
}

#define NU_MAX_PARSER_MACRO_DEPTH 1000

@interface NuParser ()
{
    int state;
    int start;
    int depth;
    int parens;
    int column;
    
    NSMutableArray* readerMacroStack;
    int readerMacroDepth[NU_MAX_PARSER_MACRO_DEPTH];
    
    int filenum;
    int linenum;
    int parseEscapes;
    
    NuCell *root;
    NuCell *current;
    bool addToCar;
    NSMutableString *hereString;
    bool hereStringOpened;
    NuStack *stack;
    NuStack *opens;
    NuSymbolTable *symbolTable;
    NSMutableDictionary *context;
    NSMutableString *partial;
    NSMutableString *comments;
    NSString *pattern;                            // used for herestrings
}
@end

@implementation NuParser

+ (const char *) filename:(int)i
{
    if ((i < 0) || (i >= filecount))
        return "";
    else
        return filenames[i];
}

- (void) setFilename:(const char *) name
{
    if (name == NULL)
        filenum = -1;
    else {
        filenames[filecount] = strdup(name);
        filenum = filecount;
        filecount++;
    }
    linenum = 1;
}

- (const char *) filename
{
    if (filenum == -1)
        return NULL;
    else
        return filenames[filenum];
}

- (BOOL) incomplete
{
    return (depth > 0) || (state == PARSE_REGEX) || (state == PARSE_HERESTRING);
}

- (int) depth
{
    return depth;
}

- (int) parens
{
    return parens;
}

- (int) state
{
    return state;
}

- (NuCell *) root
{
    return [root cdr];
}

- (NuStack *) opens
{
    return opens;
}

- (NSMutableDictionary *) context
{
    return context;
}

- (NuSymbolTable *) symbolTable
{
    return symbolTable;
}

- (NSString *) stringValue
{
    return [self description];
}

- (const char *) UTF8String
{
    return [[self stringValue] UTF8String];
}

- (void) reset
{
    state = PARSE_NORMAL;
    [partial setString:@""];
    depth = 0;
    parens = 0;
    
    [readerMacroStack removeAllObjects];
    
    int i;
    for (i = 0; i < NU_MAX_PARSER_MACRO_DEPTH; i++) {
        readerMacroDepth[i] = 0;
    }
    
    [root release];
    root = current = [[NuCell alloc] init];
    [root setFile:filenum line:linenum];
    [root setCar:[symbolTable symbolWithString:@"progn"]];
    addToCar = false;
    [stack release];
    stack = [[NuStack alloc] init];
}

- (id) init
{
    if (Nu__null == 0) Nu__null = [NSNull null];
    if ((self = [super init])) {
        
        filenum = -1;
        linenum = 1;
        column = 0;
        opens = [[NuStack alloc] init];
        // attach to symbol table (or create one if we want a separate table per parser)
        symbolTable = [[NuSymbolTable sharedSymbolTable] retain];
        // create top-level context
        context = [[NSMutableDictionary alloc] init];
        
        readerMacroStack = [[NSMutableArray alloc] init];
        
        [context setPossiblyNullObject:self forKey:[symbolTable symbolWithString:@"_parser"]];
        [context setPossiblyNullObject:symbolTable forKey:SYMBOLS_KEY];
        
        partial = [[NSMutableString alloc] initWithString:@""];
        
        [self reset];
    }
    return self;
}

- (void) close
{
    // break this retain cycle so the parser can be deleted.
    [context setPossiblyNullObject:Nu__null forKey:[symbolTable symbolWithString:@"_parser"]];
}

- (void) dealloc
{
    [opens release];
    [context release];
    [symbolTable release];
    [root release];
    [stack release];
    [comments release];
    [readerMacroStack release];
    [pattern release];
    [partial release];
    [super dealloc];
}

- (void) addAtomCell:(id)atom
{
    ParserDebug(@"addAtomCell: depth = %d  atom = %@", depth, [atom stringValue]);
    
    // when we have two consecutive labels, concatenate them.
    // this allows us to have ':' characters inside labels.
    if ([atom isKindOfClass:[NuSymbol class]] && [atom isLabel]) {
        id currentCar = [current car];
        if ([currentCar isKindOfClass:[NuSymbol class]] && [currentCar isLabel]) {
            NuSymbol *combinedLabel = [symbolTable symbolWithString:[[currentCar stringValue] stringByAppendingString:[atom stringValue]]];
            [current setCar:combinedLabel];
            return;
        }
    }
    
    NuCell *newCell;
    if (comments) {
        NuCellWithComments *newCellWithComments = [[[NuCellWithComments alloc] init] autorelease];
        [newCellWithComments setComments:comments];
        newCell = newCellWithComments;
        [comments release];
        comments = nil;
    }
    else {
        newCell = [[[NuCell alloc] init] autorelease];
        [newCell setFile:filenum line:linenum];
    }
    if (addToCar) {
        [current setCar:newCell];
        [stack push:current];
    }
    else {
        [current setCdr:newCell];
    }
    current = newCell;
    [current setCar:atom];
    addToCar = false;
}

- (void) openListCell
{
    ParserDebug(@"openListCell: depth = %d", depth);
    
    depth++;
    NuCell *newCell = [[[NuCell alloc] init] autorelease];
    [newCell setFile:filenum line:linenum];
    if (addToCar) {
        [current setCar:newCell];
        [stack push:current];
    }
    else {
        [current setCdr:newCell];
    }
    current = newCell;
    
    addToCar = true;
}

- (void) openList
{
    ParserDebug(@"openList: depth = %d", depth);
    
    while ([readerMacroStack count] > 0) {
        ParserDebug(@"  openList: readerMacro");
        
        [self openListCell];
        ++readerMacroDepth[depth];
        ParserDebug(@"  openList: ++RMD[%d] = %d", depth, readerMacroDepth[depth]);
        [self addAtomCell:
         [symbolTable symbolWithString:
          [readerMacroStack objectAtIndex:0]]];
        
        [readerMacroStack removeObjectAtIndex:0];
    }
    
    [self openListCell];
}

- (void) addAtom:(id)atom
{
    ParserDebug(@"addAtom: depth = %d  atom: %@", depth, [atom stringValue]);
    
    while ([readerMacroStack count] > 0) {
        ParserDebug(@"  addAtom: readerMacro");
        [self openListCell];
        ++readerMacroDepth[depth];
        ParserDebug(@"  addAtom: ++RMD[%d] = %d", depth, readerMacroDepth[depth]);
        [self addAtomCell:
         [symbolTable symbolWithString:[readerMacroStack objectAtIndex:0]]];
        
        [readerMacroStack removeObjectAtIndex:0];
    }
    
    [self addAtomCell:atom];
    
    while (readerMacroDepth[depth] > 0) {
        --readerMacroDepth[depth];
        ParserDebug(@"  addAtom: --RMD[%d] = %d", depth, readerMacroDepth[depth]);
        [self closeList];
    }
}

- (void) closeListCell
{
    ParserDebug(@"closeListCell: depth = %d", depth);
    
    --depth;
    
    if (addToCar) {
        [current setCar:Nu__null];
    }
    else {
        [current setCdr:Nu__null];
        current = [stack pop];
    }
    addToCar = false;
    
    while (readerMacroDepth[depth] > 0) {
        --readerMacroDepth[depth];
        ParserDebug(@"  closeListCell: --RMD[%d] = %d", depth, readerMacroDepth[depth]);
        [self closeList];
    }
}

- (void) closeList
{
    ParserDebug(@"closeList: depth = %d", depth);
    
    [self closeListCell];
}

-(void) openReaderMacro:(NSString*) operator
{
    [readerMacroStack addObject:operator];
}

-(void) quoteNextElement
{
    [self openReaderMacro:@"quote"];
}

-(void) quasiquoteNextElement
{
    [self openReaderMacro:@"quasiquote"];
}

-(void) quasiquoteEvalNextElement
{
    [self openReaderMacro:@"quasiquote-eval"];
}

-(void) quasiquoteSpliceNextElement
{
    [self openReaderMacro:@"quasiquote-splice"];
}

static int nu_octal_digit_value(unichar c)
{
    int x = (c - '0');
    if ((x >= 0) && (x <= 7))
        return x;
    [NSException raise:@"NuParseError" format:@"invalid octal character: %C", c];
    return 0;
}

static unichar nu_hex_digit_value(unichar c)
{
    int x = (c - '0');
    if ((x >= 0) && (x <= 9))
        return x;
    x = (c - 'A');
    if ((x >= 0) && (x <= 5))
        return x + 10;
    x = (c - 'a');
    if ((x >= 0) && (x <= 5))
        return x + 10;
    [NSException raise:@"NuParseError" format:@"invalid hex character: %C", c];
    return 0;
}

static unichar nu_octal_digits_to_unichar(unichar c0, unichar c1, unichar c2)
{
    return nu_octal_digit_value(c0)*64 + nu_octal_digit_value(c1)*8 + nu_octal_digit_value(c2);
}

static unichar nu_hex_digits_to_unichar(unichar c1, unichar c2)
{
    return nu_hex_digit_value(c1)*16 + nu_hex_digit_value(c2);
}

static unichar nu_unicode_digits_to_unichar(unichar c1, unichar c2, unichar c3, unichar c4)
{
    unichar value = nu_hex_digit_value(c1)*4096 + nu_hex_digit_value(c2)*256 + nu_hex_digit_value(c3)*16 + nu_hex_digit_value(c4);
    return value;
}

static NSUInteger nu_parse_escape_sequences(NSString *string, NSUInteger i, NSUInteger imax, NSMutableString *partial)
{
    i++;
    unichar c = [string characterAtIndex:i];
    switch(c) {
        case 'n': [partial appendCharacter:0x0a]; break;
        case 'r': [partial appendCharacter:0x0d]; break;
        case 'f': [partial appendCharacter:0x0c]; break;
        case 't': [partial appendCharacter:0x09]; break;
        case 'b': [partial appendCharacter:0x08]; break;
        case 'a': [partial appendCharacter:0x07]; break;
        case 'e': [partial appendCharacter:0x1b]; break;
        case 's': [partial appendCharacter:0x20]; break;
        case '0': case '1': case '2': case '3': case '4':
        case '5': case '6': case '7': case '8': case '9':
        {
            // octal. expect two more digits (\nnn).
            if (imax < i+2) {
                [NSException raise:@"NuParseError" format:@"not enough characters for octal constant"];
            }
            char c1 = [string characterAtIndex:++i];
            char c2 = [string characterAtIndex:++i];
            [partial appendCharacter:nu_octal_digits_to_unichar(c, c1, c2)];
            break;
        }
        case 'x':
        {
            // hex. expect two more digits (\xnn).
            if (imax < i+2) {
                [NSException raise:@"NuParseError" format:@"not enough characters for hex constant"];
            }
            char c1 = [string characterAtIndex:++i];
            char c2 = [string characterAtIndex:++i];
            [partial appendCharacter:nu_hex_digits_to_unichar(c1, c2)];
            break;
        }
        case 'u':
        {
            // unicode. expect four more digits (\unnnn)
            if (imax < i+4) {
                [NSException raise:@"NuParseError" format:@"not enough characters for unicode constant"];
            }
            char c1 = [string characterAtIndex:++i];
            char c2 = [string characterAtIndex:++i];
            char c3 = [string characterAtIndex:++i];
            char c4 = [string characterAtIndex:++i];
            [partial appendCharacter:nu_unicode_digits_to_unichar(c1, c2, c3, c4)];
            break;
        }
        case 'c': case 'C':
        {
            // control character.  Unsupported, fall through to default.
        }
        case 'M':
        {
            // meta character. Unsupported, fall through to default.
        }
        default:
            [partial appendCharacter:c];
    }
    return i;
}

-(id) parse:(NSString*)string
{
    if (!string) return Nu__null;            // don't crash, at least.
    
    column = 0;
    if (state != PARSE_REGEX)
        [partial setString:@""];
    else
        [partial autorelease];
    
    NSUInteger i = 0;
    NSUInteger imax = [string length];
    for (i = 0; i < imax; i++) {
        column++;
        unichar stri = [string characterAtIndex:i];
        switch (state) {
            case PARSE_NORMAL:
                switch(stri) {
                    case '(':
                        ParserDebug(@"Parser: (  %d on line %d", column, linenum);
                        [opens push:@(column)];
                        parens++;
                        if ([partial length] == 0) {
                            [self openList];
                        }
                        break;
                    case ')':
                        ParserDebug(@"Parser: )  %d on line %d", column, linenum);
                        [opens pop];
                        parens--;
                        if (parens < 0) parens = 0;
                        if ([partial length] > 0) {
                            [self addAtom:atomWithString(partial, symbolTable)];
                            [partial setString:@""];
                        }
                        if (depth > 0) {
                            [self closeList];
                        }
                        else {
                            [NSException raise:@"NuParseError" format:@"no open sexpr"];
                        }
                        break;
                    case '"':
                    {
                        state = PARSE_STRING;
                        parseEscapes = YES;
                        [partial setString:@""];
                        break;
                    }
                    case '-':
                    case '+':
                    {
                        if ((i+1 < imax) && ([string characterAtIndex:i+1] == '"')) {
                            state = PARSE_STRING;
                            parseEscapes = (stri == '+');
                            [partial setString:@""];
                            i++;
                        }
                        else {
                            [partial appendCharacter:stri];
                        }
                        break;
                    }
                    case '/':
                    {
                        if (i+1 < imax) {
                            unichar nextc = [string characterAtIndex:i+1];
                            if (nextc == ' ') {
                                [partial appendCharacter:stri];
                            }
                            else {
                                state = PARSE_REGEX;
                                [partial setString:@""];
                                [partial appendCharacter:'/'];
                            }
                        }
                        else {
                            [partial appendCharacter:stri];
                        }
                        break;
                    }
                    case ':':
                        [partial appendCharacter:':'];
                        // ordinarily we break symbols on trailing colons.
                        // one exception: we don't do it when the symbol begins with an ampersand.
                        // that's because these symbols are usually markup generators, and
                        // sometimes we want to generate markup tags that contain colons.
                        if ([partial characterAtIndex:0] != '&') {
                            [self addAtom:atomWithString(partial, symbolTable)];
                            [partial setString:@""];
                        }
                        break;
                    case '\'':
                    {
                        // try to parse a character literal.
                        // if that doesn't work, then interpret the quote as the quote operator.
                        bool isACharacterLiteral = false;
                        int characterLiteralValue = 0;
                        if (i + 2 < imax) {
                            if ([string characterAtIndex:i+1] != '\\') {
                                if ([string characterAtIndex:i+2] == '\'') {
                                    isACharacterLiteral = true;
                                    characterLiteralValue = [string characterAtIndex:i+1];
                                    i = i + 2;
                                }
                                else if ((i + 5 < imax) &&
                                         isalnum([string characterAtIndex:i+1]) &&
                                         isalnum([string characterAtIndex:i+2]) &&
                                         isalnum([string characterAtIndex:i+3]) &&
                                         isalnum([string characterAtIndex:i+4]) &&
                                         ([string characterAtIndex:i+5] == '\'')) {
                                    characterLiteralValue =
                                    ((([string characterAtIndex:i+1]*256
                                       + [string characterAtIndex:i+2])*256
                                      + [string characterAtIndex:i+3])*256
                                     + [string characterAtIndex:i+4]);
                                    isACharacterLiteral = true;
                                    i = i + 5;
                                }
                            }
                            else {
                                // look for an escaped character
                                NSUInteger newi = nu_parse_escape_sequences(string, i+1, imax, partial);
                                if ([partial length] > 0) {
                                    isACharacterLiteral = true;
                                    characterLiteralValue = [partial characterAtIndex:0];
                                    [partial setString:@""];
                                    i = newi;
                                    // make sure that we have a closing single-quote
                                    if ((i + 1 < imax) && ([string characterAtIndex:i+1] == '\'')) {
                                        i = i + 1;// move past the closing single-quote
                                    }
                                    else {
                                        [NSException raise:@"NuParseError" format:@"missing close quote from character literal"];
                                    }
                                }
                            }
                        }
                        if (isACharacterLiteral) {
                            [self addAtom:@(characterLiteralValue)];
                        }
                        else {
                            [self quoteNextElement];
                        }
                        break;
                    }
					case '~':
					{
						[self quasiquoteEvalNextElement];
						[self quoteNextElement];
						break;
					}
                    case '`':
                    {
                        [self quasiquoteNextElement];
                        break;
                    }
                    case ',':
                    {
                        if ((i + 1 < imax) && ([string characterAtIndex:i+1] == '@')) {
                            [self quasiquoteSpliceNextElement];
                            i = i + 1;
                        }
                        else {
                            [self quasiquoteEvalNextElement];
                        }
                        break;
                    }
                    case '\n':                    // end of line
                        column = 0;
                        linenum++;
                    case ' ':                     // end of token
                    case '\t':
                    case 0:                       // end of string
                        if ([partial length] > 0) {
                            [self addAtom:atomWithString(partial, symbolTable)];
                            [partial setString:@""];
                        }
                        break;
                    case ';':
                    case '#':
                        if ((stri == '#') && ([partial length] > 0)) {
                            // this allows us to include '#' in symbols (but not as the first character)
                            [partial appendCharacter:'#'];
                        } else {
                            if ([partial length]) {
                                NuSymbol *symbol = [symbolTable symbolWithString:partial];
                                [self addAtom:symbol];
                                [partial setString:@""];
                            }
                            state = PARSE_COMMENT;
                        }
                        break;
                    case '<':
                        if ((i+3 < imax) && ([string characterAtIndex:i+1] == '<')
                            && (([string characterAtIndex:i+2] == '-') || ([string characterAtIndex:i+2] == '+'))) {
                            // parse a here string
                            state = PARSE_HERESTRING;
                            parseEscapes = ([string characterAtIndex:i+2] == '+');
                            // get the tag to match
                            NSUInteger j = i+3;
                            while ((j < imax) && ([string characterAtIndex:j] != '\n')) {
                                j++;
                            }
                            [pattern release];
                            pattern = [[string substringWithRange:NSMakeRange(i+3, j-(i+3))] retain];
                            //NSLog(@"herestring pattern: %@", pattern);
                            [partial setString:@""];
                            // skip the newline
                            i = j;
                            //NSLog(@"parsing herestring that ends with %@ from %@", pattern, [string substringFromIndex:i]);
                            hereString = nil;
                            hereStringOpened = true;
                            break;
                        }
                        // if this is not a here string, fall through to the general handler
                    default:
                        [partial appendCharacter:stri];
                }
                break;
            case PARSE_HERESTRING:
                //NSLog(@"pattern %@", pattern);
                if ((stri == [pattern characterAtIndex:0]) &&
                    (i + [pattern length] < imax) &&
                    ([pattern isEqual:[string substringWithRange:NSMakeRange(i, [pattern length])]])) {
                    // everything up to here is the string
                    NSString *string = [[[NSString alloc] initWithString:partial] autorelease];
                    [partial setString:@""];
                    if (!hereString)
                        hereString = [[[NSMutableString alloc] init] autorelease];
                    else
                        [hereString appendString:@"\n"];
                    [hereString appendString:string];
                    if (hereString == nil)
                        hereString = [NSMutableString string];
                    //NSLog(@"got herestring **%@**", hereString);
                    [self addAtom:hereString];
                    // to continue, set i to point to the next character after the tag
                    i = i + [pattern length] - 1;
                    //NSLog(@"continuing parsing with:%s", &str[i+1]);
                    //NSLog(@"ok------------");
                    state = PARSE_NORMAL;
                    start = -1;
                }
                else {
                    if (parseEscapes && (stri == '\\')) {
                        // parse escape sequencs in here strings
                        i = nu_parse_escape_sequences(string, i, imax, partial);
                    }
                    else {
                        [partial appendCharacter:stri];
                    }
                }
                break;
            case PARSE_STRING:
                switch(stri) {
                    case '"':
                    {
                        state = PARSE_NORMAL;
                        NSString *string = [NSString stringWithString:partial];
                        //NSLog(@"parsed string:%@:", string);
                        [self addAtom:string];
                        [partial setString:@""];
                        break;
                    }
                    case '\n':
                    {
                        column = 0;
                        linenum++;
                        NSString *string = [[NSString alloc] initWithString:partial];
                        [NSException raise:@"NuParseError" format:@"partial string (terminated by newline): %@", string];
                        [partial setString:@""];
                        break;
                    }
                    case '\\':
                    {                             // parse escape sequences in strings
                        if (parseEscapes) {
                            i = nu_parse_escape_sequences(string, i, imax, partial);
                        }
                        else {
                            [partial appendCharacter:stri];
                        }
                        break;
                    }
                    default:
                    {
                        [partial appendCharacter:stri];
                    }
                }
                break;
            case PARSE_REGEX:
                switch(stri) {
                    case '/':                     // that's the end of it
                    {
                        [partial appendCharacter:'/'];
                        i++;
                        // add any remaining option characters
                        while (i < imax) {
                            unichar nextc = [string characterAtIndex:i];
                            if ((nextc >= 'a') && (nextc <= 'z')) {
                                [partial appendCharacter:nextc];
                                i++;
                            }
                            else {
                                i--;              // back up to revisit this character
                                break;
                            }
                        }
                        [self addAtom:regexWithString(partial)];
                        [partial setString:@""];
                        state = PARSE_NORMAL;
                        break;
                    }
                    case '\\':
                    {
                        [partial appendCharacter:stri];
                        i++;
                        [partial appendCharacter:[string characterAtIndex:i]];
                        break;
                    }
                    default:
                    {
                        [partial appendCharacter:stri];
                    }
                }
                break;
            case PARSE_COMMENT:
                switch(stri) {
                    case '\n':
                    {
                        if (!comments) comments = [[NSMutableString alloc] init];
                        else [comments appendString:@"\n"];
                        [comments appendString:[[[NSString alloc] initWithString:partial] autorelease]];
                        [partial setString:@""];
                        column = 0;
                        linenum++;
                        state = PARSE_NORMAL;
                        break;
                    }
                    default:
                    {
                        [partial appendCharacter:stri];
                    }
                }
        }
    }
    // close off anything that is still being scanned.
    if (state == PARSE_NORMAL) {
        if ([partial length] > 0) {
            [self addAtom:atomWithString(partial, symbolTable)];
        }
        [partial setString:@""];
    }
    else if (state == PARSE_COMMENT) {
        if (!comments) comments = [[NSMutableString alloc] init];
        [comments appendString:[[[NSString alloc] initWithString:partial] autorelease]];
        [partial setString:@""];
        column = 0;
        linenum++;
        state = PARSE_NORMAL;
    }
    else if (state == PARSE_STRING) {
        [NSException raise:@"NuParseError" format:@"partial string (terminated by newline): %@", partial];
    }
    else if (state == PARSE_HERESTRING) {
        if (hereStringOpened) {
            hereStringOpened = false;
        }
        else {
            if (hereString) {
                [hereString appendString:@"\n"];
            }
            else {
                hereString = [[NSMutableString alloc] init];
            }
            [hereString appendString:partial];
            [partial setString:@""];
        }
    }
    else if (state == PARSE_REGEX) {
        // we stay in this state and leave the regex open.
        [partial appendCharacter:'\n'];
        [partial retain];
    }
    if ([self incomplete]) {
        return Nu__null;
    }
    else {
        NuCell *expressions = root;
        root = nil;
        [self reset];
        [expressions autorelease];
        return expressions;
    }
}

- (id) parse:(NSString *)string asIfFromFilename:(const char *) filename;
{
    [self setFilename:filename];
    id result = [self parse:string];
    [self setFilename:NULL];
    return result;
}

- (void) newline
{
    linenum++;
}

- (id) eval: (id) code
{
    return [code evalWithContext:context];
}

- (id) valueForKey:(NSString *)string
{
    return [self eval:[self parse:string]];
}

- (void) setValue:(id)value forKey:(NSString *)string
{
    [context setObject:value forKey:[symbolTable symbolWithString:string]];
}

- (NSString *) parseEval:(NSString *)string
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NuCell *expressions = [self parse:string];
    id result = [[expressions evalWithContext:context] stringValue];
    [result retain];
    [pool drain];
    [result autorelease];
    return result;
}

#if !TARGET_OS_IPHONE
- (int) interact
{
    printf("Nu Shell.\n");
    
    char* homedir = getenv("HOME");
    char  history_file[FILENAME_MAX];
    int   valid_history_file = 0;
    
    if (homedir) {                                // Not likely, but could be NULL
        // Since we're getting something from the shell environment,
        // try to be safe about it
        int n = snprintf(history_file, FILENAME_MAX, "%s/.nush_history", homedir);
        if (n <=  FILENAME_MAX) {
            read_history(history_file);
            valid_history_file = 1;
        }
    }
    
    const char *unbufferedIO = getenv("NSUnbufferedIO");
    if (unbufferedIO && !strcmp(unbufferedIO, "YES")) {
        system("stty -echo"); // Turn off echoing to avoid duplicated input. Surely there's a better way to do this.
        puts("It looks like you are running in the Xcode debugger console. Beware: command history is broken.");
    }
    
    do {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        char *prompt = ([self incomplete] ? "- " : "% ");
#ifdef IPHONENOREADLINE
        puts(prompt);
        char line[1024];                          // careful
        int count = gets(line);
#else
        char *line = readline(prompt);
        if (line && *line && strcmp(line, "quit"))
            add_history (line);
#endif
        if(!line || !strcmp(line, "quit")) {
            break;
        }
        else {
            id progn = nil;
            
            @try
            {
                progn = [[self parse:[NSString stringWithCString:line encoding:NSUTF8StringEncoding]] retain];
            }
            @catch (NuException* nuException) {
                printf("%s\n", [[nuException dump] UTF8String]);
                [self reset];
            }
            @catch (id exception) {
                printf("%s: %s\n",
                       [[exception name] UTF8String],
                       [[exception reason] UTF8String]);
                [self reset];
            }
            
            if (progn && (progn != Nu__null)) {
                id cursor = [progn cdr];
                while (cursor && (cursor != Nu__null)) {
                    if ([cursor car] != Nu__null) {
                        id expression = [cursor car];
                        //printf("evaluating %s\n", [[expression stringValue] UTF8String]);
                        
                        @try
                        {
                            id result = [expression evalWithContext:context];
                            if (result) {
                                id stringToDisplay;
                                if ([result respondsToSelector:@selector(escapedStringRepresentation)]) {
                                    stringToDisplay = [result escapedStringRepresentation];
                                }
                                else {
                                    stringToDisplay = [result stringValue];
                                }
                                printf("%s\n", [stringToDisplay UTF8String]);
                            }
                        }
                        @catch (NuException* nuException) {
                            printf("%s\n", [[nuException dump] UTF8String]);
                        }
                        @catch (id exception) {
                            printf("%s: %s\n",
                                   [[exception name] UTF8String],
                                   [[exception reason] UTF8String]);
                        }
                    }
                    cursor = [cursor cdr];
                }
            }
            [progn release];
        }
        [pool release];
    } while(1);
    
    if (valid_history_file) {
        write_history(history_file);
    }
    
    return 0;
}
#endif
+ (int) main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NuParser *parser = [Nu sharedParser];
    int result = [parser interact];
    [pool drain];
    return result;
}

@end
