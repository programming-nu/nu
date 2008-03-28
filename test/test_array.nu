;; test_array.nu
;;  tests for Nu array extensions.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestArray is NuTestCase
     
     (- testCreate is
        (set a (NSMutableArray arrayWithList:'(1 2)))
        (a << "three")
        (assert_equal 3 (a count))
        (assert_equal 2 (a 1))
        (assert_equal "three" (a 2)))
     
     (- testEach is
        (set i 0)
        (set a (array 0 1 2))
        (a each:
           (do (x)
               (assert_equal i x)
               (set i (+ i 1)))))
     
     (- testEachInReverse is
        (set i 0)
        (set a (array 2 1 0))
        (a eachInReverse:
           (do (x)
               (assert_equal i x)
               (set i (+ i 1)))))
     
     (- testSortedArrayUsingBlock is
        (set array (NSArray arrayWithList:(list 9 42 37 1 17 30 11 28)))
        (set sorted (array sortedArrayUsingBlock:(do (a b) (b compare:a))))
        (assert_equal '(42 37 30 28 17 11 9 1) (sorted list))
        (set array (NSArray arrayWithList:(list "mary" "christopher" "ed" "brian" "tim" "jennifer")))
        (set sorted (array sortedArrayUsingBlock:(do (a b) ((a length) compare:(b length)))))
        (assert_equal '("ed" "tim" "mary" "brian" "jennifer" "christopher") (sorted list)))
     
     (- testIndexing is
          (set a (array 1 2 3))
          (assert_equal 1 (a 0))
          (assert_equal 2 (a 1))
          (assert_equal 3 (a (+ 1 1)))
          (assert_equal 3 (a -1))
          (assert_equal 2 (a -2))
          (assert_equal 1 (a -3))
          (assert_equal nil (a 3))
          (assert_equal nil (a -4))))



