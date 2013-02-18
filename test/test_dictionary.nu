;; test_dictionary.nu
;;  tests for Nu dictionary extensions.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestDictionary is NuTestCase
     
     (- (id) testSet is
        (set d (NSMutableDictionary dictionary))
        (d set:(one:1
                "two" 2
                three:"three"))
        (assert_equal 3 (d count))
        (assert_equal 2 (d valueForKey:"two"))
        (assert_equal "three" (d valueForKey:"three")))
     
     (- (id) testCreate is
        (set d (NSMutableDictionary dictionaryWithList:(one:1
                                                        "two" 2
                                                        three:"three")))
        (assert_equal 3 (d count))
        (assert_equal 2 (d valueForKey:"two"))
        (assert_equal "three" (d valueForKey:"three")))
     
     (- (id) testAutomaticAccessor is
        (set d (dict "one" 1 two:2))
        (assert_equal 1 (d "one"))
        (assert_equal 2 (d "two")))
     
     (- (id) testEach is
        (set d (dict one:1 two:2 three:3 four:4 five:5 six:6))
        ;; test each: through everything
        (set count 0)
        (d each:
           (do (k v)
               (assert_equal (d objectForKey:k) v)
               (set count (+ count 1))))
        (assert_equal (d count) count)
        ;; test each: with break
        (set count 0)
        (d each:
           (do (k v)
               (if (eq count 3) (break))
               (set count (+ count 1))))
        (assert_equal 3 count)
        ;; test each: with continue
        (set count 0)
        (d each:
           (do (k v)
               (if (eq v 3) (continue))
               (set count (+ count 1))))
        (assert_equal (- (d count) 1) count))
      
     (- (id) testMap is
        (set d (dict one:1 two:2 three:3 four:4))
        (set o (d map:(do (k v) (+ 1 v))))
        (assert_equal (d count) (o count))
        (d each:
           (do (k v)
               (assert_equal (+ 1 v) (o k)))))
     
     (- (id) testLookupWithDefault is
        (set d (dict "one" 1 two:2))
        (assert_equal 1 (d objectForKey:"one" withDefault:3))
        (assert_equal 3 (d objectForKey:"three" withDefault:3)))
     
     (- (id) testShorthand is
        (set d (dict a:12 b:23 c:34))
        (assert_equal 12 (d "a"))
        (set x "a")
        (assert_equal 12 (d x))
        (assert_equal 12 (d a:))
        (d a:78 d:89 e:90)
        (assert_equal 5 (d count))
        (assert_equal 78 (d a:))
        (assert_equal 89 (d d:))
        (assert_equal 90 (d e:))
        (assert_equal 11 (d a:11 b:22 a:))
        (assert_equal 22 (d b:))
        ;; make sure that we properly evaluate key and value arguments
        (d (+ "a" "a") (+ "b" "b") (+ "c" "c") (+ "d" "d"))
        (assert_equal "bb" (d (+ "a" "a")))
        (assert_equal "dd" (d (+ "c" "" "c")))))

