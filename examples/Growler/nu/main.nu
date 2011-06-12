;; main.nu
;;  Entry point for a Nu program.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(load "nu")      	;; essentials
(load "cocoa")		;; wrapped frameworks
(load "menu")		;; menu generation
(load "console")	;; interactive console
(load "growl")
(load "alert")

;; define the application delegate class
(class ApplicationDelegate is NSObject
     (imethod (void) applicationDidFinishLaunching: (id) sender is
          (build-menu default-application-menu "Growler")
          (set $console ((NuConsoleWindowController alloc) init))
          (puts <<-END
Type (growl "your message") in the console to growl.END)
          ($console toggleConsole:self)          
          (growl "grrowling...")))

;; install the delegate and keep a reference to it since the application won't retain it.
((NSApplication sharedApplication) setDelegate:(set delegate ((ApplicationDelegate alloc) init)))

;; this makes the application window take focus when we've started it from the terminal
((NSApplication sharedApplication) activateIgnoringOtherApps:YES)

;; run the main Cocoa event loop
(NSApplicationMain 0 nil)
