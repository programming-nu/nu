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

@implementation NuParser

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
    start = -1;
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
        [self addAtom:[symbolTable symbolWithCString:"quote"]];
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
        [self addAtom:[symbolTable symbolWithCString:"quote"]];
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

static char pattern[1000];

-(id) parse:(NSString *)string
{
    if (!string) return [NSNull null];            // don't crash, at least.

    column = 0;
    const char *str = [string cStringUsingEncoding:NSUTF8StringEncoding];

    int i = 0;
    int imax = strlen(str)+1;
    for (i = 0; i < imax; i++) {
        column++;
        switch (state) {
            case PARSE_NORMAL:
                switch(str[i]) {
                    case '(':
                        //	NSLog(@"pushing %d on line %d", column, linenum);
                        [opens push:[NSNumber numberWithInt:column]];
                        parens++;
                        if (start == -1) {
                            [self openList];
                        }
                        break;
                    case ')':
                        //	NSLog(@"popping");
                        [opens pop];
                        parens--;
                        if (parens < 0) parens = 0;
                        if (start != -1) {
                            [self addAtom:atomWithBytesAndLength(&str[start], i-start, symbolTable)];
                            start = -1;
                        }
                        if (depth > 0) {
                            [self closeList];
                        }
                        else {
                            [NSException raise:@"NuParseError" format:@"no open sexpr"];
                            //[NSException raise:@"NuParseError" format:@"line %d, no open sexpr", linenum];
                        }

                        break;
                    case '"':
                        state = PARSE_STRING;
                        if (start == -1)
                            start = i;
                        break;
                    case ':':
                        if (start != -1) {
                            [self addAtom:atomWithBytesAndLength(&str[start], i-start+1, symbolTable)];
                            start = -1;
                        }
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
                        if (start != -1) {
                            [self addAtom:atomWithBytesAndLength(&str[start], i-start, symbolTable)];
                            start = -1;
                        }
                        break;
                    case ';':
                    case '#':
                        if (start != -1) {
                            NuSymbol *symbol = [symbolTable symbolWithBytes:&str[start] length:(i-start)];
                            [self addAtom:symbol];
                        }
                        start = i;
                        state = PARSE_COMMENT;
                        break;
                    case '<':
                        if ((str[i+1] == '<') && (str[i+2] == '-')) {
                            // parse a here string
                            // get the tag to match
                            int j = i+3;
                            while ((str[j] != '\n') && (j < imax)) j++;
                            strncpy(pattern, &str[i+3], j-(i+3));
                            pattern[j-(i+3)] = '\0';
                            // skip the newline
                            // j++;
                            i = j;
                            start = i+1;
                            //printf("parsing herestring that ends with %s from %s", pattern, &str[start]);
                            state = PARSE_HERESTRING;
                            hereString = nil;
                            break;
                        }
                        // if this is not a here string, fall through to the general handler
                    default:
                        if (start == -1)
                            start = i;
                }
                break;
            case PARSE_HERESTRING:
                if ((str[i] == pattern[0]) && !strncmp(&(str[i]), pattern, strlen(pattern))) {
                    // everything up to here is the string
                    if (i-start > 0) {
                        NSString *string = [[NSString alloc] initWithBytes:&str[start] length:(i-start) encoding:NSUTF8StringEncoding];
                        if (!hereString)
                            hereString = [[NSMutableString alloc] init];
                        else
                            [hereString appendString:[NSString carriageReturn]];
                        [hereString appendString:string];
                    }
                    if (hereString == nil)
                        hereString = [NSMutableString string];
                    //NSLog(@"got herestring **%@**", hereString);
                    [self addAtom:hereString];
                    // to continue, set i to point to the next character after the tag
                    i = i + strlen(pattern)-1;
                    //NSLog(@"continuing parsing with:%s", &str[i+1]);
                    //NSLog(@"ok------------");
                    state = PARSE_NORMAL;
                    start = -1;
                }
                break;
            case PARSE_STRING:
                switch(str[i]) {
                    case '"':
                    {
                        if (str[i-1] != '\\') {
                            state = PARSE_NORMAL;
                            NSString *string = [[NSString alloc] initWithBytes:&str[start+1] length:(i-start-1) encoding:NSUTF8StringEncoding];
                            //NSLog(@"parsed string: %@", string);
                            [self addAtom:string];
                            start = -1;
                        }
                        break;
                    }
                    case '\n':
                    {
                        column = 0;
                        linenum++;
                        NSString *string = [[NSString alloc] initWithBytes:&str[start] length:(i-start) encoding:NSUTF8StringEncoding];
                        [NSException raise:@"NuParseError" format:@"partial string (terminated by newline): %@", string];
                        start = 0;
                        break;
                    }
                }
                break;
            case PARSE_COMMENT:
                switch(str[i]) {
                    case '\n':
                    {
                        if (!comments) comments = [[NSMutableString alloc] init];
                        else [comments appendString: [NSString carriageReturn]];
                        [comments appendString: [[NSString alloc] initWithBytes:&str[start] length:(i-start) encoding:NSUTF8StringEncoding]];
                        column = 0;
                        linenum++;
                        state = PARSE_NORMAL;
                        start = -1;
                        break;
                    }
                }
        }
    }
    if (state == PARSE_COMMENT) {
        if (!comments) comments = [[NSMutableString alloc] init];
        [comments appendString: [[NSString alloc] initWithBytes:&str[start] length:(i-start) encoding:NSUTF8StringEncoding]];
        column = 0;
        linenum++;
        state = PARSE_NORMAL;
        start = -1;
    }
    else if (state == PARSE_HERESTRING) {
        NSString *partial;
        if (i - start - 1 > 0) {
            partial = [[NSString alloc] initWithBytes:&str[start] length:(i - start) encoding:NSUTF8StringEncoding];
            if (!hereString)
                hereString = [[NSMutableString alloc] init];
            else
                [hereString appendString:[NSString carriageReturn]];
            [hereString appendString:partial];
        }
        start = 0;
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
            }
            if (progn && (progn != [NSNull null])) {
                id cursor = [progn cdr];
                while (cursor && (cursor != [NSNull null])) {
                    if ([cursor car] != [NSNull null]) {
                        //id expression = [cursor car];
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
    NuParser *parser = [[NuParser alloc] init];
    int result = [parser interact];
    [parser release];
    return result;
}

@end
