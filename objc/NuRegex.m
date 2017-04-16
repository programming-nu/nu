//
//  NuRegex.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>
#ifdef GNUSTEP
#import <Foundation/NSRegularExpression.h>
#import <Foundation/NSTextCheckingResult.h>
#endif

#import "NuRegex.h"
#import "Nu.h"

#pragma mark - NuRegex.m

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
    if (string && (range.location != NSNotFound)) {
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
- (id)initWithPattern:(NSString *)pattern options:(int)optionFlags {
    return [self initWithPattern:pattern
                         options:optionFlags
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

#ifdef LINUX
- (BOOL) isEqual:(NSRegularExpression *)other
{
    return ([other isKindOfClass:[NSRegularExpression class]] &&
            [[self pattern] isEqual:[other pattern]] &&
            ([self options] == [other options]));
}
#endif

@end

