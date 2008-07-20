;; @file       destructuring.nu
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

;; Destructuring bind.  The implementation here is very loosely based
;; on the one on p. 232 of Paul Graham's book On Lisp.
(macro dbind
    (let ((__pat (first margs))
          (__seq (eval (second margs)))
          (__body (cdr (cdr margs))))
        (eval (append (list 'let (destructure __pat __seq))
                      __body))))

;; Given a pattern like '(a (b c)) and a sequence like '(1 (2 3)),
;; returns a list of bindings like '((a 1) (b 2) (c 3)).
(function destructure (pat seq)
    (if (symbol? pat)
        (then 
            (let (seq (if (atom? seq)
                          (then seq)
                          (else (list 'quote seq))))
                (list (list pat seq))))
        (else (if (pair? pat)
                  (then (let ((bindings1 (destructure (car pat) (car seq)))
                              (bindings2 (destructure (cdr pat) (cdr seq))))
                            (append bindings1 bindings2)))
                  (else nil)))))

