;; @file       nu.nu
;; @discussion Nu library definitions. Useful extensions to common classes.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
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

;; Warning! I want to deprecate these.
(global second  (do (my-list) (car (cdr my-list))))
(global third   (do (my-list) (car (cdr (cdr my-list)))))
(global fourth  (do (my-list) (car (cdr (cdr (cdr my-list))))))
(global fifth   (do (my-list) (car (cdr (cdr (cdr (cdr my-list)))))))
(global sixth   (do (my-list) (car (cdr (cdr (cdr (cdr (cdr my-list))))))))
(global seventh (do (my-list) (car (cdr (cdr (cdr (cdr (cdr (cdr my-list)))))))))
(global eighth  (do (my-list) (car (cdr (cdr (cdr (cdr (cdr (cdr (cdr my-list))))))))))
(global ninth   (do (my-list) (car (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr my-list)))))))))))
(global tenth   (do (my-list) (car (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr (cdr my-list))))))))))))

(global rand
        (do (maximum)
            (let ((r (NuMath random)))
                 (* maximum (- (/ r maximum) ((/ r maximum) intValue))))))

;; Reverse a list. Just for fun.
(global reverse
        (do (my-list)
            (if my-list
                (then (append (reverse (cdr my-list)) (list (car my-list))))
                (else nil))))

;; returns an array of filenames matching a given pattern.
;; the pattern is a string that is converted into a regular expression.
(global filelist
        (do (pattern)
            (let ((r (regex pattern))
                  (results ((NSMutableSet alloc) init))
                  (enumerator ((NSFileManager defaultManager) enumeratorAtPath:"."))
                  (filename nil))
                 (while (set filename (enumerator nextObject))
                        (if (r findInString:(filename stringValue))
                            (results addObject:filename)))
                 ((results allObjects) sortedArrayUsingSelector:"compare:"))))

(class NSMutableArray
     
     ;; Concisely add objects to arrays using this method, which is equivalent to a call to addObject:.
     (- (void) << (id) object is (self addObject:object)))

(class NSMutableSet
     
     ;; Concisely add objects to sets using this method, which is equivalent to a call to addObject:.
     (- (void) << (id) object is (self addObject:object)))

(if (eq (uname) "Darwin")
    (class NuCell
         ;; Convert a list into an NSRect. The list must have at least four elements.
         (- (NSRect) rectValue is (list (self first) (self second) (self third) (self fourth)))
         ;; Convert a list into an NSPoint.  The list must have at least two elements.
         (- (NSPoint) pointValue is (list (self first) (self second)))
         ;; Convert a list into an NSSize.  The list must have at least two elements.
         (- (NSSize) sizeValue is (list (self first) (self second)))
         ;; Convert a list into an NSRange.  The list must have at least two elements.
         (- (NSRange) rangeValue is (list (self first) (self second)))))

;; Use this macro to create and extend protocols. 
;; The odd-looking use of the global operator is to define the macro globally.
;; We just use an "_" for the macro name argument because its local name is unimportant.
;; It does not work with the latest (more restrictive) ObjC runtimes from Apple.
(global protocol
        (macro _
             (set __signatureForIdentifier (NuBridgedFunction functionWithName:"signature_for_identifier" signature:"@@@"))
             (function __parse_signature (typeSpecifier)
                  (__signatureForIdentifier typeSpecifier (NuSymbolTable sharedSymbolTable)))
             
             (set __name ((margs car) stringValue))
             (unless (set __protocol (Protocol protocolNamed: __name))
                     (set __protocol ((Protocol alloc) initWithName: __name)))
             (eval (list 'set (margs car) __protocol))
             (set __rest (margs cdr))
             (while __rest
                    (set __method (__rest car))
                    (set __returnType (__parse_signature ((__method cdr) car)))
                    (set __signature __returnType)
                    (__signature appendString:"@:")
                    (set __name "#{(((__method cdr) cdr) car)}")
                    (set __argumentCursor (((__method cdr) cdr) cdr))
                    (while __argumentCursor ;; argument type
                           (__signature appendString:(__parse_signature (__argumentCursor car)))
                           (set __argumentCursor (__argumentCursor cdr))
                           (if __argumentCursor ;; variable name
                               (set __argumentCursor (__argumentCursor cdr)))
                           (if __argumentCursor ;; selector
                               (__name appendString:((__argumentCursor car) stringValue))
                               (set __argumentCursor (__argumentCursor cdr))))
                    (cond ((or (eq (__method car) '-) (eq (__method car) 'imethod))
                           (__protocol addInstanceMethod:__name withSignature:__signature))
                          ((or (eq (__method car) '+) (eq (__method car) 'cmethod))
                           (__protocol addClassMethod:__name withSignature:__signature))
                          (else nil))
                    (set __rest (__rest cdr)))))
