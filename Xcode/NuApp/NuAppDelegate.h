//
//  NuAppDelegate.h
//  NuApp
//
//  Created by Tim Burks on 6/11/11.
//  Copyright 2011 Radtastical Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NuAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIView *view;
@property (strong, nonatomic) UILabel *label;

-(void)prepareTests;
-(int)runTests;

@end
