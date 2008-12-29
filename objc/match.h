/*!
@file match.h
@description Class wrapper for Nu's match functions.
@copyright Copyright (c) 2008 Jeff Buck

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

@interface NuMatch : NSObject
{
}
+ (id) matcher;

+ (id) matchLet:(id) pattern withSequence:(id) sequence forBody:(id) body;
+ (id) matchSet:(id) pattern withSequence:(id) sequence forBody:(id) body;
+ (id) mdestructure:(id) pattern withSequence:(id) sequence;
+ (id) destructure:(id) pattern withSequence:(id) sequence;
+ (id) checkBindings:(id) bindings;
+ (BOOL) match:(id) pattern withSequence:(id) sequence;
+ (id) findAtom:(NSString*) item inSequence:(id) sequence;
@end
