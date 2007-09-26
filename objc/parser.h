/*!
    @header parser.h
  	@copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
  	@discussion Declarations for NuParser, the Nu source file parser.
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
	int linenum;
    bool quoteDepth[MAXDEPTH];
    NuCell *root;
    NuCell *current;
    bool addToCar;
	NSMutableString *hereString;
    NuStack *stack;
	NuStack *opens;
    NuSymbolTable *symbolTable;
    NSMutableDictionary *context;
	NSMutableString *comments;
}

/*! Get the symbol table used by a parser. */
- (NuSymbolTable *) symbolTable;
/*! Get the top-level evaluation context that a parser uses for evaluation. */
- (NSMutableDictionary *) context;
/*! Parse Nu source into an expression, returning the NuCell at the top of the resulting expression. 
	Since parsing may produce multiple expressions, the top-level NuCell is a Nu <b>progn</b> operator.
*/
- (id) parse:(NSString *)string;
/*! Evaluate a parsed Nu expression in the parser's evaluation context. */
- (id) eval: (id) code;
/*! Parse Nu source text and evaluate it in the parser's evalation context. */
- (NSString *) parseEval:(NSString *)string;
/*! Returns true if the parser is currently parsing an incomplete Nu expression. 
	Presumably the rest of the expression will be passed in with a future 
	invocation of the parse: method.
*/
- (BOOL) incomplete;
/*! Run a parser interactively at the console (Terminal.app). */
- (int) interact;
/*! Run the main handler for a console(Terminal.app)-oriented Nu shell. */
+ (int) main;
@end