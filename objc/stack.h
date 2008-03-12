/*!
@header stack.h
@discussion Declarations for a simple stack class.
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
/*!
    @class NuStack
	@abstract A stack class.
	@discussion A simple stack class used by the Nu parser.
 */
@interface NuStack : NSObject
{
    NSMutableArray *storage;
}
/*! Push an object onto the stack. */
- (void) push:(id) object;
/*! Pop an object from the top of the stack. Return nil if the stack is empty. */
- (id) pop;
/*! Return the current stack depth. */
- (int) depth;
@end
