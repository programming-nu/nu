;; test_list.nu
;;  tests for basic Nu list operations.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestList is NuTestCase
     
     (imethod (id) testCompare is
          (assert_equal t (eq '(1 2 3) '(1 2 3)))
          (assert_equal t (eq '(1 (2 3)) '(1 (2 3))))
          (assert_equal nil (eq '(1 2 3) '(1 2)))
          (assert_equal nil (eq '(1 2) '(1 2 3)))
          (assert_equal nil (eq '(1 2 3) nil))
          (assert_equal nil (eq '(1 2 3) 2))
          (assert_equal nil (eq 2 '(1 2 3)))
          (assert_equal nil (eq nil '(1 2 3)))
          (assert_equal t (eq '(a b c) '(a b c)))
          (assert_equal nil (eq '(a b c) '(a b d)))
          (assert_equal nil (eq '(i) '(j)))
          (assert_equal t (eq 'i 'i))
          (assert_equal nil (eq 'i 'j)))
     
     (imethod (id) testObjectAtIndex is
          (assert_equal 1 ('(1 2 3) objectAtIndex:0))
          (assert_equal 2 ('(1 2 3) objectAtIndex:1))
          (assert_equal 3 ('(1 2 3) objectAtIndex:2))
          (assert_equal nil ('(1 2 3) objectAtIndex:3)))
     
     (imethod (id) testIndexing is
          (set mylist '(1 2 3))
          (assert_equal 1 (mylist 0))
          (assert_equal 2 (mylist 1))
          (assert_equal 3 (mylist (+ 1 1)))
          (assert_equal nil (mylist 3))
          (assert_equal nil (mylist -1))))