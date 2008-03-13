;; alert.nu
;;  Display an alert box from Nu.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(function alert (message)
     ((NSAlert alertWithMessageText:"The Nu one says:" 
               defaultButton:"ignore"
               alternateButton:"abort" 
               otherButton:"retry" 
               informativeTextWithFormat:(message stringValue)) 
      runModal))