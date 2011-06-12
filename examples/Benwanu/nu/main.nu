;; @file main.nu
;; @discussion Entry point for a Nu program.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Radtastical Inc.

(load "nu")      	;; essentials
(load "cocoa")		;; wrapped frameworks
(load "menu")		;; menu generation
(load "console")	;; interactive console
(load "benwanu")    ;; the party

(set SHOW_CONSOLE_AT_STARTUP nil)

;; @class ApplicationDelegate
;; @discussion Methods of this class perform general-purpose tasks that are not appropriate methods of any other classes.
(class ApplicationDelegate is NSObject
     
     ;; This method is called after Cocoa has finished its basic application setup.
     ;; It instantiates application-specific components. 
     ;; In this case, it builds the application menu, 
     ;; creates and displays a window that displays the Mandelbrot Set,
     ;; and constructs an interactive Nu console that can be activated from the application's Window menu.
     (imethod (void) applicationDidFinishLaunching: (id) sender is
          (build-menu benwanu-application-menu "Benwanu")
          (set $controllers (NSMutableArray array))
          (self newView:self)
          (set $console ((NuConsoleWindowController alloc) init))
          (if SHOW_CONSOLE_AT_STARTUP ($console toggleConsole:self)))
     
     ;; @discussion This method handles the "New" menu item.
     ;; It creates and displays a new viewing window for the Mandelbrot Set.
     (imethod (void) newView:(id) sender is
          ($controllers << ((MandelbrotWindowController alloc) init)))
     
     ;; This method handles the "Save" menu item.
     ;; It opens a save panel for the currently active view.
     (imethod (void) saveView:(id) sender is
          (set view ((((NSApplication sharedApplication) mainWindow) delegate) view))
          (if view (view saveImage:sender)))
     
     ;; This method handles the "Server" menu items by setting the server count for the active view.
     (imethod (void) setThreadCountFromMenuItem:(id) sender is
          (set view ((((NSApplication sharedApplication) mainWindow) delegate) view))
          (if view (view setThreadCount:((sender title) intValue)))))

;; install the delegate and keep a reference to it since the application won't retain it.
((NSApplication sharedApplication) setDelegate:(set $delegate ((ApplicationDelegate alloc) init)))

;; this makes the application window take focus when we've started it from the terminal
((NSApplication sharedApplication) activateIgnoringOtherApps:YES)

;; run the main Cocoa event loop
(NSApplicationMain 0 nil)
