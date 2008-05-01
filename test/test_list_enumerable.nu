;; test_list_enumerable.nu
;;  tests for Nu methods for enumerating lists.
;;
;;  Copyright (c) 2008 Tim Burks, Neon Design Technology, Inc.

(class TestListEnumerable is NuTestCase
     
     (- testEach is
        (set sum 0)
        ((list 100 200 300) each:
         (do (n) (set sum (+ sum n))))
        (assert_equal 600 sum))
     
     (- testEachWithIndex is
        (set sum 0)
        ((list 100 200 300) eachWithIndex:
         (do (n i) (set sum (+ sum (* (+ i 1) n)))))
        (assert_equal (+ 100 (* 2 200) (* 3 300)) sum))
     
     (- testSelect is
        (set selection
             ((list 100 200 300) select:(do (n) (> n 150))))
        (assert_equal 2 (selection length))
        (assert_equal 200 (selection objectAtIndex:0))
        (assert_equal 300 (selection objectAtIndex:1)))
     
     (- testSelectWithInteger is
        (set selection
             ((list 1 2 3) select:(do (n) (% n 2))))
        (assert_equal 2 (selection length))
        (assert_equal 1 (selection objectAtIndex:0))
        (assert_equal 3 (selection objectAtIndex:1)))
     
     (- testFind is
        (set found
             ((list 100 200 300) find:(do (n) (and (> n 150) (< n 250)))))
        (assert_equal 200 found))
     
     (- testFindWithInteger is
        (set found
             ((list 1 2 3) find:(do (n) (- 1 (% n 2)))))
        (assert_equal 2 found))
     
     (- testMap is
        (assert_equal 3 ((((list 100 200 300) map:(do (n) (n stringValue))) 1) length)))
     
     (- testReduce is
        (set reduction
             ((list 100 200 300) reduce:(do (sum n) (+ sum n)) from:0))
        (assert_equal 600 reduction))
     
     (- testMapSelector is
        (assert_equal 3 ((((list 100 200 300) mapSelector:"stringValue") 1) length))))
