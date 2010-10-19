;; test_quasiquote.nu
;;  tests for Nu macro-expand operator.
;;
;;  Copyright (c) 2008 Jeff Buck

(class TestQuasiquote is NuTestCase
     
     (- (id) testAtom is
        (assert_equal '() `())
        (assert_equal 1 `1)
        (assert_equal 'a `a))
     
     (- (id) testSimpleLists is
        (assert_equal '(1) `(1))
        (assert_equal '(1 2 3) `(1 2 3))
        (assert_equal '(1 (2 3)) `(1 (2 3)))
        (assert_equal '(1 (+ 2 3)) `(1 (+ 2 3))))
     
     (- (id) testEvaling is
        (set a 1)
        (set b 2)
        
        (assert_equal '(1) `(,a))
        (assert_equal '(1 2 3) `(,a ,b 3))
        (assert_equal '(1 2 3) `(,a 2 3))
        (assert_equal '(1 2 3) `(,a ,b ,(+ a b)))
        
        ; Deep evals
        (set a 1)
        (set b 2)
        (assert_equal '(1 (2 3)) `(1 (2 ,(+ a b))))
        (assert_equal '((2 3) 1) `((2 ,(+ a b)) 1))
        (assert_equal '(1 (2 3) 4) `(1 (2 ,(+ a b)) 4))
        (assert_equal '((1 2) (3 4) 5) `(,(list 1 2) (3 ,(* 2 b)) 5))
        
        (assert_throws "NuQuasiquoteEvalOutsideQuasiquote"
             (do ()
                 (,(+ 1 1)))))
     
     (- (id) testSplicing is
        ; Single element
        (assert_equal '(1) `(,@(list 1)))
        ; Splice at beginning
        (assert_equal '(1 2) `(,@(list 1) ,(+ 1 1)))
        ; Splice at end
        (assert_equal '(1 2) `(1 ,@(list 2)))
        ; Splice at beginning and end
        (assert_equal '(1 2 3) `(,@(list 1) 2 ,@(list 3)))
        ; Splice empty list
        (assert_equal '(1 2) `(1 2 ,@(list)))
        ; Splice and evals
        (assert_equal '(1 2 3) `(,(+ 1 0) ,@(list 2 3)))
        (assert_equal '(1 2 3) `(,@(list 1) ,(+ 1 1) ,@(list 3)))
        (assert_equal '(1 2 3) `(,@(list 1 2) ,(+ 1 1 1)))
        
        ; Empty lists at end
        (assert_equal '(1) `(1 ,@(list)))
        ; Empty lists at beginning
        (assert_equal '(1) `(,@(list) 1))
        ; Empty lists in middle
        (assert_equal '(1 1) `(1 ,@(list) 1))
        ; Empty lists all around
        (assert_equal '() `(,@(list) ,@(list) ,@(list)))
        
        ; Deep splices
        (set a 1)
        (set b 2)
        (assert_equal '(1 (2 3)) `(1 (2 ,@(list (+ a b)))))
        (assert_equal '((2 3) 1) `((2 ,@(list (+ a b))) 1))
        (assert_equal '(1 (2 3) 4) `(1 (2 ,@(list (+ a b))) 4))
        (assert_equal '(1 2 (3 4) 5) `(,@(list 1 2) (3 ,@(list (* 2 b))) 5))
        
        (set x `(1 2 ,@(list (+ 1 2) (+ 2 2)) 5 ,@(list (+ 5 1) (+ 6 1)) 8))
        (assert_equal x '(1 2 3 4 5 6 7 8))
        
        (assert_throws "NuQuasiquoteSpliceOutsideQuasiquote"
             (do ()
                 (,@(list 1))))
        
        (assert_throws "NuQuasiquoteSpliceNoListError"
             (do ()
                 (`(,@(1)))))))




