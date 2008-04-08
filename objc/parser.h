/*!
@header parser.h
@discussion Declarations for NuParser, the Nu source file parser.
@copyright Copyright (c) 2007 Neon Design Technology, Inc.

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

#import <Foundation/Foundation.h>
#import "cell.h"
#import "stack.h"

#define MAXDEPTH 1000

@class NuSymbolTable;

/*!
    @class NuParser
    @abstract A Nu language parser.
    @discussion Instances of this class are used to parse and evaluate Nu source text.
 */
@interface NuParser : NSObject
{
    int state;
    int start;
    int depth;
    int parens;
    int column;
    int quoting;
    int filenum;
    int linenum;
    int parseEscapes;
    bool quoteDepth[MAXDEPTH];
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

/*! Get the symbol table used by a parser. */
- (NuSymbolTable *) symbolTable;
/*! Get the top-level evaluation context that a parser uses for evaluation. */
- (NSMutableDictionary *) context;
/*! Parse Nu source into an expression, returning the NuCell at the top of the resulting expression.
    Since parsing may produce multiple expressions, the top-level NuCell is a Nu <b>progn</b> operator.
*/
- (id) parse:(NSString *)string;
/*! Call -parse: while specifying the name of the source file for the string to be parsed. */
- (id) parse:(NSString *)string asIfFromFilename:(const char *) filename;
/*! Evaluate a parsed Nu expression in the parser's evaluation context. */
- (id) eval: (id) code;
/*! Parse Nu source text and evaluate it in the parser's evalation context. */
- (NSString *) parseEval:(NSString *)string;
/*! Get the value of a name or expression in the parser's context. */
- (id) valueForKey:(NSString *)string;
/*! Set the value of a name in the parser's context. */
- (void) setValue:(id)value forKey:(NSString *)string;
/*! Returns true if the parser is currently parsing an incomplete Nu expression.
    Presumably the rest of the expression will be passed in with a future
    invocation of the parse: method.
*/
- (BOOL) incomplete;
#ifndef IPHONE
/*! Run a parser interactively at the console (Terminal.app). */
- (int) interact;
/*! Run the main handler for a console(Terminal.app)-oriented Nu shell. */
+ (int) main;
#endif
@end
