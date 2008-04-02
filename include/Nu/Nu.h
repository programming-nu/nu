/*!
@header Nu.h
The public interface for the Nu programming language.
Objective-C programs can call Nu scripts by simply including this file,
which is built into the Nu framework.

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

@protocol NuParsing
/*! Parse a string into a list of objects that can be evaluated. */
- (id) parse:(NSString *)string;
/*! Evaluate a parsed code structure in the parser's context. */
- (id) eval:(id) code;
/*! Parse and evaluate a string containing Nu source code. */
- (id) parseEval:(NSString *) string;
/*! Get the value of a name or expression in the parser's context. */
- (id) valueForKey:(NSString *)string;
/*! Set the value of a name in the parser's context. Use this to insert object references into Nu contexts. */
- (void) setValue:(id)value forKey:(NSString *)string;
/*! Call this when you're finished using a parser. */
- (void) close;
@end

/*!
   @class Nu
   @abstract An Objective-C class that provides access to a Nu parser.
   @discussion This class provides a simple interface that allows Objective-C code to run code written in Nu.
   It is intended for use in Objective-C programs that include Nu as a framework.
 */
@interface Nu : NSObject
{
}

/*!
Get a Nu parser. The parser will implement the NuParsing protocol, shown below.

<div style="margin-left:2em">
<code>
@protocol NuParsing<br/>
// parse a string containing Nu expressions into a code object.<br/>
&#45; (id) parse:(NSString *)string;<br/>
// evaluate a code object in the parser's evaluation context.<br/>
&#45; (id) eval: (id) code;<br/>
// Get the value of a name or expression in the parser's context.<br/>
&#45; (id) valueForKey:(NSString *)string;<br/>
// Set the value of a name in the parser's context. Use this to insert object references into Nu contexts.<br/>
&#45; (void) setValue:(id)value forKey:(NSString *)string;<br/>
// Call this when you're finished using a parser.<br/>
&#45; (void) close;<br/>
@end
</code>
</div>
*/
+ (id<NuParsing>) parser;
/*!
Load a Nu source file from a bundle with the specified identifier.
Used by bundle (aka framework) initializers.
*/
+ (BOOL) loadNuFile:(NSString *) fileName fromBundleWithIdentifier:(NSString *) bundleIdentifier withContext:(NSMutableDictionary *) context;
@end

// Helpers for programmatic construction of Nu code.
// Experimental. They may change or disappear in future releases.
id _nunull();
id _nustring(const char *string);
id _nusymbol(const char *string);
id _nunumberd(double d);
id _nucell(id car, id cdr);
id _nuregex(const char *pattern, int options);
id _nulist(id firstObject,...);
