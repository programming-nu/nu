/*!
@header handler.h
@discussion Nu support for precompiled method handlers.
@copyright Copyright (c) 2008 Neon Design Technology, Inc.

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
#import "block.h"

struct handler_description
{
    IMP handler;
    char **description;
};

/*!
    @class NuHandlerWarehouse
    @abstract Internal class used to store and vend method implementations on platforms that don't allow them to be constructed at runtime.
 */
@interface NuHandlerWarehouse : NSObject
{
}

+ (void) registerHandlers:(struct handler_description *) description withCount:(int) count forReturnType:(NSString *) returnType;
+ (IMP) handlerWithSelector:(SEL)sel block:(NuBlock *)block signature:(const char *) signature userdata:(char **) userdata;

@end

void nu_handler(void *return_value, struct handler_description *description, id receiver, va_list ap);
