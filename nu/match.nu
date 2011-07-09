;; @file       match.nu
;; @discussion Macros similar to destructuring-bind in Common Lisp.
;;
;; @copyright  Copyright (c) 2008 Issac Trotts
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


;; Assigns variables in a template to values in a structure matching the template.
;; For example
;;
;;  (match-let1 ((a b) c) '((1 2) (3 4))
;;         (list a b c))
;;
;; returns
;;
;;   (1 2 (3 4))
(macro match-let1 (pattern sequence *body)
     (set __bindings (destructure pattern (eval sequence)))
     (check-bindings __bindings)
     `(let ,__bindings ,@*body))

;; Assigns variables in a template to values in a structure matching the template.
;; For example
;;
;; (progn
;;  (match-set ((a b) c) '((1 2) (3 4)))
;;  (list a b c))
;;
;; returns
;;
;;   (1 2 (3 4))
;;
;; The name is short for "destructuring set."  The semantics are similar to "set."
(macro match-set (pattern sequence *body)
     (set __bindings (destructure pattern (eval sequence)))
     (check-bindings __bindings)
     (set __set-statements
          (__bindings map:(do (b)
                              `(set ,(b 0) ,(b 1)))))
     `(progn ,@__set-statements))

;; Given a pattern like '(a (b c)) and a sequence like '(1 (2 3)),
;; returns a list of bindings like '((a 1) (b 2) (c 3)).
;; The implementation here is loosely based on the one on p. 232 of Paul
;; Graham's book On Lisp.
(function destructure (pat seq)
     (cond
          ;; The empty pattern matches the empty sequence.
          ((eq pat '())
           (if (!= seq '())
               (then
                    (throw* "NuMatchException"
                            "Attempt to match empty pattern to non-empty object"))
               (else '())))
          
          ;; The pattern nil matches the object nil.
          ((eq pat 'nil)
           (if (eq seq nil)
               (then nil)  ; matched nil with nil, producing no binding
               (else throw* "NuMatchException"
                     "nil does not match #{seq}")))
          
          ;; Wildcard _ matches everything and produces no binding.
          ((eq pat '_) '())
          
          ;; Symbol patterns match everything and produce bindings.
          ((symbol? pat)
           (let (seq (if (or (pair? seq) (symbol? seq))
                         (then (list 'quote seq))
                         (else seq)))
                (list (list pat seq))))
          
          ;; Patterns like (head . tail) recurse.
          ((and (pair? pat)
                (pair? (pat cdr))
                (eq '. (pat second))
                (pair? ((pat cdr) cdr))
                (eq nil (((pat cdr) cdr) cdr)))
           (let ((bindings1 (destructure (pat 0) (seq 0)))
                 (bindings2 (destructure (pat 2) (seq cdr))))
                (append bindings1 bindings2)))
          
          ;; Symbolic literal patterns like 'Foo match only symbols and produce
          ;; no bindings.
          ((and (pair? pat)
                (eq 'quote (pat 0))
                (pair? (pat cdr))
                (symbol? (pat second)))
           (if (eq (pat second) seq)
               (then '())  ; literal symbol match produces no bindings
               (else (throw* "NuMatchException"
                             "Failed match of literal symbol #{pat} to #{seq}"))))
          
          ;; Pair patterns (including lists) recurse.
          ((pair? pat)
           (let ((bindings1 (destructure (pat car) (seq car)))
                 (bindings2 (destructure (pat cdr) (seq cdr))))
                (append bindings1 bindings2)))
          
          ;; Literal matches produce no bindings.
          ((eq pat seq) '())
          
          ;; Everything else is rejected.
          (else (throw* "NuMatchException"
                        "Could not destructure sequence #{seq} with pattern #{pat}"))))

;; mdestructure is based on the destructure function right above,
;; but is modified to destructure macro arguments.  As these arguments
;; are not evaluated as in a standard operator, we needed to turn
;; off quoting.
;;
;; Additionally, we allow any parameter in the pattern list whose
;; name starts with '*' to capture the remaining sequence.
;;
;; This function is called from macro_1.m in the Nu core.

(function mdestructure (pat seq)
     (cond
          ((and (not pat) seq)
           (throw* "NuMatchException"
                   "Attempt to match empty pattern to non-empty object"))
          
          ((not pat) nil)
          
          ((eq pat '_) '())  ; wildcard match produces no binding
          
          ((symbol? pat)
           ;(puts "mdest: symbol?:  #{pat}  #{seq}")
           (let (seq (if (eq ((pat stringValue) characterAtIndex:0) '*')
                         (then (list seq))
                         (else seq)))
                (list (list pat seq))))
          
          ;; Patterns like (head . tail)
          ((and (pair? pat)
                (pair? (cdr pat))
                (eq '. (pat second))
                (pair? (cdr (cdr pat)))
                (eq nil (cdr (cdr (cdr pat)))))
           ;(puts "mdest: (h . t):  #{pat}  #{seq}")
           (let ((bindings1 (mdestructure (first pat) (first seq)))
                 (bindings2 (mdestructure (third pat) (rest seq))))
                (append bindings1 bindings2)))
          
          ;; Symbolic literal patterns like 'Foo
          ((and (pair? pat)
                (eq 'quote (car pat))
                (pair? (cdr pat))
                (symbol? (pat second)))
           ;(puts "mdest: 'Literal:  #{pat}  #{seq}")
           (if (eq (pat second) seq)
               (then '())  ; literal symbol match produces no bindings
               (else (throw* "NuMatchException"
                             "Failed match of literal symbol #{pat} to #{seq}"))))
          
          ((pair? pat)
           ;(puts "mdest: pair?:  #{pat}  #{seq}")
           (if (and (symbol? (car pat))
                    (eq (((car pat) stringValue) characterAtIndex:0) '*'))
               (then (list (list (car pat) seq)))
               (else ((let ((bindings1 (mdestructure (car pat) (car seq)))
                            (bindings2 (mdestructure (cdr pat) (cdr seq))))
                           (append bindings1 bindings2))))))
          
          ((eq pat seq)
           ;(puts "mdest: literal match:  #{pat}  #{seq}")
           '())  ; literal match produces no bindings
          (else (throw* "NuMatchException"
                        "pattern is not nil, a symbol or a pair: #{pat}"))))

;; Makes sure that no key is set to two different values.
;; For example (check-bindings '((a 1) (a 1) (b 2))) just returns its argument,
;; but (check-bindings '((a 1) (a 2) (b 2))) throws a NuMatchException.
(function check-bindings (bindings)
     (set dic (dict))
     (bindings each:(do (b)
                        (set key (b 0))
                        (set val (b 1))
                        (set prev-val (dic key))  ; valueForKey inexplicably rejects symbols
                        (if (eq nil prev-val)
                            (then (dic setValue:val forKey:key))
                            (else
                                 (if (not (eq val prev-val))
                                     (then
                                          (throw* "NuMatchException"
                                                  "Inconsistent bindings #{prev-val} and #{val} for #{key}")))))))
     bindings)

(function _quote-leaf-symbols (x)
     (cond
          ((pair? x)
           (cons (_quote-leaf-symbols (car x))
                 (_quote-leaf-symbols (cdr x))))
          ((symbol? x)
           (eval (list 'quote (list 'quote x))))
          (else x)))

;; Finds the first matching pattern and returns its associated expression.
(function _find-first-match (obj patterns)
     (if (not patterns)
         (then '())
         (else
              (set pb (patterns 0))  ; pattern and body
              (set pat (pb 0))
              
              ;; Handle quoted list patterns like '(a) or '(a b)
              (if (and (pair? pat)
                       (eq 'quote (pat 0)))
                  (then
                       (set pat (_quote-leaf-symbols (pat 1)))))
              
              (set body (pb cdr))
              (if (eq pat 'else)
                  (then body)
                  (else
                       (try
                           (set bindings (destructure pat obj))
                           (check-bindings bindings)
                           (set expr (cons 'let (cons bindings body)))
                           expr
                           (catch (exception)
                                  (_find-first-match obj (patterns cdr)))))))))

;; Matches an object against some patterns with associated expressions.
;; TODO(ijt): boolean conditions for patterns (like "when" in ocaml)
;;(macro-0 match
;;     (set __obj (eval (margs 0)))
;;     (set __patterns (margs cdr))
;;     (set __expr (_find-first-match __obj __patterns))
;;     (if (not __expr)
;;         (then (throw* "NuMatchException" "No match found")))
;;     (eval __expr))

(macro match (object *patterns)
     ;;(puts "---->")
     (set __obj (eval object))
     ;;(print "object: ") (puts object)
     ;;(print "obj: ") (puts __obj)
     ;;(print "*patterns: ") (puts *patterns)
     (set __expr (_find-first-match __obj *patterns))
     ;;(print "expr: ") (puts __expr)
     `(progn
            (if (not __expr)
                (then (throw* "NuMatchException" "No match found")))
            (,@__expr))
     )

