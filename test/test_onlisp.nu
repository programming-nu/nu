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
        (assert_equal a nil))

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
		(assert_equal a "a is defined"))

)
