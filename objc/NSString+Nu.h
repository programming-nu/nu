//
//  NSString+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

/*!
 @category NSString(Nu)
 @abstract NSString extensions for Nu programming.
 @discussion NSString extensions for Nu programming.
 */
@interface NSString(Nu)
/*! Get string consisting of a single carriage return character. */
+ (id) carriageReturn;
/*!
 Evaluation operator.  In Nu, strings may contain embedded Nu expressions that are evaluated when this method is called.
 Expressions are wrapped in #{...} where the ellipses correspond to a Nu expression.
 */
- (id) evalWithContext:(NSMutableDictionary *) context;

#if !TARGET_OS_IPHONE
/*! Run a shell command and return its results in a string. */
+ (NSString *) stringWithShellCommand:(NSString *) command;

/*! Run a shell command with the specified data or string as standard input and return the results in a string. */
+ (NSString *) stringWithShellCommand:(NSString *) command standardInput:(id) input;
#endif

/*! Return a string read from standard input. */
+ (NSString *) stringWithStandardInput;

/*! If the last character is a newline, return a new string without it. */
- (NSString *) chomp;

/*! Create a string from a specified character */
+ (NSString *) stringWithCharacter:(unichar) c;

/*! Convert a string into a symbol. */
- (id) symbolValue;

/*! Get a representation of the string that can be used in Nu source code. */
- (NSString *) escapedStringRepresentation;

/*! Split a string into lines. */
- (NSArray *) lines;

/*! Replace a substring with another. */
- (NSString *) replaceString:(NSString *) target withString:(NSString *) replacement;

/*! Iterate over each character in a string, evaluating the provided block for each character. */
- (id) each:(id) block;

@end

/*!
 @category NSMutableString(Nu)
 @abstract NSMutableString extensions for Nu programming.
 */
@interface NSMutableString(Nu)
/*! Append a specified character to a string. */
- (void) appendCharacter:(unichar) c;
@end

