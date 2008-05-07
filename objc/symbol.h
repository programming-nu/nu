/*!
@header symbol.h
@discussion Declarations for Nu symbols.
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

#ifdef LINUX
#define bool char
#endif

#import <Foundation/Foundation.h>
#import "nuinternals.h"

@class NuSymbol;

/*!
    @class NuSymbolTable
    @abstract The Nu symbol table class.
    @discussion Instances of NuSymbolTable manage collections of NuSymbol objects.
    By default, one NuSymbolTable object is shared by all NuParser objects and execution contexts in a process.
 */
@interface NuSymbolTable : NSObject
{
    struct st_table *symbol_table;
}

/*! Get the shared NuSymbolTable object. */
+ (NuSymbolTable *) sharedSymbolTable;
/*! Get a symbol with the specified string. */
- (id) symbolWithString:(NSString *)string;
/*! Get a symbol with the specified C string. */
- (id) symbolWithCString:(const char *)string;
/*! Get a symbol with the specified string of bytes. */
- (id) symbolWithBytes:(const void *)bytes length:(unsigned)length;
/*! Lookup a symbol in a symbol table. */
- (id) lookup:(const char *) string;
/*! Get an array containing all of the symbols in a symbol table. */
- (NSArray *) all;
/*! Remove a symbol from the symbol table */
- (void) removeSymbol:(NuSymbol *) symbol;
@end

/*!
    @class NuSymbol
    @abstract The Nu symbol class.
    @discussion Instances of NuSymbol are used to uniquely represent strings in parsed Nu expressions.
    NuSymbol objects are used as keys in local evaluation contexts (typically of type NSMutableDictionary)
    and each NuSymbol may also have a global value bound to it.
    Symbols ending in a colon (':') are considered "labels" which evaluate to themselves without error,
    and when a label is found at the head of the list,
    the list is considered to be a special type of list called a property list.
    Each member of a property list is evaluated and the resulting list is returned with no further evaluation.
 */
@interface NuSymbol : NSObject <NSCoding>
{
    NuSymbolTable *table;
    id value;
    @public                                       // only for use by the symbol table
    char *string;
    bool isLabel;
    bool isGensym;                                // in macro evaluation, symbol is replaced with an automatically-generated unique symbol.
}

/*! Get the global value of a symbol. */
- (id) value;
/*! Set the global value of a symbol. */
- (void) setValue:(id)v;
/*! Get an object of type NSString representing the symbol. */
- (NSString *) stringValue;
/*! Get a char * representing the symbol. */
- (const char *) string;
/*! Returns true if a symbol is a label. */
- (bool) isLabel;
/*! Returns true if a symbol is to be replaced by a generated symbol (which only occurs during macro evaluation). */
- (bool) isGensym;
/*! If a symbol is a label, get a string representing its name.  This string omits the final colon (':'). */
- (NSString *) labelName;
/*! Evaluate a symbol in a specified context. */
- (id) evalWithContext:(NSMutableDictionary *) context;
/*! Compare a symbol with another symbol by name.  This allows arrays of symbols to be easily sorted. */
- (NSComparisonResult) compare:(NuSymbol *) anotherSymbol;
/*! Get a description of a symbol.  This is equivalent to a call to stringValue. */
- (NSString *) description;

- (void)encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *)coder;
@end
