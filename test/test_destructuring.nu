;; test_destructuring.nu
;;  tests for Nu destructuring macros.
;;
;;  Copyright (c) 2008 Issac Trotts

(load "destructuring")

(class TestDestructuring is NuTestCase

     ;; match
     (imethod (id) testMatch is
         (assert_equal '(1 2) (match '(1 2) ((a a) a) ((a b) (list a b))))

         (function people-to-string (people)
             (match people
                    (() "no people")
                    ((p1) "one person: #{p1}")
                    ((p1 p2) "two people: #{p1} and #{p2}")
                    (else "too many people: #{(people length)}")))
         (assert_equal "no people" (people-to-string '()))
         (assert_equal "one person: Tim" (people-to-string '(Tim)))
         (assert_equal "two people: Tim and Matz" (people-to-string '(Tim Matz)))
         (assert_equal "too many people: 3" (people-to-string '(Tim Guido Matz)))

         ;; If there is no else clause then it throws an exception.
         (assert_throws "NuMatchException"
                        (match '(1 2)
                               (() 'foo)
                               ((a b c) 'bar))))

     (imethod (id) testMatchWithLiterals is
         ;; Toy algebraic simplifier
         (function simplify (expr)
             (match expr
                    ((+ 0 a) a)
                    ((+ a 0) a)
                    ((+ a a) (list '* 2 a))
                    (else expr)))
         (assert_equal 'foo (simplify '(+ 0 foo)))
         (assert_equal 'foo (simplify '(+ foo 0)))
         (assert_equal '(* 2 x) (simplify '(+ x x)))
         (assert_equal '(+ foo 1) (simplify '(+ foo 1))))

     (imethod (id) testMatchWithWildCards is
         (assert_equal '(1 4) 
                       (match '(1 (2 (3)) 4 5)
                              ((a _ b _) (list a b)))))

     (imethod (id) testRestOfListPatterns is
         (assert_equal '(1 (2 3))
                       (match '(1 2 3) 
                              ((a . b) (list a b)))))

     (imethod (id) testCheckBindings is
         (check-bindings '())  ;; empty set of bindings should not throw
         (check-bindings '((a 1)))
         (check-bindings '((a 1) (a 1)))  ;; consistent
         (assert_throws "NuDestructuringException"
                        (do () (check-bindings '((a 1) (a 2))))))  ;; inconsistent

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
                              (list yo ho)))

         ;; The same symbol can show up twice in the LHS (left hand side) as long as it
         ;; binds to eq things on the RHS (right hand side).
         (assert_equal '(bottle rum)
                       (dbind (yo ho ho) '(bottle rum rum)
                              (list yo ho)))

         ;; An error occurs if we try to match the same symbol to two different things on
         ;; the right.
         (assert_throws "NuDestructuringException"
                        (dbind (a a) '(1 2)
                               nil)))

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
         (assert_equal '(1 (2 3)) (list a b))

         (assert_throws "NuDestructuringException"
                        (dset (a a) '(1 2)))))
