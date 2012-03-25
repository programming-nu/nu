;; test_match.nu
;;  tests for Nu destructuring macros.
;;
;;  Copyright (c) 2008 Issac Trotts

(load "match")

(class TestDestructuring is NuTestCase
     
     (- (id) testFindFirstMatch is
        (assert_equal '() (_find-first-match 1 '()))
        (assert_equal '(let () 2) (_find-first-match 1 '((1 2))))
        (assert_equal '(let () 4) (_find-first-match 3 '((1 2) (3 4))))
        (assert_equal '(let () 5) (_find-first-match 'a '((1 2) ('a 5) (3 4))))
        (assert_equal '(let ((a 1) (b 2)) a)
             (_find-first-match '(1 2) '(((a b) a) ((a) a))))
        (assert_equal '(let ((a 1)) 1)
             (_find-first-match 1 '((a 1) (b 2)))))
     
     ;; match
     (if (eq (uname) "Darwin") ;; broken for iOS simulator-only
         (- (id) testMatch is
            (assert_equal 1 (match 1 (x x)))
            (assert_equal 2 (match 2 (x x) (y (+ y 1))))  ;; First match is used.
            
            (assert_equal 'nothing (match nil (0 'zero) (nil 'nothing)))
            
            ;; Make sure nil doesn't get treated as a pattern name.
            (assert_equal 'nada (match 0 (nil 'zilch) (x 'nada)))
            
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
            
            ;; If there is no else or wildcard (_) clause then it throws an exception.
            (assert_throws "NuMatchException"
                 (match '(1 2)
                        (() 'foo)
                        ((a b c) 'bar)))))
     
     (if (eq (uname) "Darwin") ;; broken for iOS simulator-only
         (- (id) testMatchWithLiterals is
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
            (assert_equal '(+ foo 1) (simplify '(+ foo 1)))))
     
     (- (id) testMatchWithWildCards is
        (assert_equal '(1 4)
             (match '(1 (2 (3)) 4 5)
                    ((a _ b _) (list a b)))))
     
     (- (id) testRestOfListPatterns is
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
     
     (- (id) testSymbolicLiterals is
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
     
     (- (id) testSymbolicLiteralsInTrees is
        (assert_equal 1 (match '(a)
                               ('(a) 1)
                               ('a 2)))
        (assert_equal 3 (match '(a)
                               ('a 2)
                               ('(a) 3))))
     
     (- (id) testQuoteLeafSymbols is
        (assert_equal '() (_quote-leaf-symbols '()))
        (assert_equal 1 (_quote-leaf-symbols 1))
        (assert_equal '(1) (_quote-leaf-symbols '(1)))
        (assert_equal ''a (_quote-leaf-symbols 'a))
        (assert_equal '( 'a 'b) (_quote-leaf-symbols '(a b)))
        (assert_equal '(('a 'c) 'b) (_quote-leaf-symbols '((a c) b)))
        (assert_equal '( 'a ('c 'b)) (_quote-leaf-symbols '(a (c b)))))
     
     (- (id) testCheckBindings is
        (check-bindings '())  ;; empty set of bindings should not throw
        (check-bindings '((a 1)))
        (check-bindings '((a 1) (a 1)))  ;; consistent
        (assert_throws "NuMatchException"
             (do () (check-bindings '((a 1) (a 2))))))  ;; inconsistent
     
     ;; match-do
     (if (defined WE_FIXED_THESE_BROKEN_TESTS)
     (if (eq (uname) "Darwin") ;; broken for iOS simulator-only
         (- (id) testMatchDo is
            (set f (match-do (() 1)))
            (assert_equal 1 (f))
            (assert_throws "NuMatchException" (f 'extra_arg))
            
            (set f (match-do (() nil) ((a) a)))
            (assert_equal nil (f))
            (assert_equal 1 (f 1))
            (assert_throws "NuMatchException" (f 1 'extra_arg))
            
            (set f (match-do ((((a) b)) (list a b)) (_ 'default)))
            (assert_equal '(1 2) (f '((1) 2)))
            (assert_equal 'default (f))
            (assert_equal 'default (f 1))
            (assert_equal 'default (f 1 2))))
     
     ;; match-function
     (- (id) testMatchFunction is
        (match-function f
             (() 0)
             ((a) 1)
             ((a b) 2)
             (_ 'many))
        (assert_equal 0 (f))
        (assert_equal 1 (f 'a))
        (assert_equal 2 (f 'a 'b))
        (assert_equal 'many (f 'a 'b 'c))
        
        (match-function f
             (((a)) a)
             (((a (b))) (list b a))
             (((a (b (c)))) (list a b c)))
        
        (assert_equal 2 (f '(2)))
        (assert_equal '(1 3) (f '(3 (1))))
        (assert_equal '(7 8 9) (f '(7 (8 (9)))))
        (assert_throws "NuMatchException" (f 1))
        
        (function slow-map (f lst)
             (match-function loop
                  ((nil) '())
                  (((a . rest))
                   (cons (f a) (loop rest))))
             (loop lst))
        (function add-1 (x) (+ x 1))
        (assert_equal '() (slow-map add-1 '()))
        (assert_equal '(1) (slow-map add-1 '(0)))
        (assert_equal '(1 2) (slow-map add-1 '(0 1)))
        (assert_equal '(4 3 2) (slow-map add-1 '(3 2 1))))
)
     
     ;; match-let1
     (- (id) testMatchLet1 is
        (assert_equal 3 (match-let1 a 3
                             a))
        (assert_equal 3 (match-let1 (a) '(3)
                             a))
        (assert_equal '(1 2 3)
             (match-let1 (a b c) '(1 2 3)
                  (list a b c)))
        (assert_equal '(1 2 3 4)
             (match-let1 (a (b c) d) '(1 (2 3) 4)
                  (list a b c d)))
        (assert_throws "NuCarCalledOnAtom"
             (do () (match-let1 (a) ()
                         nil)))
        (assert_throws "NuCarCalledOnAtom"
             (do () (match-let1 (a b) (1)
                         (list a b))))
        (assert_equal '(1 2)
             (match-let1 a '(1 2)
                  a))
        (assert_equal '(1 (2 3))
             (match-let1 (a b) '(1 (2 3))
                  (list a b)))
        
        ;; Test it with expressions on the right.
        (assert_equal (list 3 12)
             (match-let1 (a b) (list (+ 1 2) (* 3 4))
                  (list a b)))
        
        ;; Test it with symbols on the right.
        (assert_equal '(bottle rum)
             (match-let1 (yo ho) '(bottle rum)
                  (list yo ho)))
        
        ;; The same symbol can show up twice in the LHS (left hand side) as long as it
        ;; binds to eq things on the RHS (right hand side).
        (assert_equal '(bottle rum)
             (match-let1 (yo ho ho) '(bottle rum rum)
                  (list yo ho)))
        
        ;; An error occurs if we try to match the same symbol to two different things on
        ;; the right.
        (assert_throws "NuMatchException"
             (match-let1 (a a) '(1 2)
                  nil)))
     
     ;; match-setmatch-set
     (- (id) testMatchSet is
        (match-set a 3)
        (assert_equal 3 a)
        
        (match-set a '(3))
        (assert_equal '(3) a)
        
        (match-set (a) '(3))
        (assert_equal 3 a)
        
        (match-set a '(1 2))
        (assert_equal '(1 2) a)
        
        (match-set (a (b c) d) '(1 (2 3) 4))
        (assert_equal '(1 2 3 4)
             (list a b c d))
        
        (assert_throws "NuCarCalledOnAtom"
             (do () (match-set (a) ())))
        
        (assert_throws "NuCarCalledOnAtom"
             (do () (match-set (a b) (1))))
        
        (match-set (a b) '(1 (2 3)))
        (assert_equal '(1 (2 3)) (list a b))
        
        (assert_throws "NuMatchException"
             (match-set (a a) '(1 2)))))
