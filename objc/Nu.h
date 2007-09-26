/*!
    @header Nu.h
  	The public interface for the Nu programming language.
    Objective-C programs can call Nu scripts by simply including this file, 
    which is built into the Nu framework.

  	@copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
*/
#import <Foundation/Foundation.h>

@protocol NuParsing
- (id) parse:(NSString *)string;
- (id) eval: (id) code;
@end

/*!
   @class Nu
   @abstract An Objective-C class that provides access to a Nu parser.
   @discussion This class provides a simple interface that allows Objective-C code to run code written in Nu.
   It is intended for use in Objective-C programs that include Nu as a framework.
 */
@interface Nu : NSObject {
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
@end
</code>
</div>
*/
+ (id<NuParsing>) parser;
@end
