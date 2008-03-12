/*!
@header bridgesupport.h
@discussion Nu reader for Apple BridgeSupport files.
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

/*! 
    @class NuBridgeSupport
  	@abstract A reader for Apple's BridgeSupport files.
    @discussion Methods of this class are used to read Apple's BridgeSupport files.
 */
@interface NuBridgeSupport : NSObject {}
/*! Import a dynamic library at the specified path. */
+ (void)importLibrary:(NSString *) libraryPath;
/*! Import a BridgeSupport description of a framework from a specified path.  Store the results in the specified dictionary. */
+ (void)importFramework:(NSString *) framework fromPath:(NSString *) path intoDictionary:(NSMutableDictionary *) BridgeSupport;

@end