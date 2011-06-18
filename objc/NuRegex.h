/*!
 @header NuRegex.h
 @discussion regular expression support, based on NSRegularExpression.
 @copyright Copyright (c) 2011 Radtastical Inc.
 
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

// Let's make NSRegularExpression and NSTextCheckingResult look like NuRegex and NuRegexMatch

@interface NSTextCheckingResult (NuRegexMatch) 
/*!
 @method regex
 The regular expression used to make this match. */
- (NSRegularExpression *)regex;

/*!
 @method count
 The number of capturing subpatterns, including the pattern itself. */
- (NSUInteger)count;

/*!
 @method group
 Returns the part of the target string that matched the pattern. */
- (NSString *)group;

/*!
 @method groupAtIndex:
 Returns the part of the target string that matched the subpattern at the given index or nil if it wasn't matched. The subpatterns are indexed in order of their opening parentheses, 0 is the entire pattern, 1 is the first capturing subpattern, and so on. */
- (NSString *)groupAtIndex:(int)idx;

/*!
 @method groupNamed:
 Returns the part of the target string that matched the subpattern of the given name or nil if it wasn't matched. */
- (NSString *)groupNamed:(NSString *)name;

/*!
 @method range
 Returns the range of the target string that matched the pattern. */
- (NSRange)range;

/*!
 @method rangeAtIndex:
 Returns the range of the target string that matched the subpattern at the given index or {NSNotFound, 0} if it wasn't matched. The subpatterns are indexed in order of their opening parentheses, 0 is the entire pattern, 1 is the first capturing subpattern, and so on. */
- (NSRange)rangeAtIndex:(int)idx;

/*!
 @method rangeNamed:
 Returns the range of the target string that matched the subpattern of the given name or {NSNotFound, 0} if it wasn't matched. */
- (NSRange)rangeNamed:(NSString *)name;

/*!
 @method string
 Returns the target string. */
- (NSString *)string;

@end

@interface NSRegularExpression (NuRegex) 

/*!
 @method regexWithPattern:
 Creates a new regex using the given pattern string. Returns nil if the pattern string is invalid. */
+ (id)regexWithPattern:(NSString *)pattern;

/*!
 @method regexWithPattern:options:
 Creates a new regex using the given pattern string and option flags. Returns nil if the pattern string is invalid. */
+ (id)regexWithPattern:(NSString *)pattern options:(int)options;

/*!
 @method initWithPattern:
 Initializes the regex using the given pattern string. Returns nil if the pattern string is invalid. */
- (id)initWithPattern:(NSString *)pattern;

/*!
 @method initWithPattern:options:
 Initializes the regex using the given pattern string and option flags. Returns nil if the pattern string is invalid. */
- (id)initWithPattern:(NSString *)pattern options:(int)options;

/*!
 @method findInString:
 Calls findInString:range: using the full range of the target string. */
- (NSTextCheckingResult *)findInString:(NSString *)string;

/*!
 @method findInString:range:
 Returns an NuRegexMatch for the first occurrence of the regex in the given range of the target string or nil if none is found. */
- (NSTextCheckingResult *)findInString:(NSString *)string range:(NSRange)range;

/*!
 @method findAllInString:
 Calls findAllInString:range: using the full range of the target string. */
- (NSArray *)findAllInString:(NSString *)string;

/*!
 @method findAllInString:range:
 Returns an array of all non-overlapping occurrences of the regex in the given range of the target string. The members of the array are NuRegexMatches. */
- (NSArray *)findAllInString:(NSString *)string range:(NSRange)range;

/*!
 @method findEnumeratorInString:
 Calls findEnumeratorInString:range: using the full range of the target string. */
- (NSEnumerator *)findEnumeratorInString:(NSString *)str;

/*!
 @method findEnumeratorInString:range:
 Returns an enumerator for all non-overlapping occurrences of the regex in the given range of the target string. The objects returned by the enumerator are NuRegexMatches. */
- (NSEnumerator *)findEnumeratorInString:(NSString *)str range:(NSRange)r;

/*!
 @method replaceWithString:inString:
 Calls replaceWithString:inString:limit: with no limit. */
- (NSString *)replaceWithString:(NSString *)rep inString:(NSString *)str;

/*!
 @method replaceWithString:inString:limit:
 Returns the string created by replacing occurrences of the regex in the target string with the replacement string. If the limit is positive, no more than that many replacements will be made.
 
 Captured subpatterns can be interpolated into the replacement string using the syntax $x or ${x} where x is the index or name of the subpattern. $0 and $&amp; both refer to the entire pattern. Additionally, the case modifier sequences \U...\E, \L...\E, \u, and \l are allowed in the replacement string. All other escape sequences are handled literally. */
- (NSString *)replaceWithString:(NSString *)rep inString:(NSString *)str limit:(int)limit;

/*!
 @method splitString:
 Call splitString:limit: with no limit. */
- (NSArray *)splitString:(NSString *)str;

/*!
 @method splitString:limit:
 Returns an array of strings created by splitting the target string at each occurrence of the pattern. If the limit is positive, no more than that many splits will be made. If there are captured subpatterns, they are returned in the array.  */
- (NSArray *)splitString:(NSString *)str limit:(int)lim;

@end
