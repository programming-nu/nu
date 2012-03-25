;; test_array.nu
;;  tests for Nu array extensions.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

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
               (set i (+ i 1))))
        ;; iteration with break
        (set a (array 0 1 2 3 4 5 6))
        (set sum 0)
        (a each:
           (do (x)
               (if (eq x 4) (break))
               (set sum (+ sum x))))
        (assert_equal 6 sum)
        ;; iteration with continue
        (set a (array 0 1 2 3 4 5 6))
        (set sum 0)
        (a each:
           (do (x)
               (if (eq x 4) (continue))
               (set sum (+ sum x))))
        (assert_equal 17 sum))
     
     (- testEachInReverse is
        (set i 0)
        (set a (array 2 1 0))
        (a eachInReverse:
           (do (x)
               (assert_equal i x)
               (set i (+ i 1))))
        ;; iteration with break
        (set a (array 6 5 4 3 2 1 0))
        (set sum 0)
        (a eachInReverse:
           (do (x)
               (if (eq x 4) (break))
               (set sum (+ sum x))))
        (assert_equal 6 sum)
        ;; iteration with continue
        (set a (array 6 5 4 3 2 1 0))
        (set sum 0)
        (a eachInReverse:
           (do (x)
               (if (eq x 4) (continue))
               (set sum (+ sum x))))
        (assert_equal 17 sum))
     
     (- testEachWithIndex is
        (set i 0)
        (set a (array "zero" "one" "two"))
        (a eachWithIndex:
           (do (value index)
               (assert_equal i index)
               (set i (+ i 1))))
        ;; iteration with break
        (set a (array "zero" "one" "two" "three" "four" "five" "six"))
        (set sum 0)
        (a eachWithIndex:
           (do (value index)
               (if (eq index 4) (break))
               (set sum (+ sum index))))
        (assert_equal 6 sum)
        ;; iteration with continue
        (set a (array "zero" "one" "two" "three" "four" "five" "six"))
        (set sum 0)
        (a eachWithIndex:
           (do (value index)
               (if (eq index 4) (continue))
               (set sum (+ sum index))))
        (assert_equal 17 sum))
     
     (- testSortedArrayUsingBlock is
        (set array (NSArray arrayWithList:(list 9 42 37 1 17 30 11 28)))
        (set sorted (array sortedArrayUsingBlock:(do (a b) (b compare:a))))
        (assert_equal '(42 37 30 28 17 11 9 1) (sorted list))
        (set array (NSArray arrayWithList:(list "mary" "christopher" "ed" "brian" "tim" "jennifer")))
        (set sorted (array sortedArrayUsingBlock:(do (a b) ((a length) compare:(b length)))))
        (assert_equal '("ed" "tim" "mary" "brian" "jennifer" "christopher") (sorted list)))
     
     (- testSortedArrayUsingSelector is
        ;; I don't like this, but want to be sure we bridge the right
        ;; return type for the comparison method. On Snow Leopard (at
        ;; least), NSInteger is either int or long depending on the
        ;; build architecture.
        (case ((NSNumber instanceMethodWithName:"compare:") returnType)
              ("i" (class NSObject (- (int) reverseCompare:(id) other is (* -1 (self compare:other)))))
              ("q" (class NSObject (- (long) reverseCompare:(id) other is (* -1 (self compare:other))))))
        (set a (array 1 9 2 8 3 7 4 6 5))
        (set sorted (a sortedArrayUsingSelector:"reverseCompare:"))
        (assert_equal (array 9 8 7 6 5 4 3 2 1) sorted)
        ;; this is better. We directly support NSComparisonResult in declarations.
        (class NSObject (- (NSComparisonResult) reverseCompare2:(id) other is (* -1 (self compare:other))))
        (set sorted2 (a sortedArrayUsingSelector:"reverseCompare2:"))
        (assert_equal (array 9 8 7 6 5 4 3 2 1) sorted2))
     
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
