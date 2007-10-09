// parser.m
//  Nu source file parser.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "parser.h"
#import "symbol.h"
#import "extensions.h"

#define PARSE_NORMAL     0
#define PARSE_COMMENT    1
#define PARSE_STRING     2
#define PARSE_HERESTRING 3

#include <readline/readline.h>

@interface NuParser(Internal)
- (int) depth;
- (int) parens;
- (int) state;
- (NuCell *) root;
- (NuStack *) opens;
- (id) stringValue;
- (const char *) cStringUsingEncoding:(unsigned int) encoding;
- (void) reset;
- (id) init;
- (void) openList;
- (void) closeList;
- (void) addAtom:(id)atom;
-(void) quoteNextElement;
- (int) interact;
@end

@interface NSMutableString(Nu)
- (void) appendCharacter:(unichar) c;
@end

@implementation NSMutableString(Nu)
- (void) appendCharacter:(unichar) c
{
    [self appendFormat:@"%C", c];
}

@end

extern void load_builtins(NuSymbolTable *);

id atomWithBytesAndLength(const char *bytes, int length, NuSymbolTable *symbolTable)
{
    char c = ((char *) bytes)[length];
    ((char *) bytes)[length] = 0;
    char *endptr;
    // If it can be converted to a long, it's an NSNumber.
    long lvalue = strtol(bytes, &endptr, 0);
    if (*endptr == 0) {
        ((char *) bytes)[length] = c;
        return [NSNumber numberWithLong:lvalue];
    }
    // If it can be converted to a double, it's an NSNumber.
    double dvalue = strtod(bytes, &endptr);
    if (*endptr == 0) {
        ((char *) bytes)[length] = c;
        return [NSNumber numberWithDouble:dvalue];
    }
    // Otherwise, it's a symbol.
    ((char *) bytes)[length] = c;
    NuSymbol *string = [symbolTable symbolWithBytes:bytes length:length];
    return string;
}

