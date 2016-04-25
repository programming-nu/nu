/*!
 @header Nu.h
 @discussion Nu.
 @copyright Copyright (c) 2007-2011 Radtastical Inc.
 
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
#ifdef GNUSTEP
#import <Foundation/NSRegularExpression.h>
#import <Foundation/NSTextCheckingResult.h>
#endif
#import <objc/objc.h>
#import <objc/runtime.h>

#import "NSObject+Nu.h"
#import "NuParser.h"

// call this from main() to run the Nu shell.
int NuMain(int argc, const char *argv[]);

// call this to initialize the Nu environment.
void NuInit(void);

/*!
 @class Nu
 @abstract An Objective-C class that provides access to a Nu parser.
 @discussion This class provides a simple interface that allows Objective-C code to run code written in Nu.
 It is intended for use in Objective-C programs that include Nu as a framework.
 */
@interface Nu : NSObject
/*!
 Get a Nu parser with its own context.
 */
+ (NuParser *) parser;
/*!
 Get a common parser. This allows a context to be shared throughout an app.
 */
+ (NuParser *) sharedParser;
/*!
 Load a Nu source file from a bundle with the specified identifier.
 Used by bundle (aka framework) initializers.
 */
+ (BOOL)      loadNuFile:(NSString *) fileName
fromBundleWithIdentifier:(NSString *) bundleIdentifier
             withContext:(NSMutableDictionary *) context;
@end

// Helpers for programmatic construction of Nu code. Used by nubake.
// Experimental. They may change or disappear in future releases.
id _nunull(void);
id _nustring(const unsigned char *string);
id _nustring_with_length(const unsigned char *string, int length);
id _nusymbol(const unsigned char *string);
id _nusymbol_with_length(const unsigned char *string, int length);
id _nunumberd(double d);
id _nucell(id car, id cdr);
id _nuregex(const unsigned char *pattern, int options);
id _nuregex_with_length(const unsigned char *pattern, int length, int options);
id _nulist(id firstObject,...);
id _nudata(const void *bytes, int length);

