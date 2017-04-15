//
//  NuBridgedConstant.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuBridgedConstant.h"
#import "NuBridge.h"
#import "NuInternals.h"

@implementation NuBridgedConstant

+ (id) constantWithName:(NSString *) name signature:(NSString *) signature
{
    const char *constant_name = [name UTF8String];
    void *constant = dlsym(RTLD_DEFAULT, constant_name);
    if (!constant) {
        NSLog(@"%s", dlerror());
        NSLog(@"If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.");
        NSLog(@"In Xcode, check the 'Preserve Private External Symbols' checkbox.");
        return nil;
    }
    return get_nu_value_from_objc_value(constant, [signature UTF8String]);
}

@end