id atomWithString(NSString *string, NuSymbolTable *symbolTable)
{
    const char *cstring = [string cStringUsingEncoding:NSUTF8StringEncoding];
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

@implementation NuParser

static BOOL nu_parse_escapes = NO;
+ (BOOL) parseEscapes {return nu_parse_escapes;}
+ (void) setParseEscapes:(BOOL) v {nu_parse_escapes = v;}

- (BOOL) incomplete
{
    return depth > 0;
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

- (id) stringValue
{
    return [self description];
}

- (const char *) cStringUsingEncoding:(unsigned int) encoding
{
    return [[self stringValue] cStringUsingEncoding:encoding];
}

- (void) reset
{
    state = PARSE_NORMAL;
    partial = [NSMutableString string];
    depth = 0;
    parens = 0;
    quoting = 0;
    int i;
    for (i = 0; i < MAXDEPTH; i++) {
        quoteDepth[i] = false;
    }
    root = current = [[NuCell alloc] init];
    [root setCar:[symbolTable symbolWithCString:"progn"]];
    addToCar = false;
    [stack release];
    stack = [[NuStack alloc] init];
}

- (id) init
{
    extern id Nu__null;
    if (Nu__null == 0) Nu__null = [NSNull null];
    [super init];

    linenum = 1;
    column = 0;
    opens = [[NuStack alloc] init];
    // create symbol table and top-level context
    //symbolTable = [[NuSymbolTable alloc] init];
    symbolTable = [[NuSymbolTable sharedSymbolTable] retain];
    context = [[NSMutableDictionary alloc] init];

    // load symbol table
    load_builtins(symbolTable);
    [context setObject:self forKey:[symbolTable symbolWithCString:"_parser"]];
    [context setObject:symbolTable forKey:SYMBOLS_KEY];

    [self reset];
    return self;
}

- (void) dealloc
{
    [context release];
    [symbolTable release];
    [super dealloc];
}

- (void) openList
{
    if (quoting > 0) {
        quoting--;
        [self openList];
        quoteDepth[depth] = true;
        [self addAtom:[symbolTable symbolWithString:@"quote"]];
        [self openList];
        return;
    }
    depth++;
    NuCell *newCell = [[[NuCell alloc] init] autorelease];
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

- (void) closeList
{
    depth--;
    if (addToCar) {
        [current setCar:[NSNull null]];
    }
    else {
        [current setCdr:[NSNull null]];
        current = [stack pop];
    }
    addToCar = false;
    if (quoteDepth[depth]) {
        quoteDepth[depth] = false;
        [self closeList];
    }
}

- (void) addAtom:(id)atom
{
    if (quoting > 0) {
        quoting--;
        [self openList];
        [self addAtom:[symbolTable symbolWithString:@"quote"]];
        [self addAtom:atom];
        [self closeList];
        return;
    }
    NuCell *newCell;
    if (comments) {
        NuCellWithComments *newCellWithComments = [[[NuCellWithComments alloc] init] autorelease];
        [newCellWithComments setComments:comments];
        newCell = newCellWithComments;
        comments = nil;
    }
    else {
        newCell = [[[NuCell alloc] init] autorelease];
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

-(void) quoteNextElement
{
    quoting++;
}

static int nu_octal_digit_value(char c)
{
    int x = (c - '0');
    if ((x >= 0) && (x <= 7))
        return x;
    [NSException raise:@"NuParseError" format:@"invalid octal character: %c", c];
    return 0;
}

static int nu_hex_digit_value(char c)
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
    [NSException raise:@"NuParseError" format:@"invalid hex character: %c", c];
    return 0;
}

static unichar nu_octal_digits_to_unichar(char c0, char c1, char c2)
{
    return nu_octal_digit_value(c0)*64 + nu_octal_digit_value(c1)*8 + nu_octal_digit_value(c2);
}

static unichar nu_hex_digits_to_unichar(char c1, char c2)
{
    return nu_hex_digit_value(c1)*16 + nu_hex_digit_value(c2);
}

static unichar nu_unicode_digits_to_unichar(char c1, char c2, char c3, char c4)
{
    return nu_hex_digit_value(c1)*4096 + nu_hex_digit_value(c2)*256 + nu_hex_digit_value(c3)*16 + nu_hex_digit_value(c4);
}

static int nu_parse_escape_sequences(NSString *string, int i, int imax, NSMutableString *partial)
{
    i++;
    char c = [string characterAtIndex:i];
    switch(c) {
        case 'n': [partial appendCharacter:0x0a]; break;
        case 'r': [partial appendCharacter:0x0d]; break;
        case 'f': [partial appendCharacter:0x0c]; break;
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

-(id) parse:(NSString *)string
{
    if (!string) return [NSNull null];            // don't crash, at least.

    column = 0;
    partial = [NSMutableString string];

    int i = 0;
    int imax = [string length];
    for (i = 0; i < imax; i++) {
        column++;
        unichar stri = [string characterAtIndex:i];
        switch (state) {
            case PARSE_NORMAL:
                switch(stri) {
                    case '(':
                        //	NSLog(@"pushing %d on line %d", column, linenum);
                        [opens push:[NSNumber numberWithInt:column]];
                        parens++;
                        if ([partial length] == 0) {
                            [self openList];
                        }
                        break;
                    case ')':
                        //	NSLog(@"popping");
                        [opens pop];
                        parens--;
                        if (parens < 0) parens = 0;
                        if ([partial length] > 0) {
                            [self addAtom:atomWithString(partial, symbolTable)];
                            partial = [NSMutableString string];
                        }
                        if (depth > 0) {
                            [self closeList];
                        }
                        else {
                            [NSException raise:@"NuParseError" format:@"no open sexpr"];
                        }
                        break;
                    case '"':
                        state = PARSE_STRING;
                        break;
                    case ':':
                        [partial appendCharacter:':'];
                        [self addAtom:atomWithString(partial, symbolTable)];
                        partial = [NSMutableString string];
                        break;
                    case '\'':
                        [self quoteNextElement];
                        break;
                    case '\n':                    // end of line
                        column = 0;
                        linenum++;
                    case ' ':                     // end of token
                    case '\t':
                    case 0:                       // end of string
                        if ([partial length] > 0) {
                            [self addAtom:atomWithString(partial, symbolTable)];
                            partial = [NSMutableString string];
                        }
                        break;
                    case ';':
                    case '#':
                        if ([partial length] > 0) {
                            NuSymbol *symbol = [symbolTable symbolWithString:partial];
                            [self addAtom:symbol];
                            partial = [NSMutableString string];
                        }
                        state = PARSE_COMMENT;
                        break;
                    case '<':
                        if (([string characterAtIndex:i+1] == '<') && ([string characterAtIndex:i+2] == '-')) {
                            // parse a here string
                            // get the tag to match
                            int j = i+3;
                            while ((j < imax) && ([string characterAtIndex:j] != '\n')) {
                                j++;
                            }
                            pattern = [[string substringWithRange:NSMakeRange(i+3, j-(i+3))] retain];
                            //NSLog(@"herestring pattern: %@", pattern);
                            partial = [NSMutableString string];
                            // skip the newline
                            // j++;
                            i = j;
                            //printf("parsing herestring that ends with %s from %s", pattern, &str[start]);
                            state = PARSE_HERESTRING;
                            hereString = nil;
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
                    NSString *string = [[NSString alloc] initWithString:partial];
                    if (!hereString)
                        hereString = [[NSMutableString alloc] init];
                    else
                        [hereString appendString:[NSString carriageReturn]];
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
                    if (nu_parse_escapes && (stri == '\\')) {
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
                        if ([string characterAtIndex:i-1] != '\\') {
                            state = PARSE_NORMAL;
                            NSString *string = [[NSString alloc] initWithString:partial];
                            //NSLog(@"parsed string: %@", string);
                            [self addAtom:string];
                            partial = [NSMutableString string];
                        }
                        break;
                    }
                    case '\n':
                    {
                        column = 0;
                        linenum++;
                        NSString *string = [[NSString alloc] initWithString:partial];
                        [NSException raise:@"NuParseError" format:@"partial string (terminated by newline): %@", string];
                        partial = [NSMutableString string];
                        break;
                    }
                    case '\\':
                    {                             // parse escape sequences in strings
                        if (nu_parse_escapes) {
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
            case PARSE_COMMENT:
                switch(stri) {
                    case '\n':
                    {
                        if (!comments) comments = [[NSMutableString alloc] init];
                        else [comments appendString: [NSString carriageReturn]];
                        [comments appendString: [[NSString alloc] initWithString:partial]];
                        partial = [NSMutableString string];
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
    }
    else if (state == PARSE_COMMENT) {
        if (!comments) comments = [[NSMutableString alloc] init];
        [comments appendString: [[NSString alloc] initWithString:partial]];
        column = 0;
        linenum++;
        state = PARSE_NORMAL;
    }
    else if (state == PARSE_HERESTRING) {
        NSString *partial2 = [[NSString alloc] initWithString:partial];
        if (!hereString)
            hereString = [[NSMutableString alloc] init];
        else
            [hereString appendString:[NSString carriageReturn]];
        [hereString appendString:partial2];
    }
    if ([self incomplete]) {
        return [NSNull null];
    }
    else {
        NuCell *expressions = root;
        root = nil;
        [self reset];
        [expressions autorelease];
        return expressions;
    }
}

- (void) newline
{
    linenum++;
}

- (id) eval: (id) code
{
    return [code evalWithContext:context];
}

- (NSString *) parseEval:(NSString *)string
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NuCell *expressions = [self parse:string];
    id result = [[expressions evalWithContext:context] stringValue];
    [result retain];
    [pool release];
    [result autorelease];
    return result;
}

- (int) interact
{
    printf("Nu Shell.\n");
    do {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        char *prompt = ([self incomplete] ? "- " : "% ");
        char *line = readline(prompt);
        if (line && *line)
            add_history (line);
        if(!line || !strcmp(line, "quit")) {
            break;
        }
        else {
            id progn = nil;
            @try
            {
                progn = [[self parse:[NSString stringWithCString:line encoding:NSUTF8StringEncoding]] retain];
            }
            @catch (id exception) {
                printf("%s: %s\n",
                    [[exception name] cStringUsingEncoding:NSUTF8StringEncoding],
                    [[exception reason] cStringUsingEncoding:NSUTF8StringEncoding]);
                [self reset];
            }
            if (progn && (progn != [NSNull null])) {
                id cursor = [progn cdr];
                while (cursor && (cursor != [NSNull null])) {
                    if ([cursor car] != [NSNull null]) {
                        id expression = [cursor car];
                        //printf("evaluating %s\n", [[expression stringValue] cStringUsingEncoding:NSUTF8StringEncoding]);
                        @try
                        {
                            id result = [[cursor car] evalWithContext:context];
                            printf("%s\n", [[result stringValue] cStringUsingEncoding:NSUTF8StringEncoding]);
                        }
                        @catch (id exception) {
                            printf("%s: %s\n",
                                [[exception name] cStringUsingEncoding:NSUTF8StringEncoding],
                                [[exception reason] cStringUsingEncoding:NSUTF8StringEncoding]);
                        }
                    }
                    cursor = [cursor cdr];
                }
            }
            [progn release];
        }
        [pool release];
    } while(1);
    return 0;
}

+ (int) main
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NuParser *parser = [[NuParser alloc] init];
    int result = [parser interact];
    [parser release];
    [pool release];
    return result;
}

@end
