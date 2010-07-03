// regex.m
//
// Copyright (c) 2002 Aram Greenman. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#if defined(OPENSOLARIS)
#import "pcre/pcre.h"
#else
#import "pcre.h"
#endif

#import "regex.h"
#import <Foundation/Foundation.h>

// defined for Nu. TB
#define SUPPORT_UTF8

// for finding backrefs and escape sequences in replacement string passed to -replaceWithString:inString:...
#define BACKREF_PATTERN \
    @"(?<!\\\\)\\$(\\{)?(?:(\\d+|&)|(\\w+))(?(1)\\})|\\\\(?:([ULEul])|([^ULEul]))"

// convenience macros for parsing result of BACKREF_PATTERN
#define IS_BACKREF(m)               ([(m) groupAtIndex:2] != nil || [(m) groupAtIndex:3] != nil)
#define IS_NAMED_BACKREF(m)         ([(m) groupAtIndex:3] != nil)
#define IS_CASE_MODIFIER(m)         ([(m) groupAtIndex:4] != nil)
#define IS_LITERAL_ESCAPE(m)        ([(m) groupAtIndex:5] != nil)
#define BACKREF_INDEX(m)            [[(m) groupAtIndex:2] intValue]
#define BACKREF_NAME(m)             [(m) groupAtIndex:3]
#define BACKREF_IS_PARENTHESIZED(m) ([(m) groupAtIndex:1] != nil)
#define CASE_MODIFIER_STRING(m)     [(m) groupAtIndex:4]
#define LITERAL_ESCAPE_STRING(m)    [(m) groupAtIndex:5]

// information about a case modifier
typedef struct
{
    unsigned location;
    char type;
} case_modifier_t;

#ifdef SUPPORT_UTF8
// count the number of UTF-8 characters in a string
// there is probably a better way to do this but this works for now
static int utf8charcount(const char *str, int len)
{
    int chars, pos;
    unsigned char c;
    for (pos = chars = 0; pos < len; pos++) {
        c = str[pos];
        if (c <= 0x7f || (0xc0 <= c && c <= 0xfd))
            chars++;
    }
    return chars;
}

#else
#define utf8charcount(str, len) (len)
#endif

@interface NuRegex (Private)
- (const pcre *)pcre;
@end

@interface NuRegexMatch (Private)
- (id)initWithRegex:(NuRegex *)re string:(NSString *)str vector:(int *)mv count:(int)c;
@end

@interface NuRegexMatchEnumerator : NSEnumerator
{
    NuRegex *regex;
    NSString *string;
    NSRange range;
    unsigned end;
}

- (id)initWithRegex:(NuRegex *)re string:(NSString *)s range:(NSRange)r;
@end

@implementation NuRegex

static NuRegex *backrefPattern;

+ (void)initialize
{
    static BOOL initialized = NO;
    if (initialized) return;
    initialized = YES;
    [super initialize];
    backrefPattern = [[NuRegex alloc] initWithPattern:BACKREF_PATTERN];
}

+ (id)regexWithPattern:(NSString *)pat { return [[[self alloc] initWithPattern:pat] autorelease]; }

+ (id)regexWithPattern:(NSString *)pat options:(int)opts { return [[[self alloc] initWithPattern:pat options:opts ] autorelease]; }

- (id)init
{
    return [self initWithPattern:@""];
}

- (id)initWithPattern:(NSString *)pat
{
    return [self initWithPattern:pat options:0];
}

- (id)initWithPattern:(NSString *)pat options:(int)opts
{
    if ((self = [super init])) {
        pattern = [pat retain];
        options = opts;
        const char *emsg;
        int eloc, copts = 0;
        if (opts & NuRegexCaseInsensitive)  copts |= PCRE_CASELESS;
        if (opts & NuRegexDotAll)           copts |= PCRE_DOTALL;
        if (opts & NuRegexExtended)         copts |= PCRE_EXTENDED;
        if (opts & NuRegexLazy)             copts |= PCRE_UNGREEDY;
        if (opts & NuRegexMultiline)        copts |= PCRE_MULTILINE;
        #ifdef SUPPORT_UTF8
        copts |= PCRE_UTF8;
        #else
        // check for valid ASCII string
        if (![pat canBeConvertedToEncoding:NSUTF8StringEncoding]) {
            [self release];
            return nil;
        }
        #endif
        if (!(regex = pcre_compile([pat UTF8String], copts, &emsg, &eloc, NULL))) {
            [self release];
            return nil;
        }
        if (pcre_fullinfo(regex, NULL, PCRE_INFO_CAPTURECOUNT, &groupCount)) {
            [self release];
            return nil;
        }
        groupCount++;
    }
    return self;
}

