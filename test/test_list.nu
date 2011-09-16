;; test_list.nu
;;  tests for basic Nu list operations.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestList is NuTestCase
     (- testPair? is
        (assert_false (pair? nil))
        (assert_true (pair? '(1 . 2)))
        (assert_true (pair? '(1))))
     
     (- testNull? is
        (assert_true (null? nil))
        (assert_false (null? 1))
        (assert_false (null? ""))
        (assert_false (null? 0))
        (assert_false (null? '(1))))
     
     (- testList? is
        (assert_true (list? '()))
        (assert_true (list? '(1)))
        (assert_true (list? '(1 (2 3))))
        (assert_false (list? 1))
        (assert_false (list? ""))
        (assert_false (list? "a")))
     
     (- testCompare is
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
     
     (- testObjectAtIndex is
        (assert_equal 1 ('(1 2 3) objectAtIndex:0))
        (assert_equal 2 ('(1 2 3) objectAtIndex:1))
        (assert_equal 3 ('(1 2 3) objectAtIndex:2))
        (assert_equal nil ('(1 2 3) objectAtIndex:3)))
     
     (- testBasicOperators is
        (assert_equal 1 (car '(1 2 3)))
        (assert_equal '(2 3) (cdr '(1 2 3)))
        (assert_equal 1 (first '(1 2 3)))
        (assert_equal '(2 3) (rest '(1 2 3)))
        (assert_equal 1 (head '(1 2 3)))
        (assert_equal '(2 3) (tail '(1 2 3))))
     
     (- testIndexing is
        (set mylist '(1 2 3))
        (assert_equal 1 (mylist 0))
        (assert_equal 2 (mylist 1))
        (assert_equal 3 (mylist (+ 1 1)))
        (assert_equal 3 (mylist -1))
        (assert_equal 2 (mylist -2))
        (assert_equal 1 (mylist -3))
        (assert_equal nil (mylist 3))
        (assert_equal nil (mylist -4)))
     
     (- testLength is
        (set mylist '(1 2 3 4))
        (assert_equal 4 (mylist length))
        (assert_equal 4 (mylist count))
        (set mylist nil)
        (assert_equal 0 (mylist length))
        (assert_equal 0 (mylist count)))
     
     (- testAll is
        (assert_equal t (all '()))
        (assert_equal nil (all (list nil)))
        (assert_equal nil (all (list 1 nil)))
        (assert_equal t (all (list 3 2 1)))
        (assert_equal nil (all (list '(3) nil))))
     
     (- testAny is
        (assert_equal nil (any '()))
        (assert_equal nil (any (list nil)))
        (assert_equal 1 (any (list 1 nil)))
        (assert_equal 1 (any (list nil 1)))
        (assert_equal 3 (any (list 3 2 1))))
     
     (- testApply is
        (assert_equal 1 (apply + '(1)))
        (assert_equal 3 (apply + '(1 2)))
        (assert_equal '(a b c) (apply list '(a b c)))
        (function identity (x) x)
        (assert_equal 'a (apply identity '(a)))
        (set a "foo")
        (assert_equal 'a (apply identity '(a)))
        (assert_equal "foo" (apply identity (list a)))
        (assert_throws "NuUndefinedSymbol" (apply identity (list b)))
        (assert_equal '(a b c d) (apply list 'a 'b '(c d)))
        (set a 1)
        (set b 2)
        (set c 3)
        (set d 4)
        (assert_equal '(a 2 c 4) (apply list 'a b `(c ,d)))
        (assert_equal 10 (apply + a b (list c d))))
     
     (- testSort is
        (assert_equal '() (sort '()))
        (assert_equal '(1) (sort '(1)))
        (assert_equal '(1 2) (sort '(1 2)))
        (assert_equal '(1 2) (sort '(2 1)))
        (assert_equal '(1 1 2) (sort '(1 2 1)))
        (assert_equal '(1 2 3) (sort '(3 2 1)))
        (assert_equal '(3 2 1) (sort '(1 2 3) (do (a b) (- (a compare:b))))))
     
     (- testMap is
        (assert_equal '() (map + '()))
        (assert_equal '() (map + '() '()))
        (assert_equal '() (map + '(1) '()))
        (assert_equal '() (map + '() '(1)))
        (assert_equal '(3) (map + '(1) '(2)))
        (assert_equal '(9 12) (map + '(1 2) '(3 4) '(5 6)))
        (assert_equal '(9) (map + '(1 2) '(3) '(5 6))))
     
     (- testAccessors is
        (set x '(((1 2) 3 4) (5 6 7) 8 9))
        (assert_equal '(1 2) (x caar))
        (assert_equal '(3 4) (x cadr))
        (assert_equal '(5 6 7) (x cdar))
        (assert_equal '(8 9) (x cddr))
        (assert_equal 1 (x caaar))
        (assert_equal '(2) (x caadr))
        (assert_equal 3 (x cadar))
        (assert_equal '(4) (x caddr))
        (assert_equal 5 (x cdaar))
        (assert_equal '(6 7) (x cdadr))
        (assert_equal 8 (x cddar))
        (assert_equal '(9) (x cdddr)))
     
     (- testImplicitAccessors is
        (assert_equal '(6 7) ('(1 2 3 4 5 6 7) cdddddr))
        (assert_equal 5 ('(1 2 3 4 5 6 7) cddddar))
        (assert_equal '(7) ('(1 2 3 4 5 6 7) cddddddr))
        (assert_equal '7 ('(1 2 3 4 5 6 7) cddddddar)))
     
     (- testArray is
        (assert_equal (array 1 2 3) ('(1 2 3) array))
        (assert_equal (array) (nil array))
        (assert_equal (array) ('() array))))

