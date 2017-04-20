//
//  NuAppDelegate.m
//  NuApp
//
//  Created by Tim Burks on 6/11/11.
//  Copyright 2011 Radtastical Inc. All rights reserved.
//

#import "NuAppDelegate.h"

#import "Nu.h"
#import "NuBlock.h"
#import "NuBridgedBlock.h"

#import <UIKit/UIKit.h>

@class ViewController;

@implementation NuAppDelegate
@synthesize window,view,label;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSDictionary *environment = [[NSProcessInfo processInfo] environment];
	NSString *testConfigPath = environment[@"XCTestConfigurationFilePath"];
	if (testConfigPath)
		return YES;
	
	NSLog(@"inner");
	CGRect frame = [[UIScreen mainScreen] bounds];
	self.window = [[[UIWindow alloc] initWithFrame:frame] autorelease];
	[self.window makeKeyAndVisible];
	UIViewController *viewController = [[UIViewController alloc] init];
	self.window.rootViewController = viewController;
	self.view = [[UIView alloc] initWithFrame:frame];
	viewController.view = self.view;
	self.label = [[UILabel alloc] initWithFrame:frame];
	self.label.text = @"Not run yet";
	self.label.textAlignment = NSTextAlignmentCenter;
	[self.view addSubview:self.label];
	self.view.backgroundColor = [UIColor whiteColor];

	[self prepareTests];
	int failures = [self runTests];
	if (failures == 0) {
		view.backgroundColor = [UIColor greenColor];
		label.text = @"Everything Nu!";
	} else {
		view.backgroundColor = [UIColor redColor];
		label.text = [NSString stringWithFormat:@"%d failures!",failures];
	}
	
	return YES;
}

-(void)prepareTests
{
	NuInit();
	
	[[Nu sharedParser] parseEval:@"(load \"nu\")"];
	[[Nu sharedParser] parseEval:@"(load \"test\")"];
	
	NSString *resourceDirectory = [[NSBundle mainBundle] resourcePath];
	
	NSArray *files = [[NSFileManager defaultManager]
					  contentsOfDirectoryAtPath:resourceDirectory
					  error:NULL];
	NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"^test_.*nu$" options:0 error:NULL];
	for (NSString *filename in files) {
		NSUInteger numberOfMatches = [regex numberOfMatchesInString:filename
															options:0
															  range:NSMakeRange(0, [filename length])];
		if (numberOfMatches) {
			NSLog(@"loading %@", filename);
			NSString *s = [NSString stringWithContentsOfFile:[resourceDirectory stringByAppendingPathComponent:filename]
													encoding:NSUTF8StringEncoding
													   error:NULL];
			[[Nu sharedParser] parseEval:s];
		}
	}
	
	[regex release];
}

-(int)runTests
{
	int failures = 0;
	
	@try
	{
		NSLog(@"running tests");
		failures += [[[Nu sharedParser] parseEval:@"(NuTestCase runAllTests)"] intValue];
		
		failures++;
		
		NSString* script = @"(do () (puts \"cBlock Work!\"))";
		id parsed = [[Nu sharedParser] parse:script];
		NuBlock* block = [[Nu sharedParser] eval:parsed];
		void (^cblock)() = [NuBridgedBlock cBlockWithNuBlock:block	signature:@"v"];
		cblock();
		
		failures--;
		
	}
 	@catch (NSException *e)
	{
		NSLog(@"Exception: %@", e);
	}
	@finally {
		return failures;
	}
}

@end
