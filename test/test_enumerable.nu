;; test_enumerable.nu
;;  tests for Nu enumerable extensions.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestEnumerable is NuTestCase
     
     (- testEach is
        (set sum 0)
        ((array 100 200 300) each:
         (do (n) (set sum (+ sum n))))
        (assert_equal 600 sum)
        (set sum "")
        (function append-to-sum (x) (set sum (+ sum x)))
        ((array 100 200 300) each:append-to-sum)
        (assert_equal "100200300" sum))
     
     (- testEachWithIndex is
        (set sum 0)
        ((array 100 200 300) eachWithIndex:
         (do (n i) (set sum (+ sum (* (+ i 1) n)))))
        (assert_equal (+ 100 (* 2 200) (* 3 300)) sum))
     
     (- testSelect is
        (set selection
             ((array 100 200 300) select:(do (n) (> n 150))))
        (assert_equal 2 (selection count))
        (assert_equal 200 (selection objectAtIndex:0))
        (assert_equal 300 (selection objectAtIndex:1))
        (set a (array 1 2 3 nil 4 5 6 nil 7 8 nil))
        (assert_equal 11 (a count))
        (assert_equal 8 ((a select) count)))
     
     (- testSelectWithInteger is
        (set selection
             ((array 1 2 3) select:(do (n) (% n 2))))
        (assert_equal 2 (selection count))
        (assert_equal 1 (selection objectAtIndex:0))
        (assert_equal 3 (selection objectAtIndex:1)))
     
     (- testFind is
        (set found
             ((array 100 200 300) find:(do (n) (and (> n 150) (< n 250)))))
        (assert_equal 200 found))
     
     (- testFindWithInteger is
        (set found
             ((array 1 2 3) find:(do (n) (- 1 (% n 2)))))
        (assert_equal 2 found))
     
     (- testMap is
        (assert_equal 3 ((((array 100 200 300) map:(do (n) (n stringValue))) 1) length))
        ;; Testing mapping an operator onto an array
        (set words (array "the girl" "from ipanema"))
        (set regexen (words map: regex))
        (set wanted (array /the girl/ /from ipanema/))
        (assert_equal wanted regexen))
     
     (- testMapWithIndex is
        (set result ((array 0 100 200 300) mapWithIndex:
                     (do (n i) (+ n i))))
        (assert_equal 0 (result 0))
        (assert_equal 101 (result 1))
        (assert_equal 202 (result 2))
        (assert_equal 303 (result 3)))
     
     (- testReduce is
        (set testArray (array 100 200 300))
        (set reduction
             (testArray reduce:(do (sum n) (+ sum n)) from:0))
        (assert_equal 600 reduction)
        (set reduction ((array 100 200 300) reduce:+ from:0))
        (assert_equal 600 reduction)
        (assert_equal (testArray reduce:(do (sum n) (+ sum n)) from:0) (testArray reduce:+ from:0)))
     
     (- testLeftReduce is
        (set testArray (array 100 200 300))
        (set r (testArray reduceLeft:(do (diff n) (- diff n)) from:600))
        (assert_equal 0 r)
        ; testing using an operator.
        (assert_equal r (testArray reduceLeft:- from:600)))
     
     (- testEachInReverse is
        (set title "")
        ((array "the" "girl" "from" "ipanema") eachInReverse:
         (do (n) (set title (+ title n))))
        (assert_equal title "ipanemafromgirlthe")
        (set sum "")
        (function append-to-sum (x) (set sum (+ sum x)))
        ((array 100 200 300) eachInReverse:append-to-sum)
        (assert_equal "300200100" sum))
     
     (- testMapSelector is
        (assert_equal 3 ((((array 100 200 300) mapSelector:"stringValue") 1) length))))