- (NSString *) pattern {return pattern;}

- (int) options {return options;}

- (void)dealloc
{
    [pattern release];
    pcre_free(regex);
    pcre_free(extra);
    [super dealloc];
}

- (NuRegexMatch *)findInString:(NSString *)str
{
    return [self findInString:str range:NSMakeRange(0, [str length])];
}

- (NuRegexMatch *)findInString:(NSString *)str range:(NSRange)range
{
    //NSLog(@"NuRegex findInString:%d range:(%d %d)", [str length], range.location, range.length);
    int error, length, opts, *matchv;
    length = [str length];
    opts = 0;
    #ifndef SUPPORT_UTF8
    // check for valid ASCII string
    if (![str canBeConvertedToEncoding:NSUTF8StringEncoding])
        [NSException raise:@"%@ is not a valid ASCII string, build with UTF-8 support", str];
    #endif
    // sanity check range
    if (range.location + range.length > length)
        [NSException raise:NSRangeException format:@"range %@ out of bounds", NSStringFromRange(range)];
    // don't match $ anchor if range is before end of string
    if (range.location + range.length < length)
        opts |= PCRE_NOTEOL;
    // allocate match vector
    NSAssert1(matchv = malloc(sizeof(int) * groupCount * 3), @"couldn't allocate match vector for %d items", groupCount * 3);
    // convert character range to byte range
    range.length = strlen([[str substringWithRange:range] UTF8String]);
    range.location = strlen([[str substringToIndex:range.location] UTF8String]);
    // try match
    if ((error = pcre_exec(regex, extra, [str UTF8String], range.location + range.length, range.location, opts, matchv, groupCount * 3)) == PCRE_ERROR_NOMATCH) {
        free(matchv);
        return nil;
    }
    // should not get any error besides PCRE_ERROR_NOMATCH
    NSAssert1(error > 0, @"unexpected error pcre_exec(): %d", error);
    // return the match, match object takes ownership of matchv
    return [[[NuRegexMatch alloc] initWithRegex:self string:str vector:matchv count:groupCount] autorelease];
}

- (NSArray *)findAllInString:(NSString *)str
{
    return [self findAllInString:str range:NSMakeRange(0, [str length])];
}

- (NSArray *)findAllInString:(NSString *)str range:(NSRange)range
{
    return [[self findEnumeratorInString:str range:range] allObjects];
}

- (NSEnumerator *)findEnumeratorInString:(NSString *)str
{
    return [self findEnumeratorInString:str range:NSMakeRange(0, [str length])];
}

- (NSEnumerator *)findEnumeratorInString:(NSString *)str range:(NSRange)r
{
    return [[[NuRegexMatchEnumerator alloc] initWithRegex:self string:str range:r] autorelease];
}

- (NSString *)replaceWithString:(NSString *)rep inString:(NSString *)str
{
    return [self replaceWithString:rep inString:str limit:0];
}

