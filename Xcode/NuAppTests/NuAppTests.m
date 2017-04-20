//
//  NuAppTests.m
//  NuAppTests
//
//  Created by Johannes Goslar on 20.4.17.
//
//

#import <XCTest/XCTest.h>
#import "NuAppDelegate.h"

@interface NuAppTests : XCTestCase

@end

@implementation NuAppTests

-(void)setUp
{
	[(NuAppDelegate*)UIApplication.sharedApplication.delegate prepareTests];
	[super setUp];
}

-(void)testEverything
{
    [self measureBlock:^{
		XCTAssertEqual([(NuAppDelegate*)UIApplication.sharedApplication.delegate runTests], 0);
    }];
}

@end
