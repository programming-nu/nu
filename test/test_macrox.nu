;; test_macrox.nu
;;  tests for Nu macro-expand operator.
;;
;;  Copyright (c) 2008 Jeff Buck

(class TestMacrox is NuTestCase
     
     (imethod (id) testIncMacro is
          (defmacro inc! `(set ,(car margs) (+ ,(car margs) 1)))
          
          ;; Test the macro evaluation
          (set a 0)
          (inc! a)
          (assert_equal 1 a)
          
          ;; Test the expansion
          (set newBody (macrox (inc! a)))
          (assert_equal "(set a (+ a 1))" (newBody stringValue)))
     
     (imethod (id) testNestedMacro is
          (defmacro inc! `(set ,(car margs) (+ ,(car margs) 1)))
          
          (defmacro inc2!
               `(progn
                      (inc! ,(car margs))
                      (inc! ,(car margs))))
          
          (set a 0)
          (inc2! a)
          (assert_equal 2 a)
          
          (set newBody (macrox (inc2! a)))
          (assert_equal "(progn (inc! a) (inc! a))" (newBody stringValue)))
     
     
     (imethod (id) testFactorialMacro is
          (defmacro mfact
               (set __x (car margs))
               `(if (== ,__x 0)
                    (then 1)
                    (else (* (mfact (- ,__x 1)) ,__x))))
          
          (set newBody (macrox (mfact x)))
          (assert_equal "(if (== x 0) (then 1) (else (* (mfact (- x 1)) x)))" (newBody stringValue))
          
          (set x 4)
          (assert_equal 24 (mfact x))))
