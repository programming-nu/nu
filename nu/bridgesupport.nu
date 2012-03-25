;; @file       bridgesupport.nu
;; @discussion Optionally read constants, enums, and functions from Apple's BridgeSupport files.
;;
;; @copyright Copyright (c) 2007 Tim Burks, Radtastical Inc.
;;
;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

(global BridgeSupport (dict frameworks:(dict)	;; remember the frameworks we've read
                            constants:(dict)	;; for each constant, remember its type signature
                            enums:(dict)		;; for each enum, remember its value
                            functions:(dict)))	;; for each function, remember its signature

(global import
        (macro _ (framework *path)
             `(progn
                    (NuBridgeSupport importFramework:(',framework stringValue)
                         fromPath:(if ,*path (then (car ,*path)) (else nil))
                         intoDictionary:BridgeSupport))))

(global import-system
        (macro _ ()
             `(progn
                    (((NSString stringWithShellCommand:"ls /System/Library/Frameworks") lines) each:
                     (do (line)
                         (set name ((line componentsSeparatedByString:".") 0))
                         (eval (cons 'import (list name))))))))

