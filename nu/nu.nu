;; @file       nu.nu
;; @discussion Nu library definitions. Useful extensions to common classes.
;;
;; @copyright  Copyright (c) 2007 Tim Burks, Radtastical Inc.
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

(global rand
        (do (maximum)
            (let ((r (NuMath random)))
                 (* maximum (- (/ r maximum) ((/ r maximum) intValue))))))

(global atom?
        (do (x)
            (x atom)))

(global char?
        (do (x)
            (eq (x class) ('a' class))))

(global eq?
        (do (x y)
            (eq x y)))

(global ge?
        (do (x y)
            (ge x y)))

(global gt?
        (do (x y)
            (gt x y)))

(global le?
        (do (x y)
            (le x y)))

(global lt?
        (do (x y)
            (lt x y)))

(global ne?
        (do (x y)
            (ne x y)))

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
;;(global apply
;;        (macro _ (fn *fnargs)
;;             `(eval (cons ,fn ,*fnargs))))

;; Evaluates an expression and raises a NuAssertionFailure if the result is false.
;; For example (assert (eq 1 1)) does nothing but (assert (eq (+ 1 1) 1)) throws
;; an exception.
(global assert
        (macro _ (*body)
             `(progn
                    (set expression ,(car *body))
                    (if (not (eval expression))
                        (then (throw ((NSException alloc)
                                      initWithName:"NuAssertionFailure"
                                      reason:,(*body stringValue)
                                      userInfo:nil)))))))

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

(if (or (eq (uname) "Darwin") (eq (uname "iOS"))) ;; throw is currently only available with the Darwin runtime
    (then
         ;; Evaluates an expression and raises a NuAssertionFailure if the result is false.
         ;; For example (assert (eq 1 1)) does nothing but (assert (eq (+ 1 1) 1)) throws
         ;; an exception.
         (global assert
                 (macro _ (*body)
                      `(progn
                             (set expression ,(car *body))
                             (if (not (eval expression))
                                 (then (throw ((NSException alloc)
                                               initWithName:"NuAssertionFailure"
                                               reason:(expression stringValue)
                                               userInfo:nil)))))))
         
         ;; Throws an exception.
         ;; This function is more concise and easier to remember than throw.
         (global throw*
                 (do (type reason)
                     (throw ((NSException alloc) initWithName:type
                             reason:reason
                             userInfo:nil)))))
    (else
         (global assert (macro _ () (NSLog "warning: assert is unavailable")))
         (global throw* (macro _ () (NSLog "warning: throw* is unavailable")))
         (global throw  (macro _ () (NSLog "warning: throw is unavailable")))))


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

;; profiling macro - experimental
(global profile
        (macro _ (name *body)
             `(progn ((NuProfiler defaultProfiler) start:,name)
                     (set __result (progn ,@*body))
                     ((NuProfiler defaultProfiler) stop)
                     __result)))

;; import some useful C functions
(global random  (NuBridgedFunction functionWithName:"random" signature:"l"))
(global srandom (NuBridgedFunction functionWithName:"srandom" signature:"vI"))

