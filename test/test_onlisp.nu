;; test_onlisp.nu
;;  more tests for Nu macros.
;;
;;  Copyright (c) 2008 Jeff Buck

;; Some macro tests adapted from Paul Graham's book OnLisp

(class TestOnLisp is NuTestCase
     
     (- (id) testNil is
        (macro nil! (var)
             `(set ,var nil))
        
        (set newBody (macrox (nil! a)))
        (assert_equal "(set a nil)" (newBody stringValue))
        
        (set a 5)
        (nil! a)
        (assert_equal nil a))
     
     (- (id) testOurWhen is
        (macro our-when (test *body)
             `(if ,test
                  (progn
                        ,@*body)))
        
        (set n 1)
        (our-when (< n 5)
             (set a "a is defined")
             (set n (+ n 1))
             )
        (assert_equal "a is defined" a)
        
        (set n 6)
        (our-when (< n 5)
             (set b "b is defined"))
        (assert_throws "NuUndefinedSymbol" b))
     
     (- (id) testOurAnd is
        (macro our-and (*args)
             (case (*args length)
                   (0 t)
                   (1 (car *args))
                   (else
                        `(if ,(car *args)
                             (our-and ,@(cdr *args)))
                        )))
        (assert_equal 3 (our-and 1 2 (set m 3)))
        ; Make sure namespace scoping is correct
        (assert_equal 3 m)
        (assert_equal nil (our-and 1 nil (set n 1)))
        ; Make sure short circuit boolean logic is working
        (assert_throws "NuUndefinedSymbol" n))
     
     (- (id) testOurSum is
        (macro our-sum (*args)
             `(+ ,@*args))
        (assert_equal 10 (our-sum 1 2 3 4)))
     
     (- (id) testOurFor is
        (macro myfor ((var start stop) *body)
             `(let ((,var ,start)
                    (__gstop ,stop))	;; Only evaluate stop once
                   (while (<= ,var __gstop)
                          ,@*body
                          (set ,var (+ ,var 1)))))
        
        (set var 0)
        (myfor (i 1 10)
               (set var (+ var i)))
        (assert_equal 55 var)
        
        ;; Make sure we didn't pollute our context
        (assert_throws "NuUndefinedSymbol" i)
        
        ;; Make sure evals work in the parameter list
        (set var 0)
        (set n 20)
        (myfor (i (* 1 1) (- n 10))
               (set var (+ var i)))
        (assert_equal 55 var)
        
        (macro inc! (n) `(set ,n (+ ,n 1)))
        
        (set var 0)
        (set n 9)
        
        ;; Make sure we only eval "stop" one time
        ;; otherwise, we'd have an infinite loop
        (myfor (i 1 (inc! n))
               (set var (+ var i)))
        (assert_equal 55 var))
     
     (- (id) testOurApply is
        (macro our-apply (f *data)
             `(eval (cons ,f ,@*data)))
        
        (assert_equal 6 (our-apply + '(1 2 3))))
     
     (- (id) fixme_testOurLet is
        (macro mylet (bindings *body)
             `((do ,(bindings map:
                         (do (x) (car x)))
                   ,@*body)
               ,@(bindings map:
                 (do (x) (second x)))))
        
        (assert_equal 3
             (mylet ((x 1) (y 2))
                    (+ x y))))
     
     (- (id) testNumericIf is
        (macro numeric-if (expr pos zero neg)
             `(let ((__expr ,expr))
                   (cond
                        ((> __expr 0) ,pos)
                        ((eq __expr 0) ,zero)
                        (t ,neg))))
        (assert_equal '(p z n)
             ('(1 0 -1) map: (do (n) (numeric-if n 'p 'z 'n))))))
