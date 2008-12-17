;; test_macrox.nu
;;  tests for Nu macro-expand operator.
;;
;;  Copyright (c) 2008 Jeff Buck

(class TestMacrox is NuTestCase
     
     (imethod (id) testIncMacro is
          (macro inc! (n)
               `(set ,n (+ ,n 1)))
          
          ;; Test the macro evaluation
          (set a 0)
          (inc! a)
          (assert_equal 1 a)
          
          ;; Test the expansion
          (set newBody (macrox (inc! a)))
          (assert_equal "(set a (+ a 1))" (newBody stringValue)))
     
     (imethod (id) testNestedMacro is
          (macro inc! (n)
               `(set ,n (+ ,n 1)))
          
          (macro inc2! (n)
               `(progn
                      (inc! ,n)
                      (inc! ,n)))
          
          (set a 0)
          (inc2! a)
          (assert_equal 2 a)
          
          (set newBody (macrox (inc2! a)))
          (assert_equal "(progn (inc! a) (inc! a))" (newBody stringValue)))
     
     
     (imethod (id) testFactorialMacro is
          (macro mfact (n)
               `(if (== ,n 0)
                    (then 1)
                    (else (* (mfact (- ,n 1)) ,n))))
          
          (set newBody (macrox (mfact x)))
          (assert_equal "(if (== x 0) (then 1) (else (* (mfact (- x 1)) x)))" (newBody stringValue))
          
          (set x 4)
          
          (assert_equal 24 (mfact x)))
     
     (imethod (id) testCallingContextForMacro is
          ;; Make sure we didn't ruin our calling context
          (macro mfact (n)
               `(if (== ,n 0)
                    (then 1)
                    (else (* (mfact (- ,n 1)) ,n))))
          (set n 10)
          (mfact 4)
          (assert_equal n 10))


	(imethod (id) testRestMacro is
		(macro myfor ((var start stop) *body)
			`(let ((,var ,start))
				(while (<= ,var ,stop)
					,@*body
					(set ,var (+ ,var 1)))))
		
		(set var 0)
		(myfor (i 1 10)
			(set var (+ var i)))
		(assert_equal var 55)
		
		;; Make sure we didn't pollute our context
		(assert_throws "NuUndefinedSymbol"
			(puts "#{i}"))
		)
)