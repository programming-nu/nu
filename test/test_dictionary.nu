;; test_dictionary.nu
;;  tests for Nu dictionary extensions.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestDictionary is NuTestCase
     
     (imethod (id) testSet is
          (set d (NSMutableDictionary dictionary))
          (d set:(one:1
                  "two" 2
                  three:"three"))
          (assert_equal 3 (d count))
          (assert_equal 2 (d valueForKey:"two"))
          (assert_equal "three" (d valueForKey:"three")))
     
     (imethod (id) testCreate is
          (set d (NSMutableDictionary dictionaryWithList:(one:1
                                                          "two" 2
                                                          three:"three")))
          (assert_equal 3 (d count))
          (assert_equal 2 (d valueForKey:"two"))
          (assert_equal "three" (d valueForKey:"three")))
     
     (imethod (id) testAutomaticAccessor is
          (set d (dict "one" 1 two:2))
          (assert_equal 1 (d "one"))
          (assert_equal 2 (d "two")))
     
     (imethod (id) testEach is
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
     
     (imethod (id) testLookupWithDefault is
          (set d (dict "one" 1 two:2))
          (assert_equal 1 (d objectForKey:"one" withDefault:3))
          (assert_equal 3 (d objectForKey:"three" withDefault:3))))

