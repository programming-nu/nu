;; @file server.nu
;; @discussion An embedded web server for benwanu.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

;; Load this file into a running app to add a web server.
;; It requires NuHTTP. Specifically /Library/Frameworks/NuHTTP.framework.

(load "NuHTTP:server")
(set server ((NuHTTPController alloc) initWithPort:3000))
(set handlers (array))

(get "/"
     (self redirectResponse:response toLocation:"/screenshot"))

(get "/screenshot"
     ((response objectForKey:"headers") setObject:"image/png" forKey:"Content-Type")
     (set mainWindow ((NSApplication sharedApplication) frontWindow))
     (set imageView (((mainWindow contentView) subviews) 0))
     ((imageView imageRep) representationUsingType:NSPNGFileType properties:nil))

(get "/recenter"
     (set frontWindow ((NSApplication sharedApplication) frontWindow))
     (set imageView (((frontWindow contentView) subviews) 0))
     (imageView recenter)
     (self redirectResponse:response toLocation:"/screenshot"))

(server setHandlers:handlers)