;; Variant of (do (args) body) that gives different results depending
;; on the structure of the argument list. For example, here is a
;; function that counts its arguments, up to two:
;;
;; % (set f (match-do (() 0)
;;                    ((a) 1)
;;                    ((a b) 2)))
;; (do (*args) ((match *args (() 0) ((a) 1) ((a b) 2))))
;; % (f)
;; 0
;; % (f 'x)
;; 1
;; % (f 'y)
;; 1
;; % (f 'x 'y)
;; 2
;; % (f 'x 'y 'z)
;; NuMatchException: No match found
;;
(macro match-do (*body)
     `(do (*args)
          (match *args ,@*body)))

;; Variant of (function name (args) body) that gives different results depending
;; on the structure of the argument list. For example, here is a way to implement
;; map:
;;
;; % (function slow-map (f lst)
;;   (match-function loop
;;     ((nil) '())
;;     (((a . rest))
;;      (puts "about to cons #{(f a)} onto recurse on #{rest}")
;;      (cons (f a) (loop rest)))
;;     (etc (puts "misc: #{etc}")))
;;   (loop lst))
;; % (slow-map cos '(3.14 0))
;; (-0.9999987317275395 1)
;;
(macro match-function (fn *body)
     `(set ,fn (match-do ,@*body)))

;; Looks for an occurrence of item in the list l.
(function find-atom (item l)
     (cond
          ((eq item nil)
           nil)
          ((eq l nil)
           nil)
          ((eq item (l stringValue))
           item)
          ((pair? l)
           (or (find-atom item (car l))
               (find-atom item (cdr l))))))


;; Class definition to make it easier to bridge to ObjC (jsb)

(class NuMatch is NSObject
     (+ (id) matchLet:(id) pattern withSequence:(id) sequence forBody:(id) body is
        (match-let1 pattern sequence body))
     
     (+ (id) matchSet:(id) pattern withSequence:(id) sequence forBody:(id) body is
        (match-set pattern sequencebody))
     
     (+ (id) mdestructure:(id) pattern withSequence:(id) sequence is
        (mdestructure pattern sequence))
     
     (+ (id) destructure:(id) pattern withSequence:(id) sequence is
        (destructure pattern sequence))
     
     (+ (id) checkBindings:(id) bindings is
        (check-bindings bindings))
     
     (+ (BOOL) match:(id) pattern withSequence:(id) sequence is
        (match pattern sequence))
     
     (+ (id) findAtom:(id) a inSequence:(id) sequence is
        (find-atom a sequence)))

