;; main.nu
;; Entry point for a Nu program.
;;
;; Copyright (c) 2007 Tim Burks, Radtastical Inc.

(load "nu")      	;; essentials
(load "cocoa")		;; wrapped frameworks
(load "menu")		;; menu generation
(load "console")	;; interactive console
(load "maildemo")   ;; application details are here

(set SHOW_CONSOLE_AT_STARTUP nil)

(class ApplicationDelegate is NSObject
     
     (- (void) applicationDidFinishLaunching: (id) sender is
        (build-menu maildemo-application-menu "MailDemo")
        (set $controllers (NSMutableArray array))
        (self newView:self)
        (set $console ((NuConsoleWindowController alloc) init))
        (if SHOW_CONSOLE_AT_STARTUP ($console toggleConsole:self)))
     
     (- (void) newView:(id) sender is
        ($controllers << ((MailController alloc) init))))

((NSApplication sharedApplication) setDelegate:(set $delegate ((ApplicationDelegate alloc) init)))
((NSApplication sharedApplication) activateIgnoringOtherApps:YES)
(NSApplicationMain 0 nil)
