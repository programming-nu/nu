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
          (assert_equal nil (eq 'i 'j))))           
