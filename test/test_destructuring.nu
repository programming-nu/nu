;; test_destructuring.nu
;;  tests for Nu destructuring macros.
;;
;;  Copyright (c) 2008 Issac Trotts

(load "destructuring")

(class TestDestructuring is NuTestCase
     
     ;; dbind
     (imethod (id) testDbind is
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
                              (list a b)))
         ;; Test it with expressions on the right.
         (assert_equal (list 3 12)
                       (dbind (a b) (list (+ 1 2) (* 3 4))
                              (list a b)))
         ;; Test it with symbols on the right.
         (assert_equal '(bottle rum)
                       (dbind (yo ho) '(bottle rum)
                              (list yo ho))))

     ;; dset 
     (imethod (id) testDset is
         (dset a 3)
         (assert_equal 3 a)

         (dset a '(3))
         (assert_equal '(3) a)

         (dset (a) '(3))
         (assert_equal 3 a)

         (dset a '(1 2))
         (assert_equal '(1 2) a)

         (dset (a (b c) d) '(1 (2 3) 4))
         (assert_equal '(1 2 3 4)
                       (list a b c d))

         (assert_throws "NuCarCalledOnAtom"
                        (do () (dset (a) ())))

         (assert_throws "NuCarCalledOnAtom"
                        (do () (dset (a b) (1))))

         (dset (a b) '(1 (2 3)))
         (assert_equal '(1 (2 3)) (list a b))))

