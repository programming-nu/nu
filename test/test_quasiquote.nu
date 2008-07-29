

;; test_quasiquote.nu
;;  tests for Nu macro-expand operator.
;;
;;  Copyright (c) 2008 Jeff Buck

(class TestQuasiquote is NuTestCase
     
     (imethod (id) testAtom is
          (assert_equal 1 `1)
			(assert_equal 'a `a))
     
	(imethod (id) testEvaling is
		(set a 1)
		(set b 2)
		
		(assert_equal '(1) `(,a))
		(assert_equal '(1 2 3) `(,a ,b 3))
		(assert_equal '(1 2 3) `(,a 2 3))
		(assert_equal '(1 2 3) `(,a ,b ,(+ a b)))
		
		)
     
     (imethod (id) testSplicing is
		(assert_equal '(1) `(,@(list 1)))
	
          (set x `(1 2 ,@(list (+ 1 2) (+ 2 2)) 5 ,@(list (+ 5 1) (+ 6 1)) 8))
          (assert_equal x '(1 2 3 4 5 6 7 8)))
     
)