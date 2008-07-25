;; test_match.nu
;;  tests for Nu destructuring macros.
;;
;;  Copyright (c) 2008 Issac Trotts

(load "match")

(class TestDestructuring is NuTestCase
     
     (imethod (id) testFindFirstMatch is
         (assert_throws "NuMatchException" (_find-first-match 1 '()))
         (assert_equal '(let () 2) (_find-first-match 1 '((1 2))))
         (assert_equal '(let () 4) (_find-first-match 3 '((1 2) (3 4))))
         (assert_equal '(let () 5) (_find-first-match 'a '((1 2) ('a 5) (3 4))))
         (assert_equal '(let ((a 1) (b 2)) a)
                       (_find-first-match '(1 2) '(((a b) a) ((a) a))))
         )

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
                      ((a . b) (list a b))))
          (assert_equal '(1 2 (3))
               (match '(1 2 3)
                      ((a b . c) (list a b c))))
          
          ;; This is probably an inefficient way to implement map.
          (function silly-map (f a-list)
               (match a-list
                      (() '())
                      ((head . tail)
                       (cons (f head) (silly-map f tail)))))
          (function add1 (x) (+ 1 x))
          (assert_equal '() (silly-map add1 '()))
          (assert_equal '(1) (silly-map add1 '(0)))
          (assert_equal '(1 3) (silly-map add1 '(0 2)))
          (assert_equal '(1 2 3) (silly-map add1 '(0 1 2))))
     
     (imethod (id) testSymbolicLiterals is
          (assert_equal 1 (match 'a ('a 1)))
          (assert_equal 2 (match '(a 2) (('a x) x)))
          (assert_throws "NuMatchException" (match '(a 2) (('b x) x)))
          
          (function to-num (thing)
               (match thing
                      ('Baz 7)
                      (('Foo x) x)
                      (('Bar x y) (+ x y))))
          (assert_equal 42 (to-num '(Foo 42)))
          (assert_equal 9 (to-num '(Bar 4 5)))
          (assert_equal 7 (to-num 'Baz))
          
          (function fruit-desc (fruit)
               (match fruit
                      (('Apple crunchiness) "Apple #{crunchiness}-crunchy")
                      (('BananaBunch n) "Banana bunch with #{n} bananas")
                      (('Orange desc) "Orange #{desc}")))
          
          (assert_equal "Apple 2.5-crunchy" (fruit-desc '(Apple 2.5)))
          (assert_equal "Banana bunch with 5 bananas"
               (fruit-desc '(BananaBunch 5)))
          (assert_equal "Orange bergamot" (fruit-desc '(Orange "bergamot"))))
     
     (imethod (id) testCheckBindings is
          (check-bindings '())  ;; empty set of bindings should not throw
          (check-bindings '((a 1)))
          (check-bindings '((a 1) (a 1)))  ;; consistent
          (assert_throws "NuMatchException"
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
          (assert_throws "NuMatchException"
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
          
          (assert_throws "NuMatchException"
               (dset (a a) '(1 2)))))
