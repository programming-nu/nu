//
//  NSBundle+Nu.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NSBundle+Nu.h"
#import "NuInternals.h"
#import "NSDictionary+Nu.h"

@implementation NSBundle(Nu)

+ (NSBundle *) frameworkWithName:(NSString *) frameworkName
{
    NSBundle *framework = nil;
    
    // is the framework already loaded?
    NSArray *fw = [NSBundle allFrameworks];
    NSEnumerator *frameworkEnumerator = [fw objectEnumerator];
    while ((framework = [frameworkEnumerator nextObject])) {
        if ([frameworkName isEqual: [[framework infoDictionary] objectForKey:@"CFBundleName"]]) {
            return framework;
        }
    }
    
    // first try the current directory
    framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/%@.framework", [[NSFileManager defaultManager] currentDirectoryPath], frameworkName]];
    
    // then /Library/Frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/Frameworks/%@.framework", frameworkName]];
    
    // then /System/Library/Frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/System/Library/Frameworks/%@.framework", frameworkName]];
    
    // then /usr/frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/usr/frameworks/%@.framework", frameworkName]];
    
    // then /usr/local/frameworks
    if (!framework)
        framework = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/usr/local/frameworks/%@.framework", frameworkName]];
    
    if (framework) {
        if ([framework load])
            return framework;
    }
    return nil;
}

- (id) loadNuFile:(NSString *) nuFileName withContext:(NSMutableDictionary *) context
{
    NSString *fileName = [self pathForResource:nuFileName ofType:@"nu"];
    if (fileName) {
        NSString *string = [NSString stringWithContentsOfFile:fileName encoding:NSUTF8StringEncoding error:NULL];
        if (string) {
            NuSymbolTable *symbolTable = [context objectForKey:SYMBOLS_KEY];
            id parser = [context lookupObjectForKey:[symbolTable symbolWithString:@"_parser"]];
            id body = [parser parse:string asIfFromFilename:[fileName UTF8String]];
            [body evalWithContext:context];
            return [symbolTable symbolWithString:@"t"];
        }
        return nil;
    }
    else {
        return nil;
    }
}

@end
