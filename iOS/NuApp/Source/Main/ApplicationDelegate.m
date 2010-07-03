//
//  ApplicationDelegate.m
//  NuApp
//
//  Created by Tim Burks on 7/2/10.
//  Copyright Neon Design Technology, Inc. 2010. All rights reserved.
//

#import "ApplicationDelegate.h"

@implementation ApplicationDelegate
@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];	
    self.window.backgroundColor = [UIColor redColor];	
    [window makeKeyAndVisible];
    return YES;
}

- (void)dealloc {
    [window release];
    [super dealloc];
}

@end
