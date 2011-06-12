;; @file server.nu
;; @discussion An embedded web server for benwanu.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Radtastical Inc.

;; Load this file into a running app to add a web server.
;; It requires NuHTTP. Specifically /Library/Frameworks/NuHTTP.framework.

(load "NuHTTP:server")
(set server ((NuHTTPController alloc) initWithPort:3000))
(set handlers (array))

(get "/"
     (self redirectResponse:response toLocation:"/screenshot"))

(function current-mandelbrot-view ()
     (if (and (set frontWindow ((NSApplication sharedApplication) frontWindow))
              (set mandelbrotView (((frontWindow contentView) subviews) 0))
              (mandelbrotView isKindOfClass:MandelbrotView))
         (then mandelbrotView)
         (else nil)))

(set NO_VIEW_AT_FRONT "<h3>No View at Front</h3><p>Please be sure that a Mandelbrot view is open and that the console is closed.</p>")

(get "/screenshot"
     (if (set mandelbrotView (current-mandelbrot-view))
         (then ((response objectForKey:"headers") setObject:"image/png" forKey:"Content-Type")
               ((mandelbrotView imageRep) representationUsingType:NSPNGFileType properties:nil))
         (else NO_VIEW_AT_FRONT)))

(get "/recenter"
     (if (set mandelbrotView (current-mandelbrot-view))
         (then (mandelbrotView recenter)
               (self redirectResponse:response toLocation:"/screenshot"))
         (else NO_VIEW_AT_FRONT)))

(server setHandlers:handlers)
