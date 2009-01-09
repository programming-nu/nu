/*!
@file match.m
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
#import "match.h"
#import "parser.h"

// Declare Nu class to avoid compiler warning when loading match.nu
@interface Nu {}
+ (id) parser;
@end

@implementation NuMatch

static BOOL	g_loadedMatch = YES; // originally this was NO, but it's now unnecessary

+ (id) matcher
{
	// The destructure code is written in Nu and is in the file match.nu
	if (!g_loadedMatch)
	{
		id parser = [Nu parser];
		id script = [parser parse:@"(load \"match\")"];
		[parser eval:script];
		
		g_loadedMatch = YES;
	}
        return self;	
}

@end
