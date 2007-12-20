;; @file       bridgesupport.nu
;; @discussion Optionally read constants, enums, and functions from Apple's BridgeSupport files.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(global BridgeSupport (dict frameworks:(dict)	;; remember the frameworks we've read
                            constants:(dict)	;; for each constant, remember its type signature
                            enums:(dict)		;; for each enum, remember its value
                            functions:(dict)))	;; for each function, remember its signature

(global import
        (macro _ 
             (NuBridgeSupport importFramework:((margs car) stringValue) 
                  fromPath:(if (margs cdr) (then (eval ((margs cdr) car))) (else nil)) 
                  intoDictionary:BridgeSupport)))

(global import-system 
        (macro _
             (((NSString stringWithShellCommand:"ls /System/Library/Frameworks") lines) each: 
              (do (line)
                  (set name ((line componentsSeparatedByString:".") 0))
                  (eval (cons 'import (list name)))))))