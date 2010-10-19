;; test_blockargs.nu
;;  tests for argument handling in Nu blocks.
;;
;;  Copyright (c) 2008 Jeff Buck


(class TestBlockArgs is NuTestCase
     
     (- (id) testSimpleArgs is
        (function make-list (a b c)
             (list a b c))
        (assert_equal '(1 2 3) (make-list 1 2 3)))
     
     (- (id) testRestArgs is
        (function make-list (a b *rest)
             (append (list a b) *rest))
        (assert_equal '(1 2 3) (make-list 1 2 3))
        (assert_equal '(1 2 3 4 5) (make-list 1 2 3 4 5)))
     
     (- (id) testOverrideImplicitArgs1 is
        (function make-list (*args)
             (*args))
        (assert_equal '(1 2 3) (make-list 1 2 3))
        (assert_equal '() (make-list)))
     
     (- (id) testOverrideImplicitArgs2 is
        (function make-list (a b *args)
             (list a b *args))
        (assert_equal '(1 2 ()) (make-list 1 2))
        (assert_equal '(1 2 (3)) (make-list 1 2 3)))
     
     (- (id) testBlock is
        (assert_equal '(1 2) ((do (a b) (list a b)) 1 2))
        (assert_equal '(1 2) ((do (a b *args) (list a b)) 1 2 3 4))
        (assert_equal '(3 4) ((do (a b *args) (*args)) 1 2 3 4))
        (assert_equal '(1 (3 4)) ((do (a b *args) (list a *args)) 1 2 3 4))))
