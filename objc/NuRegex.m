/*!
 @file NuRegex.m
 @description regular expression support.
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

#import "NuRegex.h"
#import "NuObject.h"
#import <Foundation/Foundation.h>

@implementation NSTextCheckingResult (NuRegexMatch) 
/*!
 @method regex
 The regular expression used to make this match. */
- (NSRegularExpression *)regex {
    return [self regularExpression];
}

/*!
 @method count
 The number of capturing subpatterns, including the pattern itself. */
- (NSUInteger)count {
    return [self numberOfRanges];
}

/*!
 @method group
 Returns the part of the target string that matched the pattern. */
- (NSString *)group {
    return [self groupAtIndex:0];
}

/*!
 @method groupAtIndex:
 Returns the part of the target string that matched the subpattern at the given index or nil if it wasn't matched. The subpatterns are indexed in order of their opening parentheses, 0 is the entire pattern, 1 is the first capturing subpattern, and so on. */
- (NSString *)groupAtIndex:(int)i {
    NSRange range = [self rangeAtIndex:i];
    NSString *string = [self associatedObjectForKey:@"string"];
    if (string) {
        return [string substringWithRange:range];
    } else {
        return nil;
    }
}

/*!
 @method string
 Returns the target string. */
- (NSString *)string {
    return [self associatedObjectForKey:@"string"];
}

@end

@implementation NSRegularExpression (NuRegex) 

/*!
 @method regexWithPattern:
 Creates a new regex using the given pattern string. Returns nil if the pattern string is invalid. */
+ (id)regexWithPattern:(NSString *)pattern {
    return [self regularExpressionWithPattern:pattern
                                      options:0
                                        error:NULL];
}

/*!
 @method regexWithPattern:options:
 Creates a new regex using the given pattern string and option flags. Returns nil if the pattern string is invalid. */
+ (id)regexWithPattern:(NSString *)pattern options:(int)options {
    return [self regularExpressionWithPattern:pattern
                                      options:options
                                        error:NULL]; 
}

/*!
 @method initWithPattern:
 Initializes the regex using the given pattern string. Returns nil if the pattern string is invalid. */
- (id)initWithPattern:(NSString *)pattern {
    return [self initWithPattern:pattern 
                         options:0
                           error:NULL];
}

/*!
 @method initWithPattern:options:
 Initializes the regex using the given pattern string and option flags. Returns nil if the pattern string is invalid. */
- (id)initWithPattern:(NSString *)pattern options:(int)options {
    return [self initWithPattern:pattern
                         options:options
                           error:NULL];
}


/*!
 @method findInString:
 Calls findInString:range: using the full range of the target string. */
- (NSTextCheckingResult *)findInString:(NSString *)string {
    NSTextCheckingResult *result = [self firstMatchInString:string 
                                                    options:0 
                                                      range:NSMakeRange(0,[string length])];
    if (result) {
        [result setRetainedAssociatedObject:string forKey:@"string"];
    }
    return result;
}

/*!
 @method findInString:range:
 Returns an NuRegexMatch for the first occurrence of the regex in the given range of the target string or nil if none is found. */
- (NSTextCheckingResult *)findInString:(NSString *)string range:(NSRange)range {
    NSTextCheckingResult *result = [self firstMatchInString:string
                                                    options:0 
                                                      range:range];
    if (result) {
        [result setRetainedAssociatedObject:string forKey:@"string"];
    }
    return result;
}

/*!
 @method findAllInString:
 Calls findAllInString:range: using the full range of the target string. */
- (NSArray *)findAllInString:(NSString *)string {
    NSArray *result = [self matchesInString:string
                                    options:0 
                                      range:NSMakeRange(0, [string length])];
    if (result) {
        for (NSObject *match in result) {
            [match setRetainedAssociatedObject:string forKey:@"string"];
        }
    }
    return result;
}

/*!
 @method findAllInString:range:
 Returns an array of all non-overlapping occurrences of the regex in the given range of the target string. The members of the array are NuRegexMatches. */
- (NSArray *)findAllInString:(NSString *)string range:(NSRange)range {
    NSArray *result = [self matchesInString:string options:0 range:range];
    if (result) {
        for (NSObject *match in result) {
            [match setRetainedAssociatedObject:string forKey:@"string"];
        }
    }
    return result;
}

/*!
 @method replaceWithString:inString:
 Calls replaceWithString:inString:limit: with no limit. */
- (NSString *)replaceWithString:(NSString *)replacement inString:(NSString *)string {
    return [self stringByReplacingMatchesInString:string 
                                          options:0 
                                            range:NSMakeRange(0, [string length])
                                     withTemplate:replacement];
    
}

@end