- (NSString *)replaceWithString:(NSString *)rep inString:(NSString *)str limit:(int)lim
{
    NSMutableString *repBuffer, *result = [NSMutableString string];
    NuRegexMatch *match, *backref;
    NSArray *allMatches, *allBackrefs;
    NSRange remainRange, matchRange, backrefRemainRange, backrefMatchRange;
    case_modifier_t *caseModVector;
    int i, j, k, l, length, repLength, allCount, allBackrefsCount, caseModIdx;
    // set remaining range to full range of receiver
    length = [str length];
    remainRange = NSMakeRange(0, length);
    // find all matches of pattern
    allMatches = [self findAllInString:str];
    allCount = [allMatches count];
    // find all backrefs/escapes in replacement string
    allBackrefs = [backrefPattern findAllInString:rep];
    allBackrefsCount = [allBackrefs count];
    repLength = [rep length];
    // create case mod list
    caseModVector = malloc(sizeof(case_modifier_t) * allCount * allBackrefsCount);
    NSAssert1(caseModVector, @"couldn't allocate memory for %d case modifiers", allCount * allBackrefsCount);
    // while limit is not reached and there are more matches to replace
    for (i = 0; (lim < 1 || i < lim) && i < allCount; i++) {
        // get the the next match
        match = [allMatches objectAtIndex:i];
        // build the replacement string
        repBuffer = [NSMutableString string];
        backrefRemainRange = NSMakeRange(0, repLength);
        caseModIdx = 0;
        for (j = 0; j < allBackrefsCount; j++) {
            // get the next backref
            backref = [allBackrefs objectAtIndex:j];
            backrefMatchRange = [backref range];
            // append the part before the backref
            [repBuffer appendString:[rep substringWithRange:NSMakeRange(backrefRemainRange.location, backrefMatchRange.location - backrefRemainRange.location)]];
            // interpret backref
            if (IS_BACKREF(backref)) {
                NSString *captured;
                int idx;
                if (IS_NAMED_BACKREF(backref)) {
                    NSString *backrefName = BACKREF_NAME(backref);
                    while ((idx = pcre_get_stringnumber(regex, [backrefName UTF8String])) == PCRE_ERROR_NOSUBSTRING && !BACKREF_IS_PARENTHESIZED(backref)) {
                                                  // need at least one letter
                        if (backrefMatchRange.length < 3)
                            [NSException raise:NSInvalidArgumentException format:@"no backreference named %@ in pattern", backrefName];
                        backrefName = [backrefName substringToIndex:[backrefName length] - 1];
                        backrefMatchRange.length--;
                    }
                }
                else {
                    idx = BACKREF_INDEX(backref);
                    // in the case of multiple digits after $, chop it down to the highest valid index
                    while (idx >= [match count] && !BACKREF_IS_PARENTHESIZED(backref)) {
                                                  // need at least one digit
                        if (backrefMatchRange.length < 3)
                            [NSException raise:NSInvalidArgumentException format:@"no such backreference %d in pattern", idx];
                        idx /= 10;
                        backrefMatchRange.length--;
                    }
                }
                // append the captured subpattern to ther replacement string
                captured = [match groupAtIndex:idx];
                [repBuffer appendString:captured ? (id)captured : (id)@""];
                // handle case modifier
            }
            else if (IS_CASE_MODIFIER(backref)) {
                case_modifier_t caseMod;
                caseMod.location = [repBuffer length];
                caseMod.type = [CASE_MODIFIER_STRING(backref) UTF8String][0];
                caseModVector[caseModIdx] = caseMod;
                caseModIdx++;
                // handle literal escape
            }
            else {
                NSAssert1(IS_LITERAL_ESCAPE(backref), @"%@ isn't a backref, case modifier, or literal escape!", backref);
                [repBuffer appendString:LITERAL_ESCAPE_STRING(backref)];
            }
            // set the remaining range to the part after the match
            backrefRemainRange.location = backrefMatchRange.location + backrefMatchRange.length;
            backrefRemainRange.length = repLength - backrefRemainRange.location;
        }
        // append the remaining replacement string to repBuffer
        [repBuffer appendString:[rep substringWithRange:backrefRemainRange]];
        // interpret case modifiers
        for (k = 0; k < caseModIdx; k++) {
            NSRange caseModRange = NSMakeRange(0,0);
            char caseModType = caseModVector[k].type;
            switch (caseModType) {
                case 'u':
                case 'l':
                    caseModRange = NSMakeRange(caseModVector[k].location, 1);
                    break;
                case 'U':
                case 'L':
                    // assume case modifier applies to rest of string unless we find a terminator
                    caseModRange = NSMakeRange(caseModVector[k].location, [repBuffer length] - caseModVector[k].location);
                    for (l = k + 1; l < caseModIdx; l++)
                    if (caseModVector[l].type == 'E') {
                        caseModRange = NSMakeRange(caseModVector[k].location, caseModVector[l].location - caseModVector[k].location);
                        break;
                    }
                    break;
                case 'E':
                    break;
            }
            if (caseModRange.location + caseModRange.length > [repBuffer length])
                continue;
            if (caseModType == 'u' || caseModType == 'U')
                [repBuffer replaceCharactersInRange:caseModRange withString:[[repBuffer substringWithRange:caseModRange] uppercaseString]];
            else if (caseModType == 'l' || caseModType == 'L')
                [repBuffer replaceCharactersInRange:caseModRange withString:[[repBuffer substringWithRange:caseModRange] lowercaseString]];
        }
        // append the part of the target string before the match
        matchRange = [match range];
        [result appendString:[str substringWithRange:NSMakeRange(remainRange.location, matchRange.location - remainRange.location)]];
        // append repBuffer
        [result appendString:repBuffer];
        // set the remaining range to the part after the match
        remainRange.location = matchRange.location + matchRange.length;
        remainRange.length = length - remainRange.location;
    }
    free(caseModVector);
    // append the remaining string
    [result appendString:[str substringWithRange:remainRange]];
    return result;
}

- (NSArray *)splitString:(NSString *)str
{
    return [self splitString:str limit:0];
}

