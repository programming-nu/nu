/*!
@file cell.m
@description Nu cells.
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
#import "cell.h"
#import "symbol.h"
#import "extensions.h"
#import "operator.h"
#import "block.h"
#import "dtrace.h"
#import "object.h"
#import "objc_runtime.h"
#import "exception.h"

@implementation NuCell

+ (id) cellWithCar:(id)car cdr:(id)cdr
{
    NuCell *cell = [[self alloc] init];
    [cell setCar:car];
    [cell setCdr:cdr];
    return [cell autorelease];
}

- (id) init
{
    [super init];
    car = Nu__null;
    cdr = Nu__null;
    file = -1;
    line = -1;
    return self;
}

- (void) dealloc
{
    [car release];
    [cdr release];
    [super dealloc];
}

- (bool) atom {return false;}

- (id) car {return car;}

- (id) cdr {return cdr;}

- (void) setCar:(id) c
{
    [c retain];
    [car release];
    car = c;
}

- (void) setCdr:(id) c
{
    [c retain];
    [cdr release];
    cdr = c;
}

// additional accessors, for efficiency (from Nu)
- (id) caar {return [car car];}
- (id) cadr {return [car cdr];}
- (id) cdar {return [cdr car];}
- (id) cddr {return [cdr cdr];}
- (id) caaar {return [[car car] car];}
- (id) caadr {return [[car car] cdr];}
- (id) cadar {return [[car cdr] car];}
- (id) caddr {return [[car cdr] cdr];}
- (id) cdaar {return [[cdr car] car];}
- (id) cdadr {return [[cdr car] cdr];}
- (id) cddar {return [[cdr cdr] car];}
- (id) cdddr {return [[cdr cdr] cdr];}

- (BOOL) isEqual:(id) other
{
    if (nu_objectIsKindOfClass(other, [NuCell class])
    && [[self car] isEqual:[other car]] && [[self cdr] isEqual:[other cdr]]) {
        return YES;
    }
    else {
        return NO;
    }
}

- (id) first
{
    return car;
}

- (id) second
{
    return [cdr car];
}

- (id) third
{
    return [[cdr cdr] car];
}

- (id) fourth
{
    return [[[cdr cdr]  cdr] car];
}

- (id) fifth
{
    return [[[[cdr cdr]  cdr]  cdr] car];
}

- (id) nth:(int) n
{
    if (n == 1)
        return car;
    id cursor = cdr;
    int i;
    for (i = 2; i < n; i++) {
        cursor = [cursor cdr];
        if (cursor == Nu__null) return nil;
    }
    return [cursor car];
}

- (id) objectAtIndex:(int) n
{
    if (n < 0)
        return nil;
    else if (n == 0)
        return car;
    id cursor = cdr;
    for (int i = 1; i < n; i++) {
        cursor = [cursor cdr];
        if (cursor == Nu__null) return nil;
    }
    return [cursor car];
}

// When an unknown message is received by a cell, treat it as a call to objectAtIndex:
- (id) handleUnknownMessage:(NuCell *) method withContext:(NSMutableDictionary *) context
{
    if ([[method car] isKindOfClass:[NuSymbol class]]) {
        NSString *methodName = [[method car] stringValue];
        int length = [methodName length];
        if (([methodName characterAtIndex:0] == 'c') && ([methodName characterAtIndex:(length - 1)] == 'r')) {
            id cursor = self;
            BOOL valid = YES;
            for (int i = 1; valid && (i < length - 1); i++) {
                switch ([methodName characterAtIndex:i]) {
                    case 'd': cursor = [cursor cdr]; break;
                    case 'a': cursor = [cursor car]; break;
                    default:  valid = NO;
                }
            }
            if (valid) return cursor;
        }
    }
    id m = [[method car] evalWithContext:context];
    if ([m isKindOfClass:[NSNumber class]]) {
        int mm = [m intValue];
        if (mm < 0) {
            // if the index is negative, index from the end of the array
            mm += [self length];
        }
        return [self objectAtIndex:mm];
    }
    else {
        return [super handleUnknownMessage:method withContext:context];
    }
}

- (id) lastObject
{
    id cursor = self;
    while ([cursor cdr] != Nu__null) {
        cursor = [cursor cdr];
    }
    return [cursor car];
}

- (NSMutableString *) stringValue
{
    NuCell *cursor = self;
    NSMutableString *result = [NSMutableString stringWithString:@"("];
    int count = 0;
    while (IS_NOT_NULL(cursor)) {
        if (count > 0)
            [result appendString:@" "];
        count++;
        id item = [cursor car];
        if (nu_objectIsKindOfClass(item, [NuCell class])) {
            [result appendString:[item stringValue]];
        }
        else if (IS_NOT_NULL(item)) {
            if ([item respondsToSelector:@selector(escapedStringRepresentation)]) {
                [result appendString:[item escapedStringRepresentation]];
            }
            else {
                [result appendString:[item description]];
            }
        }
        else {
            [result appendString:@"()"];
        }
        cursor = [cursor cdr];
        // check for dotted pairs
        if (IS_NOT_NULL(cursor) && !nu_objectIsKindOfClass(cursor, [NuCell class])) {
            [result appendString:@" . "];
            if ([cursor respondsToSelector:@selector(escapedStringRepresentation)]) {
                [result appendString:[((id) cursor) escapedStringRepresentation]];
            }
            else {
                [result appendString:[cursor description]];
            }
            break;
        }
    }
    [result appendString:@")"];
    return result;
}

- (void) addToException:(NuException*)e value:(id)value
{
    const char *parsedFilename = nu_parsedFilename(self->file);

    if (parsedFilename) {
        NSString* filename = [NSString stringWithCString:parsedFilename encoding:NSUTF8StringEncoding];
        [e addFunction:value lineNumber:[self line] filename:filename];
    }
    else {
        [e addFunction:value lineNumber:[self line]];
    }
}

- (id) evalWithContext:(NSMutableDictionary *)context
{
    id value = nil;
    id result = nil;

    @try
    {
        value = [car evalWithContext:context];

        #ifdef DARWIN
        if (NU_LIST_EVAL_BEGIN_ENABLED()) {
            if ((self->line != -1) && (self->file != -1)) {
                NU_LIST_EVAL_BEGIN(nu_parsedFilename(self->file), self->line);
            }
            else {
                NU_LIST_EVAL_BEGIN("", 0);
            }
        }
        #endif
        // to improve error reporting,
        // add the currently-evaluating expression to the context
        [context setObject:self forKey:[[NuSymbolTable sharedSymbolTable] symbolWithString:@"_expression"]];
        result = [value evalWithArguments:cdr context:context];

        #ifdef DARWIN
        if (NU_LIST_EVAL_END_ENABLED()) {
            if ((self->line != -1) && (self->file != -1)) {
                NU_LIST_EVAL_END(nu_parsedFilename(self->file), self->line);
            }
            else {
                NU_LIST_EVAL_END("", 0);
            }
        }
        #endif
    }
    @catch (NuException* nuException) {
        [self addToException:nuException value:[car stringValue]];
        @throw nuException;
    }
    @catch (NSException* e) {
        if (   nu_objectIsKindOfClass(e, [NuBreakException class])
            || nu_objectIsKindOfClass(e, [NuContinueException class])
        || nu_objectIsKindOfClass(e, [NuReturnException class])) {
            @throw e;
        }
        else {
            NuException* nuException = [[NuException alloc] initWithName:[e name]
                reason:[e reason]
                userInfo:[e userInfo]];
            [self addToException:nuException value:[car stringValue]];
            @throw nuException;
        }
    }

    return result;
}

- (id) each:(id) block
{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        id cursor = self;
        while (cursor && (cursor != Nu__null)) {
            [args setCar:[cursor car]];
            [block evalWithArguments:args context:Nu__null];
            cursor = [cursor cdr];
        }
        [args release];
    }
    return self;
}

- (id) eachPair:(id) block
{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        [args setCdr:[[[NuCell alloc] init] autorelease]];
        id cursor = self;
        while (cursor && (cursor != Nu__null)) {
            [args setCar:[cursor car]];
            [[args cdr] setCar:[[cursor cdr] car]];
            [block evalWithArguments:args context:Nu__null];
            cursor = [[cursor cdr] cdr];
        }
        [args release];
    }
    return self;
}

- (id) eachWithIndex:(id) block
{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        [args setCdr:[[[NuCell alloc] init] autorelease]];
        id cursor = self;
        int i = 0;
        while (cursor && (cursor != Nu__null)) {
            [args setCar:[cursor car]];
            [[args cdr] setCar:[NSNumber numberWithInt:i]];
            [block evalWithArguments:args context:Nu__null];
            cursor = [cursor cdr];
            i++;
        }
        [args release];
    }
    return self;
}

- (id) select:(id) block
{
    NuCell *parent = [[[NuCell alloc] init] autorelease];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        id cursor = self;
        id resultCursor = parent;
        while (cursor && (cursor != Nu__null)) {
            [args setCar:[cursor car]];
            id result = [block evalWithArguments:args context:Nu__null];
            if (nu_valueIsTrue(result)) {
                [resultCursor setCdr:[NuCell cellWithCar:[cursor car] cdr:[resultCursor cdr]]];
                resultCursor = [resultCursor cdr];
            }
            cursor = [cursor cdr];
        }
        [args release];
    }
    else
        return Nu__null;
    NuCell *selected = [parent cdr];
    return selected;
}

- (id) find:(id) block
{
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        id cursor = self;
        while (cursor && (cursor != Nu__null)) {
            [args setCar:[cursor car]];
            id result = [block evalWithArguments:args context:Nu__null];
            if (nu_valueIsTrue(result)) {
                [args release];
                return [cursor car];
            }
            cursor = [cursor cdr];
        }
        [args release];
    }
    return Nu__null;
}

- (id) map:(id) block
{
    NuCell *parent = [[[NuCell alloc] init] autorelease];
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        id cursor = self;
        id resultCursor = parent;
        while (cursor && (cursor != Nu__null)) {
            [args setCar:[cursor car]];
            id result = [block evalWithArguments:args context:Nu__null];
            [resultCursor setCdr:[NuCell cellWithCar:result cdr:[resultCursor cdr]]];
            cursor = [cursor cdr];
            resultCursor = [resultCursor cdr];
        }
        [args release];
    }
    else
        return Nu__null;
    NuCell *result = [parent cdr];
    return result;
}

- (id) mapSelector:(SEL) sel
{
    NuCell *parent = [[NuCell alloc] init];
    id args = [[NuCell alloc] init];
    id cursor = self;
    id resultCursor = parent;
    while (cursor && (cursor != Nu__null)) {
        id object = [cursor car];
        id result = [object performSelector:sel];
        [resultCursor setCdr:[NuCell cellWithCar:result cdr:[resultCursor cdr]]];
        cursor = [cursor cdr];
        resultCursor = [resultCursor cdr];
    }
    [args release];
    NuCell *result = [parent cdr];
    [parent release];
    return result;
}

- (id) reduce:(id) block from:(id) initial
{
    id result = initial;
    if (nu_objectIsKindOfClass(block, [NuBlock class])) {
        id args = [[NuCell alloc] init];
        [args setCdr:[[[NuCell alloc] init] autorelease]];
        id cursor = self;
        while (cursor && (cursor != Nu__null)) {
            [args setCar:result];
            [[args cdr] setCar:[cursor car]];
            result = [block evalWithArguments:args context:Nu__null];
            cursor = [cursor cdr];
        }
        [args release];
    }
    return result;
}

- (NSUInteger) length
{
    int count = 0;
    id cursor = self;
    while (cursor && (cursor != Nu__null)) {
        cursor = [cursor cdr];
        count++;
    }
    return count;
}

- (NSMutableArray *) array
{
    NSMutableArray *a = [NSMutableArray array];
    id cursor = self;
    while (cursor && cursor != Nu__null) {
        [a addObject:[cursor car]];
        cursor = [cursor cdr];
    }
    return a;
}

- (NSUInteger) count
{
    return [self length];
}

- (id) comments {return nil;}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:car];
    [coder encodeObject:cdr];
}

- (id) initWithCoder:(NSCoder *)coder
{
    [super init];
    car = [[coder decodeObject] retain];
    cdr = [[coder decodeObject] retain];
    return self;
}

- (void) setFile:(int) f line:(int) l
{
    file = f;
    line = l;
}

- (int) file {return file;}
- (int) line {return line;}
@end

@implementation NuCellWithComments

- (void) dealloc
{
    [comments release];
    [super dealloc];
}

- (id) comments {return comments;}

- (void) setComments:(id) c
{
    [c retain];
    [comments release];
    comments = c;
}

@end
