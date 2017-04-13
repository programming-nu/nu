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
@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	CGRect frame = [[UIScreen mainScreen] bounds];
    self.window = [[[UIWindow alloc] initWithFrame:frame] autorelease];
    [self.window makeKeyAndVisible];
	UIViewController *viewController = [[UIViewController alloc] init];
	self.window.rootViewController = viewController;
	UIView *view = [[UIView alloc] initWithFrame:frame];
	viewController.view = view;
	UILabel *label = [[UILabel alloc] initWithFrame:frame];
	label.textAlignment = NSTextAlignmentCenter;
	[view addSubview:label];
	
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
    NSLog(@"running tests");
	int failures = [[[Nu sharedParser] parseEval:@"(NuTestCase runAllTests)"] intValue];
	
	NSString* script = @"(do () (puts \"cBlock Work!\"))";
	id parsed = [[Nu sharedParser] parse:script];
	NuBlock* block = [[Nu sharedParser] eval:parsed];
	void (^cblock)() = [NuBridgedBlock cBlockWithNuBlock:block	signature:@"v"];
	cblock();
	
	if (failures == 0) {
		view.backgroundColor = [UIColor greenColor];
		label.text = @"Everything Nu!";
	} else {
		view.backgroundColor = [UIColor redColor];
		label.text = [NSString stringWithFormat:@"%d failures!",failures];
	}
    NSLog(@"ok");    
    return YES;
}

@end
