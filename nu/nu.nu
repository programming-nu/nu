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

(global NSUTF8StringEncoding 4)
(global NSLog (NuBridgedFunction functionWithName:"NSLog" signature:"v@"))

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

(global char?
        (do (x)
            (eq (x class) ('a' class))))

(global atom?
        (do (x)
            (x atom)))

(global number?
        (do (x)
            (eq (x class) (1 class))))

;; O(n) in the length of the list (if it is a list).
(global list?
        (do (x)
            (or (eq x nil)
                (and (pair? x)
                     (list? (cdr x))))))

(global null?
        (do (x)
            (eq x nil)))

(global pair?
        (do (x)
            (eq (x class) NuCell)))

(global string?
        (do (x)
            (eq (x class) ("" class))))

(global symbol?
        (do (x)
            (eq (x class) NuSymbol)))

(global zero?
        (do (x)
            (eq x 0)))

;; Reverses a list.
(global reverse
        (do (my-list)
            (if my-list
                (then (append (reverse (cdr my-list)) (list (car my-list))))
                (else nil))))

;; Returns the first true item in the list, or nil if no item is true.
(global any
        (do (ls)
            (ls find:(do (x) x))))

;; Returns t if all elements of the list are true.
(global all
        (do (ls)
            (not (any (ls map:(do (x) (not x)))))))

;; Applies a function to a list of arguments.
;; For example (apply + '(1 2)) returns 3.
(global apply
        (macro-0 _
             (set __f (eval (car margs)))
             (set __args (eval (cdr margs)))
             (eval (cons __f __args))))

;; Evaluates an expression and raises a NuAssertionFailure if the result is false.
;; For example (assert (eq 1 1)) does nothing but (assert (eq (+ 1 1) 1)) throws
;; an exception.
(global assert
        (macro-0 _
             (set expression (car margs))
             (if (not (eval expression))
                 (then (throw ((NSException alloc)
                               initWithName:"NuAssertionFailure"
                               reason:(expression stringValue)
                               userInfo:nil))))))

;; Allows mapping a function over multiple lists.
;; For example (map + '(1 2) '(3 4)) returns '(4 6).
;; The length of the result is the same as that of the shortest list passed in.
;; For example (map + '(1 2) '(3)) returns '(4).
(global map
        (progn
              (set _map
                   (do (f _lists)
                       (if (_lists select:(do (x) (not x)))
                           (then '())
                           (else
                                (cons
                                     (apply f (_lists map: (do (ls) (first ls))))
                                     (_map f (_lists map: (do (ls) (rest ls)))))))))
              (do (fun *lists)
                  (_map fun *lists))))

;; Sorts a list.
(global sort
        (do (ls *more-args)
            (set block (if *more-args
                           (then (first *more-args))
                           (else (do (a b) (a compare:b)))))
            (((apply array ls) sortedArrayUsingBlock:block) list)))

(if (eq (uname) "Darwin") ;; throw is currently only available with the Darwin runtime
    (then
         ;; Evaluates an expression and raises a NuAssertionFailure if the result is false.
         ;; For example (assert (eq 1 1)) does nothing but (assert (eq (+ 1 1) 1)) throws
         ;; an exception.
         (global assert
                 (macro-0 _
                      (set expression (car margs))
                      (if (not (eval expression))
                          (then (throw ((NSException alloc)
                                        initWithName:"NuAssertionFailure"
                                        reason:(expression stringValue)
                                        userInfo:nil))))))
         
         ;; Throws an exception.
         ;; This function is more concise and easier to remember than throw.
         (global throw*
                 (do (type reason)
                     (throw ((NSException alloc) initWithName:type
                             reason:reason
                             userInfo:nil)))))
    (else
         (global assert (macro-0 _ (NSLog "warning: assert is unavailable")))
         (global throw* (macro-0 _ (NSLog "warning: throw* is unavailable")))
         (global throw  (macro-0 _ (NSLog "warning: throw is unavailable")))))




;; Returns an array of filenames matching a given pattern.
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

(class NSObject
     
     ;; Write objects as XML property lists (only for NSData, NSString, NSNumber, NSDate, NSArray, and NSDictionary objects)
     (- writeToPropertyList:name is
        (set xmlData (NSPropertyListSerialization dataFromPropertyList:self
                          format:100 ;; NSPropertyListXMLFormat_v1_0
                          errorDescription:(set error (NuReference new))))
        (if xmlData (xmlData writeToFile:name atomically:YES)
            (else (puts ((error value) description)))))
     
     ;; Read objects from property lists
     (+ readFromPropertyList:name is
        (NSPropertyListSerialization propertyListFromData:(NSData dataWithContentsOfFile:name)
             mutabilityOption:0 ;; NSPropertyListImmutable
             format:nil
             errorDescription:nil))
     
     (- XMLPropertyListRepresentation is
        (NSPropertyListSerialization dataFromPropertyList:self
             format:100 ;; NSPropertyListXMLFormat_v1_0
             errorDescription:(set error (NuReference new))))
     
     (- binaryPropertyListRepresentation is
        (NSPropertyListSerialization dataFromPropertyList:self
             format:200 ;; NSPropertyListBinaryFormat_v1_0
             errorDescription:(set error (NuReference new)))))

(class NSData
     (- propertyListValue is
        (NSPropertyListSerialization propertyListFromData:self
             mutabilityOption:0 ;; NSPropertyListImmutable
             format:nil
             errorDescription:nil)))

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
        (macro-0 _
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

;; profiling macro - experimental
(global profile
        (macro-1 _ (name *body)
             `(progn ((NuProfiler defaultProfiler) start:,name)
                     (set __result (progn ,@*body))
                     ((NuProfiler defaultProfiler) stop)
                     __result)))

;; import some useful C functions
(global random  (NuBridgedFunction functionWithName:"random" signature:"l"))
(global srandom (NuBridgedFunction functionWithName:"srandom" signature:"vI"))

