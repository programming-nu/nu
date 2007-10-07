/*
 * NuScreenSaver.m
 *  initialization code for the NuScreenSaver plugin.
 *
 * Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
 */
#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaverView.h>
#import <Nu/Nu.h>

@interface NuScreenSaver : ScreenSaverView
{
}

@end

@implementation NuScreenSaver

+ (void) initialize
{
    static initialized = 0;
    if (!initialized) {
        initialized = 1;
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSBundle *bundle = [NSBundle bundleForClass:self];
        NSString *main_path = [bundle pathForResource:@"bundle" ofType:@"nu"];
        if (main_path) {
            NSString *main = [NSString stringWithContentsOfFile:main_path];
            if (main) {
                id parser = [Nu parser];
                id script = [parser parse:main];
                [parser eval:script];
            }
        }
        [pool release];
    }
}

@end
