;; main.nu
;;  Aaron Hillegass' RandomApp example, the nib way. 
;;  a how-to for cooking with Nu and Cocoa.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(load "Nu:nu")		;; basics
(load "Nu:cocoa")	;; cocoa definitions

;; the window controller loads and manages the window.
;; you can have as many of these running at the same time as you want.
(class RandomAppWindowController is NSWindowController
     (ivar (id) textField) ;; you need this to complete the outlet connection in the nib.
     
     (imethod (id) init is
          (self initWithWindowNibName:"Random")
          ((self window) makeKeyAndOrderFront:self)
          self)
     
     (imethod (void) seed: (id) sender is
          (NuMath srandom:((NSCalendarDate calendarDate) timeIntervalSince1970))
          (@textField setStringValue:"generator seeded"))
     
     (imethod (void) generate: (id) sender is
          (@textField setIntValue:(NuMath random))))

;; the application delegate sets up your app once Cocoa has finished initializing itself.
(class ApplicationDelegate is NSObject
     (imethod (void) applicationDidFinishLaunching: (id) sender is
          (set $windows (NSMutableArray array))
          (10 times:
              (do (i)
                  (let ((controller ((RandomAppWindowController alloc) init)))
                       ((controller window) setTitle:"#{(+ i 1)}. Yes, I can load nibs with Nu.")
                       ($windows << controller))))))

;; install the delegate and keep a reference to it since the application won't retain it.
((NSApplication sharedApplication) setDelegate:(set delegate ((ApplicationDelegate alloc) init)))

;; this makes the application window take focus when we've started it from the terminal
((NSApplication sharedApplication) activateIgnoringOtherApps:YES)

;; run the main Cocoa event loop
(NSApplicationMain 0 nil)
