//
//  main.m
//  NuApp
//
//  Created by Tim Burks on 7/2/10.
//  Copyright Radtastical Inc. 2010. All rights reserved.
//
#import "NuMain.h"

int main(int argc, char *argv[]) {    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSError *error;
	NSString *main_nu = [NSString stringWithContentsOfFile:
						  [[NSBundle mainBundle] pathForResource:@"main" ofType:@"nu"]
												   encoding:NSUTF8StringEncoding
													  error:&error];
	NSLog(@"%@", main_nu);
	NSLog(@"%d", [main_nu length]);

	id parser = [Nu parser];
	
	NSLog(@"parsing %@", main_nu);
	
	[parser parseEval:main_nu];
	NSLog(@"running");
	
	
    int retVal = UIApplicationMain(argc, argv, nil, @"AppDelegate");
	
	NSLog(@"done");
	
    [pool release];
    return retVal;
}
