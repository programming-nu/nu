;; @file fscript.nu
;; @discussion Nu helpers for working with F-Script.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(load "FScript")

(function fs-browse (object)
     (set browser (BigBrowser 
                       bigBrowserWithRootObject:object
                       interpreter:(FSInterpreter interpreter)))
     (browser makeKeyAndOrderFront:0)
     (unless $fs-browsers (set $fs-browsers (array)))
     ($fs-browsers << browser)
     browser)

