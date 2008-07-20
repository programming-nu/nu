;; test_macros.nu
;;  tests for Nu macros.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(load "destructuring")

(class TestDestructuring is NuTestCase
     
     ;; dbind
     (imethod (id) testDlet is
         (assert_equal 3 (dbind a 3
                                a))
         (assert_equal 3 (dbind (a) '(3)
                                   a))
         (assert_equal '(1 2 3)
                       (dbind (a b c) '(1 2 3)
                              (list a b c)))
         (assert_equal '(1 2 3 4)
                       (dbind (a (b c) d) '(1 (2 3) 4)
                              (list a b c d)))
         (assert_throws "NuCarCalledOnAtom"
                        (do () (dbind (a) ()
                                      nil)))
         (assert_throws "NuCarCalledOnAtom"
                        (do () (dbind (a b) (1)
                                      (list a b))))
         (assert_equal '(1 2)
                       (dbind a '(1 2)
                              a))
         (assert_equal '(1 (2 3))
                       (dbind (a b) '(1 (2 3))
                              (list a b)))))

