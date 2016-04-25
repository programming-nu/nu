//
//  NuParser.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

#pragma mark -
#pragma mark Parsing



#import "NuSymbol.h"

/*!
 @class NuParser
 @abstract A Nu language parser.
 @discussion Instances of this class are used to parse and evaluate Nu source text.
 */
@interface NuParser : NSObject

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
/*! Reset the parse set after an error */
- (void) reset;

#if !TARGET_OS_IPHONE
/*! Run a parser interactively at the console (Terminal.app). */
- (int) interact;
/*! Run the main handler for a console(Terminal.app)-oriented Nu shell. */
+ (int) main;
#endif

@end