- (NSArray *)splitString:(NSString *)str limit:(int)lim
{
    NSMutableArray *result = [NSMutableArray array];
    NuRegexMatch *match;
    NSArray *allMatches;
    NSString *group;
    NSRange remainRange, matchRange;
    int i, j, count, allCount, length = [str length];
    // find all matches
    allMatches = [self findAllInString:str];
    allCount = [allMatches count];
    remainRange = NSMakeRange(0, length);
    // while limit is not reached and there are more matches
    for (i = 0; (lim < 1 || i < lim) && i < allCount; i++) {
        // get next match
        match = [allMatches objectAtIndex:i];
        matchRange = [match range];
        // add substring from last split to this split
        [result addObject:[str substringWithRange:NSMakeRange(remainRange.location, matchRange.location - remainRange.location)]];
        // add captured subpatterns if any
        count = [match count];
        for (j = 1; j < count; j++)
            if ((group = [match groupAtIndex:j]))
            [result addObject:group];
        // set remaining range to the part after the split
        remainRange.location = matchRange.location + matchRange.length;
        remainRange.length = length - remainRange.location;
    }
    // add rest of the string
    [result addObject:[str substringWithRange:remainRange]];
    return result;
}

- (const pcre *)pcre { return regex; }

- (BOOL)isEqual:(NuRegex *)other
{
    return (([pattern isEqual: [other pattern]]) && (options == [other options]));
}

@end

@implementation NuRegexMatch

// takes ownership of the passed match vector, free on dealloc
- (id)initWithRegex:(NuRegex *)re string:(NSString *)str vector:(int *)mv count:(int)c
{
    if ((self = [super init])) {
        regex = [re retain];
        string = [str copy];                      // really only copies if the string is mutable, immutable strings are just retained
        matchv = mv;
        count = c;
    }
    return self;
}

- (void)dealloc
{
    free(matchv);
    [regex release];
    [string release];
    [super dealloc];
}

- (NuRegex *)regex
{
    return regex;
}

- (NSUInteger)count
{
    return count;
}

- (NSString *)group
{
    return [self groupAtIndex:0];
}

- (NSString *)groupAtIndex:(int)idx
{
    NSRange r = [self rangeAtIndex:idx];
    return r.location == NSNotFound ? (NSString *)nil : [string substringWithRange:r];
}

- (NSString *)groupNamed:(NSString *)name
{
    int idx = pcre_get_stringnumber([regex pcre], [name UTF8String]);
    if (idx == PCRE_ERROR_NOSUBSTRING)
        [NSException raise:NSInvalidArgumentException format:@"no group named %@", name];
    return [self groupAtIndex:idx];
}

- (NSRange)range
{
    return [self rangeAtIndex:0];
}

- (NSRange)rangeAtIndex:(int)idx
{
    int start, end;

    if (idx < 0)
        idx = count + idx;
    if ((idx >= count) || (idx < 0))
        [NSException raise:NSRangeException format:@"index %d out of bounds", idx];
    start = matchv[2 * idx];
    end = matchv[2 * idx + 1];
    if (start < 0)
        return NSMakeRange(NSNotFound, 0);
    // convert byte locations to character locations
    return NSMakeRange(utf8charcount([string UTF8String], start), utf8charcount([string UTF8String] + start, end - start));
}

- (NSRange)rangeNamed:(NSString *)name
{
    int idx = pcre_get_stringnumber([regex pcre], [name UTF8String]);
    if (idx == PCRE_ERROR_NOSUBSTRING)
        [NSException raise:NSInvalidArgumentException format:@"no group named %@", name];
    return [self rangeAtIndex:idx];
}

- (NSString *)string
{
    return string;
}

- (NSString *)description
{
    NSMutableString *desc = [NSMutableString stringWithFormat:@"%@ {\n", [super description]];
    int i;
    for (i = 0; i < count; i++)
        [desc appendFormat:@"\t%d %@ %@\n", i, NSStringFromRange([self rangeAtIndex:i]), [self groupAtIndex:i]];
    [desc appendString:@"}"];
    return desc;
}

@end

@implementation NuRegexMatchEnumerator

- (id)initWithRegex:(NuRegex *)re string:(NSString *)s range:(NSRange)r
{
    if ((self = [super init])) {
        regex = [re retain];
        string = [s copy];                        // create one immutable copy of the string so we don't copy it over and over when the matches are created
        range = r;
        end = range.location + range.length;
    }
    return self;
}

- (void)dealloc
{
    [regex release];
    [string release];
    [super dealloc];
}

- (id)nextObject
{
    NuRegexMatch *next;
    if ((next = [regex findInString:string range:range])) {
        range.location = [next range].location + [next range].length;
        if ([next range].length == 0)
            range.location++;
        range.length = end - range.location;
        if (range.location > end)
            return nil;
    }
    return next;
}

- (NSArray *)allObjects
{
    NSMutableArray *all = [NSMutableArray array];
    NuRegexMatch *next;
    while ((next = [self nextObject]))
        [all addObject:next];
    return all;
}

@end
